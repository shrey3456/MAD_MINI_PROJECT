import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../widgets/match_card.dart';
import 'package:intl/intl.dart';

class MatchListScreen extends StatefulWidget {
  @override
  _MatchListScreenState createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> with SingleTickerProviderStateMixin {
  final _matchService = MatchService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
          title: const Text('View Matches'),
          backgroundColor: Colors.blue[900],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(
                text: 'UPCOMING',
                icon: Icon(Icons.event),
              ),
              Tab(
                text: 'LIVE',
                icon: Icon(Icons.sports_cricket),
              ),
              Tab(
                text: 'RECENT',
                icon: Icon(Icons.history),
              ),
            ],
          ),
        ),
        body: StreamBuilder<List<MatchModel>>(
          stream: _matchService.getAllMatches(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final matches = snapshot.data ?? [];
            final upcomingMatches = matches.where((m) => m.status?.toLowerCase() == 'upcoming').toList();
            final liveMatches = matches.where((m) => m.status?.toLowerCase() == 'live').toList();
            final recentMatches = matches.where((m) => m.status?.toLowerCase() == 'completed').toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildMatchList(upcomingMatches, 'upcoming'),
                _buildMatchList(liveMatches, 'live'),
                _buildMatchList(recentMatches, 'completed'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/new-match'),
          child: Icon(Icons.add),
          backgroundColor: Colors.blue[900],
        ),
      ),
    );
  }

  Widget _buildMatchList(List<MatchModel> matches, String status) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(status),
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No ${status.toUpperCase()} matches',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: matches.length,
      padding: EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final match = matches[index];
        if (match == null) return SizedBox.shrink();
        
        return MatchCard(
          match: match,
          onStatusChange: match.createdBy != null && 
              _matchService.getCurrentUserId() == match.createdBy
              ? () => _showStatusChangeDialog(match)
              : null,
          onTap: () => Navigator.pushNamed(
            context,
            '/match-details',
            arguments: match,
          ),
        );
      },
    );
  }

  IconData _getEmptyStateIcon(String status) {
    switch (status) {
      case 'upcoming':
        return Icons.event;
      case 'live':
        return Icons.live_tv;
      case 'completed':
        return Icons.history;
      default:
        return Icons.sports_cricket;
    }
  }

  void _showStatusChangeDialog(MatchModel match) {
    if (match.id == null || match.status == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Match Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.status?.toLowerCase() == 'upcoming')
              ListTile(
                leading: Icon(Icons.play_circle, color: Colors.green),
                title: Text('Start Match'),
                onTap: () async {
                  await _matchService.updateMatchStatus(match.id!, 'live');
                  Navigator.pop(context);
                },
              ),
            if (match.status?.toLowerCase() == 'live')
              ListTile(
                leading: Icon(Icons.stop_circle, color: Colors.red),
                title: Text('End Match'),
                onTap: () async {
                  await _matchService.updateMatchStatus(match.id!, 'completed');
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}