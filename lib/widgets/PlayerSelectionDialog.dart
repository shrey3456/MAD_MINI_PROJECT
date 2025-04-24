import 'package:flutter/material.dart';
import '../models/player_model.dart';

class PlayerSelectionDialog extends StatelessWidget {
  final List<PlayerModel> players;
  final String title;
  final bool showBowlingStats;

  const PlayerSelectionDialog({
    Key? key,
    required this.players,
    required this.title,
    this.showBowlingStats = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: players.map((player) => ListTile(
            title: Text(player.name),
            onTap: () => Navigator.pop(context, player),
          )).toList(),
        ),
      ),
    );
  }
}