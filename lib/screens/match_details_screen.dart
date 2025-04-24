import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/player_model.dart'; // Ensure PlayerModel is imported
import '../services/match_service.dart';
import 'package:intl/intl.dart';

class MatchDetailsScreen extends StatefulWidget {
  final MatchModel match;
  
  const MatchDetailsScreen({
    Key? key,
    required this.match,
  }) : super(key: key);
  
  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final _matchService = MatchService();
  bool isCreator = false;

  @override
  void initState() {
    super.initState();
    _checkCreatorStatus();
  }

  Future<void> _checkCreatorStatus() async {
    final currentUserId = _matchService.getCurrentUserId();
    setState(() {
      isCreator = currentUserId == widget.match.createdBy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Match Details'),
        backgroundColor: Colors.blue[900],
        actions: [
          if (isCreator && widget.match.status != 'completed')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _showEditDialog(context),
            ),
        ],
      ),
      body: StreamBuilder<MatchModel>(
        stream: _matchService.getMatchStream(widget.match.id!).cast<MatchModel>(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final match = snapshot.data ?? widget.match;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMatchHeader(match),
                SizedBox(height: 16),
                _buildStatusSpecificContent(match),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchHeader(MatchModel match) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${match.team1} vs ${match.team2}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Venue: ${match.venue}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Overs: ${match.overs}',
              style: TextStyle(fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(match.date),
                  style: TextStyle(fontSize: 16),
                ),
                _buildStatusChip(match.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSpecificContent(MatchModel match) {
    switch (match.status?.toLowerCase()) {
      case 'upcoming':
        return _buildUpcomingContent(match);
      case 'live':
        return _buildLiveContent(match);
      case 'completed':
        return _buildCompletedContent(match);
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildUpcomingContent(MatchModel match) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildTeamSquad('Team 1', match.team1Players ?? []),
            SizedBox(height: 16),
            _buildTeamSquad('Team 2', match.team2Players ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveContent(MatchModel match) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Add live scoring widgets here
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedContent(MatchModel match) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Add match summary widgets here
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Match Details'),
        content: SingleChildScrollView(
          child: _buildEditForm(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save changes
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    // Add form fields for editing match details
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add form fields here
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color = _getStatusColor(status ?? '');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTeamSquad(String teamName, List<PlayerModel> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...players.map((player) => ListTile(
          leading: CircleAvatar(
            child: Text(player.jerseyNumber.toString()),
          ),
          title: Text(player.name),
          subtitle: Text(player.role.toString().split('.').last),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (player.isCaptain)
                Icon(Icons.stars, color: Colors.amber, size: 20),
              if (player.isViceCaptain)
                Icon(Icons.star_half, color: Colors.amber, size: 20),
              if (player.isWicketKeeper)
                Icon(Icons.sports_cricket, color: Colors.grey, size: 20),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'live':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}