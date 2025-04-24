import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../services/match_service.dart';
import '../models/ball_model.dart';

class MatchScoringScreen extends StatefulWidget {
  final MatchModel match;

  const MatchScoringScreen({
    super.key, 
    required this.match,
  });

  @override
  State<MatchScoringScreen> createState() => _MatchScoringScreenState();
}

class NumberPickerDialog extends StatelessWidget {
  final String title;
  final int minValue;
  final int maxValue;

  const NumberPickerDialog({
    super.key,
    required this.title,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            maxValue - minValue + 1,
            (index) => SizedBox(
              width: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, minValue + index),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('${minValue + index}'),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}
class PlayerSelectionDialog extends StatelessWidget {
  final String title;
  final List<PlayerModel> players;
  final List<PlayerModel> selectedPlayers;

  const PlayerSelectionDialog({
    super.key,
    required this.title,
    required this.players,
    required this.selectedPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final isSelected = selectedPlayers.contains(player);
            
            return ListTile(
              title: Text(player.name),
              subtitle: Text('#${player.jerseyNumber} - ${player.role}'),
              enabled: !isSelected,
              onTap: () => Navigator.pop(context, player),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}

class _MatchScoringScreenState extends State<MatchScoringScreen> {
  late MatchController controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    controller = MatchController(matchService: MatchService());
    _initializeMatch();
  }

  Future<void> _initializeMatch() async {
    await controller.initializeMatch(widget.match);
    setState(() => isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.match.team1} vs ${widget.match.team2}'),
          backgroundColor: Colors.blue[900],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<MatchController>(
      builder: (context, controller, _) {
        if (!_isTossCompleted()) {
          return _buildTossScreen();
        }

        if (!_isOpeningPlayersSelected()) {
          return _buildPlayerSelectionScreen();
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _buildScoreHeader(controller),
              const TabBar(
                tabs: [
                  Tab(text: 'SCORING'),
                  Tab(text: 'SCORECARD'),
                  Tab(text: 'COMMENTARY'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildScoringTab(controller),
                    ScorecardWidget(match: widget.match),
                    _buildCommentaryTab(controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isTossCompleted() {
    return widget.match.tossWinner != null && 
           widget.match.tossDecision != null;
  }

  Widget _buildTossScreen() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Toss',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButton<String>(
                hint: const Text('Select Toss Winner'),
                value: widget.match.tossWinner,
                items: [
                  DropdownMenuItem(
                    value: widget.match.team1,
                    child: Text(widget.match.team1),
                  ),
                  DropdownMenuItem(
                    value: widget.match.team2,
                    child: Text(widget.match.team2),
                  ),
                ],
                onChanged: (value) {
                  // Update toss winner
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Choose to bat
                    },
                    child: const Text('BAT'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Choose to field
                    },
                    child: const Text('FIELD'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOpeningPlayersSelected() {
    return controller.striker != null && 
           controller.nonStriker != null && 
           controller.currentBowler != null;
  }

  Widget _buildPlayerSelectionScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Opening Players',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _selectStriker(context),
            child: Text(
              'Select Striker: ${controller.striker?.name ?? "Not Selected"}',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _selectNonStriker(context),
            child: Text(
              'Select Non-Striker: ${controller.nonStriker?.name ?? "Not Selected"}',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _selectBowler(context),
            child: Text(
              'Select Bowler: ${controller.currentBowler?.name ?? "Not Selected"}',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStriker(BuildContext context) async {
    final player = await showDialog<PlayerModel>(
      context: context,
      builder: (context) => PlayerSelectionDialog(
        title: 'Select Striker',
        players: controller.battingTeam,
        selectedPlayers: [
          if (controller.nonStriker != null) controller.nonStriker!,
        ],
      ),
    );

    if (player != null) {
      controller.striker = player;
      controller.notifyListeners();
    }
  }

  Future<void> _selectNonStriker(BuildContext context) async {
    final player = await showDialog<PlayerModel>(
      context: context,
      builder: (context) => PlayerSelectionDialog(
        title: 'Select Non-Striker',
        players: controller.battingTeam,
        selectedPlayers: [
          if (controller.striker != null) controller.striker!,
        ],
      ),
    );

    if (player != null) {
      controller.nonStriker = player;
      controller.notifyListeners();
    }
  }

  Future<void> _selectBowler(BuildContext context) async {
    final player = await showDialog<PlayerModel>(
      context: context,
      builder: (context) => PlayerSelectionDialog(
        title: 'Select Bowler',
        players: controller.bowlingTeam,
        selectedPlayers: const [],
      ),
    );

    if (player != null) {
      controller.currentBowler = player;
      controller.notifyListeners();
    }
  }

  // Widget _buildScoreHeader(MatchController controller) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     color: Colors.blue[900],
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               '${controller.runs}/${controller.wickets}',
  //               style: const TextStyle(
  //                 fontSize: 24,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //               ),
  //             ),
  //             Text(
  //               'Overs: ${controller.overs.floor()}.${controller.balls}',
  //               style: const TextStyle(
  //                 fontSize: 18,
  //                 color: Colors.white,
  //               ),
  //             ),
  //           ],
  //         ),
  //         // More score header content...
  //       ],
  //     ),
  //   );
  // }
 Widget _buildScoreHeader(MatchController controller) {
  return Container(
    padding: const EdgeInsets.all(16),
    color: Colors.blue[900],
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${controller.runs}/${controller.wickets}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Overs: ${controller.overs.floor()}.${controller.balls}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Striker info
            Expanded(
              child: Text(
                '${controller.striker?.name ?? ''} * ${controller.striker?.stats['runs'] ?? 0}(${controller.striker?.stats['balls'] ?? 0})',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Non-striker info
            Expanded(
              child: Text(
                '${controller.nonStriker?.name ?? ''} ${controller.nonStriker?.stats['runs'] ?? 0}(${controller.nonStriker?.stats['balls'] ?? 0})',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bowler: ${controller.currentBowler?.name ?? ''} '
          '${controller.currentBowler?.stats['wickets'] ?? 0}-${controller.currentBowler?.stats['runs'] ?? 0}',
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

  Widget _buildScoringTab(MatchController controller) {
    return Column(
      children: [
        _buildCurrentOverDisplay(controller),
        _buildRunButtons(controller),
        _buildExtraButtons(controller),
      ],
    );
  }

  Widget _buildRunButtons(MatchController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: List.generate(7, (index) {
          return ElevatedButton(
            onPressed: () => _handleRuns(index, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '$index',
              style: const TextStyle(fontSize: 24),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExtraButtons(MatchController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildExtraButton('WIDE', controller),
          _buildExtraButton('NO BALL', controller),
          _buildExtraButton('BYE', controller),
          _buildExtraButton('LEG BYE', controller),
          ElevatedButton(
            onPressed: () => _handleWicket(controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('WICKET'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraButton(String type, MatchController controller) {
    return ElevatedButton(
      onPressed: () => _handleExtras(type, controller),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: Text(type),
    );
  }

void _handleRuns(int runs, MatchController controller) async {
  await controller.recordBall(
    runs: runs,
    extraType: null,
    extraRuns: 0,
  );

  // Over completion is handled by controller
  if (controller.balls == 0 && controller.overs.floor() > 0) {
    await _showNewBowlerDialog(controller);
  }
}

Future<void> _handleExtras(String type, MatchController controller) async {
  final extraRuns = await showDialog<int>(
    context: context,
    builder: (context) => NumberPickerDialog(
      title: 'Additional Runs',
      minValue: 0,
      maxValue: 4,
    ),
  );

  if (extraRuns != null) {
    String extraType = '';
    switch (type) {
      case 'WIDE':
        extraType = 'wide';
        break;
      case 'NO BALL':
        extraType = 'no_ball';
        break;
      case 'BYE':
        extraType = 'byes';
        break;
      case 'LEG BYE':
        extraType = 'leg_byes';
        break;
    }

    await controller.recordBall(
      runs: 0,
      extraType: extraType,
      extraRuns: extraRuns,
    );
  }
}
  
Future<void> _handleWicket(MatchController controller) async {
  final wicketType = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Wicket Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Bowled'),
            onTap: () => Navigator.pop(context, 'bowled'),
          ),
          ListTile(
            title: const Text('Caught'),
            onTap: () => Navigator.pop(context, 'caught'),
          ),
          ListTile(
            title: const Text('LBW'),
            onTap: () => Navigator.pop(context, 'lbw'),
          ),
          ListTile(
            title: const Text('Run Out'),
            onTap: () => Navigator.pop(context, 'run_out'),
          ),
        ],
      ),
    ),
  );

  if (wicketType != null) {
    controller.wickets++;
    controller.balls++; // Count wicket as a ball
    
    // Record the wicket ball
   await controller.recordBall(
        runs: 0,
        wicketType: wicketType,
        dismissedPlayerId: controller.striker?.id,
      );
      if (controller.wickets < 10) {
        await controller.selectNextBatsman(context);
      } else {
        await _handleInningsComplete(controller);
      }
    // Mark batsman as out
    if (controller.striker != null) {
      controller.striker!.stats['out'] = true;
      controller.striker!.stats['wicketType'] = wicketType;
    }
    
    if (controller.balls >= 6) {
      controller.balls = 0;
      controller.overs++;
      await _showNewBowlerDialog(controller);
    }

    if (controller.wickets < 10) {
      await _selectNewBatsman(controller);
    } else {
      await _handleInningsComplete(controller);
    }
    
    controller.notifyListeners();
  }
}

Future<void> _selectNewBatsman(MatchController controller) async {
  final availableBatsmen = controller.battingTeam
      .where((p) => p.stats['out'] != true && p != controller.nonStriker)
      .toList();

  if (availableBatsmen.isEmpty) {
    await _handleInningsComplete(controller);
    return;
  }

  final newBatsman = await showDialog<PlayerModel>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PlayerSelectionDialog(
      title: 'Select New Batsman',
      players: availableBatsmen,
      selectedPlayers: const [],
    ),
  );

  if (newBatsman != null) {
    controller.striker = newBatsman;
    controller.notifyListeners();
  }
}
  Future<void> _showNewBowlerDialog(MatchController controller) async {
    await controller.selectBowlerForNextOver(context);
  }

  Future<void> _handleInningsComplete(MatchController controller) async {
    await controller.endInnings();
    
    if (controller.currentInnings == 1) {
      // Start second innings
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('First Innings Complete'),
          content: Text(
            'Score: ${controller.runs}/${controller.wickets}\n'
            'Overs: ${controller.overs}\n'
            'Target: ${controller.runs + 1}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startSecondInnings(controller);
              },
              child: const Text('Start Second Innings'),
            ),
          ],
        ),
      );
    } else {
      // Match complete
      _showMatchSummary(controller);
    }
  }

  void _startSecondInnings(MatchController controller) {
    controller.currentInnings = 2;
    controller.runs = 0;
    controller.wickets = 0;
    controller.overs = 0;
    controller.balls = 0;
    controller.striker = null;
    controller.nonStriker = null;
    controller.currentBowler = null;
    controller.notifyListeners();
  }

  void _showMatchSummary(MatchController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Match Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First Innings: ${controller.match.firstInningsScore}'),
            Text('Second Innings: ${controller.runs}/${controller.wickets}'),
            const SizedBox(height: 16),
            Text(
              'Winner: ${_getWinningTeam(controller)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getWinningTeam(MatchController controller) {
    if (controller.runs > controller.match.firstInningsScore!) {
      return controller.battingTeamName;
    } else if (controller.runs < controller.match.firstInningsScore!) {
      return controller.bowlingTeamName;
    } else {
      return 'Match Tied';
    }
  }

  Widget _buildCurrentOverDisplay(MatchController controller) {
    final currentOverBalls = controller.getCurrentOverBalls();
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THIS OVER',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var ball in currentOverBalls)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getBallColor(ball),
                    ),
                    child: Text(
                      _getBallText(ball),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentaryTab(MatchController controller) {
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
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getBallColor(ball),
                child: Text(
                  _getBallText(ball),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(_getCommentaryText(ball, controller)),
              subtitle: Text('Over ${ball.over}.${ball.ball}'),
            );
          },
        );
      },
    );
  }

  Color _getBallColor(BallModel ball) {
    if (ball.wicketType != null) return Colors.red;
    if (ball.extraType != null) return Colors.orange;
    if (ball.runs == 4) return Colors.blue;
    if (ball.runs == 6) return Colors.purple;
    return ball.runs > 0 ? Colors.green : Colors.grey;
  }

  String _getBallText(BallModel ball) {
    if (ball.wicketType != null) return 'W';
    if (ball.extraType != null) {
      switch (ball.extraType) {
        case 'wide': return 'WD';
        case 'no_ball': return 'NB';
        case 'byes': return 'B';
        case 'leg_byes': return 'LB';
        default: return '';
      }
    }
    return '${ball.runs}';
  }

  String _getCommentaryText(BallModel ball, MatchController controller) {
    final batter = controller.battingTeam.firstWhere(
      (p) => p.id == ball.batterId,
      orElse: () => PlayerModel(
        name: 'Unknown',
        id: 'unknown',
        jerseyNumber: 0,
        role: 'Unknown',
        battingStyle: 'Unknown',
      ),
    );
    
    final bowler = controller.bowlingTeam.firstWhere(
      (p) => p.id == ball.bowlerId,
      orElse: () => PlayerModel(
        name: 'Unknown',
        id: 'unknown',
        jerseyNumber: 0,
        role: 'Unknown',
        battingStyle: 'Unknown',
      ),
    );

    if (ball.wicketType != null) {
      return '${batter.name} OUT! (${ball.wicketType})';
    }

    String text = '${bowler.name} to ${batter.name}, ';
    if (ball.extraType != null) {
      text += '${ball.extraType} + ${ball.extraRuns} runs';
    } else {
      text += '${ball.runs} runs';
    }
    return text;
  }
}

class ScorecardWidget extends StatelessWidget {
  final MatchModel match;

  const ScorecardWidget({
    super.key,
    required this.match,
  });

  String _calculateStrikeRate(int runs, int balls) {
    if (balls == 0) return '0.00';
    return ((runs * 100) / balls).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchController>(
      builder: (context, controller, _) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'BATTING'),
                  Tab(text: 'BOWLING'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBattingScorecard(controller),
                    _buildBowlingScorecard(controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

Widget _buildBattingScorecard(MatchController controller) {
  return ListView.builder(
    itemCount: controller.battingTeam.length,
    itemBuilder: (context, index) {
      final player = controller.battingTeam[index];
      final stats = player.stats;
      
      // Don't show yet to bat for out players
      if (stats['out'] == true) {
        return ListTile(
          title: Text(player.name),
          subtitle: Text('OUT'),
          trailing: Text(
            '${stats['runs'] ?? 0}(${stats['balls'] ?? 0}) '
            '${stats['fours'] ?? 0}x4 ${stats['sixes'] ?? 0}x6 '
            'SR: ${_calculateStrikeRate(stats['runs'] ?? 0, stats['balls'] ?? 0)}',
          ),
        );
      }

      // Only show yet to bat for players who haven't batted
      if ((stats['balls'] ?? 0) == 0) {
        return ListTile(
          title: Text(player.name),
          subtitle: Text('Yet to bat'),
        );
      }
      
      return ListTile(
        title: Text(player.name),
        subtitle: Text('Batting'),
        trailing: Text(
          '${stats['runs'] ?? 0}(${stats['balls'] ?? 0}) '
          '${stats['fours'] ?? 0}x4 ${stats['sixes'] ?? 0}x6 '
          'SR: ${_calculateStrikeRate(stats['runs'] ?? 0, stats['balls'] ?? 0)}',
        ),
      );
    },
  );
}

Widget _buildBowlingScorecard(MatchController controller) {
  return ListView.builder(
    itemCount: controller.bowlingTeam.length,
    itemBuilder: (context, index) {
      final player = controller.bowlingTeam[index];
      final stats = player.stats;
      
      // Calculate bowling figures
      final overs = (stats['balls'] ?? 0) ~/ 6;
      final balls = (stats['balls'] ?? 0) % 6;
      final economy = stats['balls'] != null && stats['balls'] > 0 
          ? ((stats['runs'] ?? 0) * 6 / (stats['balls'] ?? 1)).toStringAsFixed(2)
          : '0.00';

      if ((stats['balls'] ?? 0) == 0) {
        return ListTile(
          title: Text(player.name),
          subtitle: const Text('Yet to bowl'),
        );
      }
      
      return ListTile(
        title: Text(player.name),
        subtitle: Text('Economy: $economy'),
        trailing: Text(
          '${stats['wickets'] ?? 0}-${stats['runs'] ?? 0} '
          '($overs.${balls})',
        ),
      );
    },
  );
}
}