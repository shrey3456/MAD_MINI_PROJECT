import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';

class UserMatchesScreen extends StatefulWidget {
  final String userId;

  const UserMatchesScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserMatchesScreen> createState() => _UserMatchesScreenState();
}

class _UserMatchesScreenState extends State<UserMatchesScreen> with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
        backgroundColor: Colors.blue[900],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              text: 'LIVE',
              icon: Icon(Icons.sports_cricket),
            ),
            Tab(
              text: 'UPCOMING',
              icon: Icon(Icons.event),
            ),
            Tab(
              text: 'RECENT',
              icon: Icon(Icons.history),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchesList('live'),
          _buildMatchesList('upcoming'),
          _buildMatchesList('completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/new-match'),
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMatchesList(String status) {
    return StreamBuilder<List<MatchModel>>(
      stream: _matchService.getUserMatchesByStatus(widget.userId, status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data ?? [];
        
        if (matches.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          itemCount: matches.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final match = matches[index];
            return _buildMatchCard(match, status);
          },
        );
      },
    );
  }

  Widget _buildMatchCard(MatchModel match, String status) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${match.team1} vs ${match.team2}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Venue: ${match.venue}'),
                if (status == 'live' && match.currentInnings != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${match.battingTeam}: ${match.currentScore}/${match.currentWickets} (${match.currentOvers})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  if (match.currentInnings == 2 && match.firstInningsScore != null)
                    Text(
                      'Target: ${match.firstInningsScore! + 1}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ],
            ),
            trailing: _buildStatusChip(match.status ?? 'unknown'),
          ),
          if (status == 'live') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.sports_cricket),
                    label: const Text('Score'),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/match-scoring',
                      arguments: match,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    label: const Text('End', style: TextStyle(color: Colors.red)),
                    onPressed: () => _endMatch(match),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    if (status == 'live') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No matches in progress',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a match from the upcoming section',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    String message;
    IconData icon;
    
    switch (status) {
      case 'live':
        message = 'No live matches';
        icon = Icons.sports_cricket;
        break;
      case 'upcoming':
        message = 'No upcoming matches';
        icon = Icons.event;
        break;
      default:
        message = 'No completed matches';
        icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          if (status == 'upcoming') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/new-match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
              child: const Text('Create New Match'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startMatch(MatchModel match) async {
    try {
      await _matchService.updateMatchStatus(match.id!, 'live');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match started successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endMatch(MatchModel match) async {
    try {
      await _matchService.updateMatchStatus(match.id!, 'completed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match completed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to end match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'live':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}