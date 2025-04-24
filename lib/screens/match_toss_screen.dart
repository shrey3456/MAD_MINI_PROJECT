import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../controllers/match_controller.dart';
import 'team_selection_screen.dart';
// Ensure this file contains the definition of Routes

class MatchTossScreen extends StatefulWidget {
  final MatchModel match;

  const MatchTossScreen({
    Key? key, 
    required this.match,
  }) : super(key: key);

  @override
  State<MatchTossScreen> createState() => _MatchTossScreenState();
}

class _MatchTossScreenState extends State<MatchTossScreen> {
  String? tossWinner;
  String? decision;

  @override
  Widget build(BuildContext context) {
    // Check if match is ready for scoring
    if (widget.match.status == 'live' && 
        widget.match.tossWinner != null && 
        widget.match.tossDecision != null &&
        widget.match.selectedTeam1Players != null &&
        widget.match.selectedTeam2Players != null) {
      // Redirect to scoring screen if everything is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          '/match-scoring',
          arguments: widget.match,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if only toss is done (redirect to team selection)
    if (widget.match.tossWinner != null && widget.match.tossDecision != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          '/team-selection',
          arguments: {
            'match': widget.match,
            'tossWinner': widget.match.tossWinner,
            'tossDecision': widget.match.tossDecision,
          },
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Toss'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '${widget.match.team1} vs ${widget.match.team2}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Venue: ${widget.match.venue}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${widget.match.overs} Overs',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Who won the toss?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => tossWinner = widget.match.team1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tossWinner == widget.match.team1 ? 
                        Colors.blue[900] : Colors.grey[300],
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      widget.match.team1,
                      style: TextStyle(
                        color: tossWinner == widget.match.team1 ? 
                          Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => tossWinner = widget.match.team2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tossWinner == widget.match.team2 ? 
                        Colors.blue[900] : Colors.grey[300],
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      widget.match.team2,
                      style: TextStyle(
                        color: tossWinner == widget.match.team2 ? 
                          Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (tossWinner != null) ...[
              const SizedBox(height: 32),
              Text(
                'What did $tossWinner elect to do?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => decision = 'bat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: decision == 'bat' ? 
                          Colors.blue[900] : Colors.grey[300],
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        'BAT',
                        style: TextStyle(
                          color: decision == 'bat' ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => decision = 'bowl'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: decision == 'bowl' ? 
                          Colors.blue[900] : Colors.grey[300],
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        'BOWL',
                        style: TextStyle(
                          color: decision == 'bowl' ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            if (tossWinner != null && decision != null)
              ElevatedButton(
                onPressed: _proceedToTeamSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _proceedToTeamSelection() async {
    try {
      // Update match in Firebase with toss details and live status
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id)
          .update({
        'tossWinner': tossWinner,
        'tossDecision': decision,
        'status': 'live',
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      // Create new match model with updated values
      final updatedMatch = MatchModel(
        id: widget.match.id,
        team1: widget.match.team1,
        team2: widget.match.team2,
        venue: widget.match.venue,
        overs: widget.match.overs,
        date: widget.match.date,
        time: widget.match.time,
        tossWinner: tossWinner,
        tossDecision: decision,
        status: 'live',
        createdBy: widget.match.createdBy,
      );

      if (!context.mounted) return;

      // Navigate to team selection
      Navigator.pushReplacementNamed(
        context,
        '/team-selection',
        arguments: {
          'match': updatedMatch,
          'tossWinner': tossWinner,
          'tossDecision': decision,
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to update match: $e'),
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