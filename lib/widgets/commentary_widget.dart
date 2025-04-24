import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/ball_model.dart';
import '../models/match_model.dart';

class CommentaryTab extends StatelessWidget {
  final MatchModel match;
  
  const CommentaryTab({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchController>(
      builder: (context, controller, _) {
        return StreamBuilder<List<BallModel>>(
          stream: controller.getBallsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final balls = snapshot.data!;
            return ListView.builder(
              itemCount: balls.length,
              itemBuilder: (context, index) {
                final ball = balls[index];
                return CommentaryCard(ball: ball, controller: controller);
              },
            );
          },
        );
      },
    );
  }
}

class CommentaryCard extends StatelessWidget {
  final BallModel ball;
  final MatchController controller;

  const CommentaryCard({
    super.key,
    required this.ball,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final commentary = _getCommentary();
    final color = _getBallColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            _getBallText(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(commentary),
        subtitle: Text(
          '${ball.runsInInnings}/${controller.wickets} (${ball.over}.${ball.ball})',
        ),
      ),
    );
  }

  String _getBallText() {
    if (ball.wicketType != null) return 'W';
    if (ball.extraType != null) {
      switch (ball.extraType) {
        case 'wide': return 'Wd';
        case 'no_ball': return 'Nb';
        case 'byes': return 'B';
        case 'leg_byes': return 'Lb';
        default: return '';
      }
    }
    return '${ball.runs}';
  }

  Color _getBallColor() {
    if (ball.wicketType != null) return Colors.red;
    if (ball.extraType == 'wide') return Colors.purple;
    if (ball.extraType == 'no_ball') return Colors.orange;
    if (ball.runs == 4) return Colors.blue;
    if (ball.runs == 6) return Colors.green;
    return Colors.grey;
  }

  String _getCommentary() {
    final batter = controller.battingTeam
        .firstWhere((p) => p.id == ball.batterId);
    final bowler = controller.bowlingTeam
        .firstWhere((p) => p.id == ball.bowlerId);

    if (ball.wicketType != null) {
      return _getWicketCommentary(batter.name, bowler.name);
    }

    if (ball.extraType != null) {
      return _getExtrasCommentary(batter.name, bowler.name);
    }

    return _getRunsCommentary(batter.name, bowler.name);
  }

  String _getWicketCommentary(String batter, String bowler) {
    switch (ball.wicketType) {
      case 'bowled':
        return '$bowler to $batter, OUT! Clean bowled!';
      case 'caught':
        final fielder = controller.bowlingTeam
            .firstWhere((p) => p.id == ball.fielderId);
        return '$bowler to $batter, OUT! Caught by ${fielder.name}!';
      case 'lbw':
        return '$bowler to $batter, OUT! LBW!';
      case 'run_out':
        final fielder = controller.bowlingTeam
            .firstWhere((p) => p.id == ball.fielderId);
        return '$bowler to $batter, OUT! Run out by ${fielder.name}!';
      default:
        return '$bowler to $batter, OUT!';
    }
  }

  String _getExtrasCommentary(String batter, String bowler) {
    switch (ball.extraType) {
      case 'wide':
        return '$bowler to $batter, Wide! ${ball.extraRuns > 1 ? '+${ball.extraRuns - 1} runs' : ''}';
      case 'no_ball':
        return '$bowler to $batter, No ball! ${ball.extraRuns > 1 ? '+${ball.extraRuns - 1} runs' : ''}';
      case 'byes':
        return '$bowler to $batter, ${ball.extraRuns} byes';
      case 'leg_byes':
        return '$bowler to $batter, ${ball.extraRuns} leg byes';
      default:
        return '$bowler to $batter';
    }
  }

  String _getRunsCommentary(String batter, String bowler) {
    switch (ball.runs) {
      case 0:
        return '$bowler to $batter, no run';
      case 4:
        return '$bowler to $batter, FOUR! Beautiful shot!';
      case 6:
        return '$bowler to $batter, SIX! Maximum!';
      default:
        return '$bowler to $batter, ${ball.runs} runs';
    }
  }
}