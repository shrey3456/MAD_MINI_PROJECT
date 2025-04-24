import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../controllers/match_controller.dart';
import 'match_scoring_screen.dart' as scoring;
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamSelectionScreen extends StatefulWidget {
  final MatchModel match;

  const TeamSelectionScreen({
    Key? key,
    required this.match,
  }) : super(key: key);

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<PlayerModel> team1Selected = [];
  final List<PlayerModel> team2Selected = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Select Playing XI'),
        backgroundColor: Colors.blue[900],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Text(widget.match.team1, style: TextStyle(color: Colors.white))),
            Tab(child: Text(widget.match.team2, style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamSelection(
            teamName: widget.match.team1,
            players: widget.match.team1Players ?? [],
            selectedPlayers: team1Selected,
          ),
          _buildTeamSelection(
            teamName: widget.match.team2,
            players: widget.match.team2Players ?? [],
            selectedPlayers: team2Selected,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTeamSelection({
    required String teamName,
    required List<PlayerModel> players,
    required List<PlayerModel> selectedPlayers,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color.fromARGB(255, 252, 250, 250),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected: ${selectedPlayers.length}/11',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                teamName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isSelected = selectedPlayers.contains(player);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.blue[900] : Colors.grey[300],
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  title: Text(player.name),
                  subtitle: Text(player.role),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          if (selectedPlayers.length < 11) {
                            selectedPlayers.add(player);
                          } else {
                            _showMaxPlayersDialog();
                          }
                        } else {
                          selectedPlayers.remove(player);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      if (selectedPlayers.contains(player)) {
                        selectedPlayers.remove(player);
                      } else if (selectedPlayers.length < 11) {
                        selectedPlayers.add(player);
                      } else {
                        _showMaxPlayersDialog();
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final canProceed = team1Selected.length == 11 && team2Selected.length == 11;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: canProceed ? _proceedToMatch : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('START MATCH', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showMaxPlayersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Players Selected'),
        content: const Text('You can only select 11 players per team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _proceedToMatch() async {
    try {
      // Create match data with selected players and toss details
      final Map<String, dynamic> matchData = {
        'id': widget.match.id,
        'team1': widget.match.team1,
        'team2': widget.match.team2,
        'tossWinner': widget.match.tossWinner,
        'tossDecision': widget.match.tossDecision,
        'selectedTeam1Players': team1Selected.map((p) => p.toJson()).toList(),
        'selectedTeam2Players': team2Selected.map((p) => p.toJson()).toList(),
        'status': 'live',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update match in Firebase
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id)
          .update(matchData);

      // Create updated match model with selected players
      final updatedMatch = MatchModel(
        id: widget.match.id,
        team1: widget.match.team1,
        team2: widget.match.team2,
        venue: widget.match.venue,
        overs: widget.match.overs,
        date: widget.match.date,
        time: widget.match.time,
        tossWinner: widget.match.tossWinner,
        tossDecision: widget.match.tossDecision,
        selectedTeam1Players: team1Selected,
        selectedTeam2Players: team2Selected,
        status: 'in_progress',
      );

      // Remove loading indicator
      Navigator.pop(context);

      // Navigate to scoring screen
      Navigator.pushReplacementNamed(
        context,
        '/match-scoring',
        arguments: updatedMatch,
      );
    } catch (e) {
      // Remove loading indicator if showing
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to save match details: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}