import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/ball_model.dart';
import '../services/match_service.dart';

class MatchController extends ChangeNotifier {
  final MatchService matchService;

  MatchController({required this.matchService});
  
  // Match state
  late MatchModel match;
  MatchModel? _currentMatch;
  List<PlayerModel> _battingTeam = [];
  List<PlayerModel> _bowlingTeam = [];
  PlayerModel? striker;
  PlayerModel? nonStriker;
  PlayerModel? currentBowler;
  int currentInnings = 1;
  int runs = 0;
  int wickets = 0;
  double overs = 0.0;
  int balls = 0;
  int _legalBalls = 0;
  
  // Extras
  int wides = 0;
  int noBalls = 0;
  int byes = 0;
  int legByes = 0;

  // Over tracking
  DateTime? _lastRunTime;
  DateTime? _lastScoringTime;
  List<BallModel> _currentOverBalls = [];

  // Add new properties for dismissal details
  String? _dismissalType;
  PlayerModel? _fielder;
  PlayerModel? _wicketKeeper;

  // Add new property
  String? currentOverStats = '';

  // Add new properties for innings completion
  bool isInningsComplete = false;
  int targetOvers = 20;  // Default value

  // Add new property for yet-to-bat players
  List<PlayerModel> yetToBat = [];
  
  // Add these new getters and properties
  int target = 0;
  String get battingTeamName {
    if (_currentMatch == null) return '';
    if (_battingTeam.isEmpty) return '';
    
    if (currentInnings == 1) {
      return _currentMatch!.tossWinner == _currentMatch!.team1 && 
             _currentMatch!.tossDecision == 'bat' ? 
             _currentMatch!.team1 : _currentMatch!.team2;
    } else {
      // For second innings, it's the opposite team
      return _currentMatch!.tossWinner == _currentMatch!.team1 && 
             _currentMatch!.tossDecision == 'bat' ? 
             _currentMatch!.team2 : _currentMatch!.team1;
    }
  }
  
  String get bowlingTeamName {
    if (_currentMatch == null) return '';
    if (_bowlingTeam.isEmpty) return '';
    
    return _currentMatch!.team1 == battingTeamName ? _currentMatch!.team2 : _currentMatch!.team1;
  }

  List<BallModel> getAllBalls() {
    if (_currentMatch == null) return [];
    return List.from(_currentOverBalls);  // Return a copy to prevent modification
  }

  bool canAddExtras() {
    if (_lastScoringTime == null) return true;
    final now = DateTime.now();
    if (now.difference(_lastScoringTime!) < const Duration(milliseconds: 500)) {
      return false;
    }
    _lastScoringTime = now;
    return true;
  }

  // Getters
  MatchModel? get currentMatch => _currentMatch;
  List<PlayerModel> get battingTeam => _battingTeam;
  List<PlayerModel> get bowlingTeam => _bowlingTeam;
  int get extras => wides + noBalls + byes + legByes;
  int get legalBalls => _legalBalls;

  // Add getter for wicket description
  String getWicketDescription(String wicketType, PlayerModel? fielder, PlayerModel? bowler) {
    if (striker == null) return '';
    
    switch (wicketType) {
      case 'caught':
        return 'c ${fielder?.name ?? 'Unknown'} b ${bowler?.name ?? 'Unknown'}';
      case 'stumped':
        return 'st ${fielder?.name ?? 'Unknown'} b ${bowler?.name ?? 'Unknown'}';
      case 'bowled':
        return 'b ${bowler?.name ?? 'Unknown'}';
      case 'lbw':
        return 'lbw b ${bowler?.name ?? 'Unknown'}';
      case 'hit wicket':
        return 'hit wicket b ${bowler?.name ?? 'Unknown'}';
      case 'run out':
        return 'run out (${fielder?.name ?? 'Unknown'})';
      default:
        return wicketType;
    }
  }

  double get currentRunRate {
    if (overs == 0) return 0;
    return runs / overs;
  }

  List<PlayerModel>? get selectedTeam1Players => _currentMatch?.selectedTeam1Players;
  List<PlayerModel>? get selectedTeam2Players => _currentMatch?.selectedTeam2Players;

  bool canAddRuns() {
    if (_lastRunTime == null) return true;
    
    final now = DateTime.now();
    if (now.difference(_lastRunTime!) < const Duration(milliseconds: 500)) {
      return false;
    }
    _lastRunTime = now;
    return true;
  }

  void addRuns(int runs) {
    if (!canAddRuns()) return;
    
    // Check if we have striker and bowler - if not, show alerts
    if (striker == null || nonStriker == null) {
      debugPrint('Cannot add runs: batsmen not selected');
      return;
    }
    
    if (currentBowler == null) {
      debugPrint('Cannot add runs: bowler not selected');
      return;
    }

    // Update batsman stats
    striker!.stats['balls'] = (striker!.stats['balls'] ?? 0) + 1;
    striker!.stats['runs'] = (striker!.stats['runs'] ?? 0) + runs;
    
    if (runs == 4) striker!.stats['fours'] = (striker!.stats['fours'] ?? 0) + 1;
    if (runs == 6) striker!.stats['sixes'] = (striker!.stats['sixes'] ?? 0) + 1;

    // Update bowler stats
    currentBowler!.stats['balls'] = (currentBowler!.stats['balls'] ?? 0) + 1;
    currentBowler!.stats['runs'] = (currentBowler!.stats['runs'] ?? 0) + runs;

    // Record ball with updated stats
    recordBall(runs: runs);
    
    // Handle strike rotation for odd runs (1,3,5,7)
    if (runs % 2 == 1) {
      rotateStrike();
    }
    
    notifyListeners();
  }

  List<BallModel> getCurrentOverBalls() {
    return List.from(_currentOverBalls.where((ball) => ball.over == overs.floor())
        .toList());
  }

  Future<void> initializeMatch(MatchModel match) async {
    _currentMatch = match;
    targetOvers = match.overs;
    
    _setupTeams();
    
    // Initialize yetToBat with all batting team players
    yetToBat = List.from(_battingTeam);
    
    await loadLastMatchState();
    
    // If second innings, set target
    if (currentInnings == 2 && _currentMatch?.firstInningsScore != null) {
      target = (_currentMatch?.firstInningsScore ?? 0) + 1;
    }
    
    notifyListeners();
  }

  void _setupTeams() {
    if (_currentMatch == null) return;

    if (currentInnings == 1) {
      // First innings setup
      if (_currentMatch!.tossWinner == _currentMatch!.team1 &&
          _currentMatch!.tossDecision == 'bat' ||
          _currentMatch!.tossWinner == _currentMatch!.team2 &&
          _currentMatch!.tossDecision == 'field') {
        _battingTeam = _currentMatch!.selectedTeam1Players ?? [];
        _bowlingTeam = _currentMatch!.selectedTeam2Players ?? [];
      } else {
        _battingTeam = _currentMatch!.selectedTeam2Players ?? [];
        _bowlingTeam = _currentMatch!.selectedTeam1Players ?? [];
      }
    } else {
      // Second innings - swap teams
      if (_currentMatch!.tossWinner == _currentMatch!.team1 &&
          _currentMatch!.tossDecision == 'bat' ||
          _currentMatch!.tossWinner == _currentMatch!.team2 &&
          _currentMatch!.tossDecision == 'field') {
        _battingTeam = _currentMatch!.selectedTeam2Players ?? [];
        _bowlingTeam = _currentMatch!.selectedTeam1Players ?? [];
      } else {
        _battingTeam = _currentMatch!.selectedTeam1Players ?? [];
        _bowlingTeam = _currentMatch!.selectedTeam2Players ?? [];
      }
    }
  }

  bool _canScore() {
    if (_lastScoringTime == null) return true;
    final now = DateTime.now();
    if (now.difference(_lastScoringTime!).inMilliseconds < 500) {
      return false;
    }
    _lastScoringTime = now;
    return true;
  }

  // Update player stats in database
  Future<void> updatePlayerStats(PlayerModel player) async {
    if (_currentMatch == null) return;
    
    try {
      await matchService.updatePlayerStats(
        matchId: _currentMatch!.id!,
        playerId: player.id,
        stats: player.stats,
      );
    } catch (e) {
      print('Error updating player stats: $e');
    }
  }

  Future<void> recordBall({
    required int runs,
    String? extraType,
    int extraRuns = 0,
    String? wicketType,
    String? dismissedPlayerId,
    String? fielderId,
    BuildContext? context,
  }) async {
    try {
      if (!_canScore()) return;
      
      // Check if we have necessary players
      if (striker == null || nonStriker == null || currentBowler == null) {
        debugPrint('Cannot record ball: players not selected');
        return;
      }
      
      // Increment legal balls for non-extras or byes/leg-byes
      if (extraType == null || extraType == 'byes' || extraType == 'leg_byes') {
        _legalBalls++;
      }

      // Update total runs based on type
      int totalRuns = runs;
      if (extraType != null) {
        if (extraType == 'wide' || extraType == 'no_ball') {
          // Wides and no-balls: 1 extra + any additional runs
          totalRuns = 1 + extraRuns;
          
          // Update specific extra counters
          if (extraType == 'wide') {
            wides += totalRuns;
          } else {
            noBalls += totalRuns;
          }
        } else if (extraType == 'byes' || extraType == 'leg_byes') {
          // Byes and leg-byes: only count the extra runs
          totalRuns = extraRuns;
          
          // Update specific extra counters
          if (extraType == 'byes') {
            byes += extraRuns;
          } else {
            legByes += extraRuns;
          }
        }
      }

      // Increment balls count for legal deliveries
      if (extraType == null || extraType == 'byes' || extraType == 'leg_byes') {
        balls++;
        if (balls == 6) {
          overs += 1.0;
          balls = 0;
          _legalBalls = 0;
          
          // Rotate strike at end of over
          rotateStrike();
          
          // Clear current over balls for UI
          _currentOverBalls = _currentOverBalls.where((b) => b.over != overs.floor() - 1).toList();
        } else {
          // Update overs with decimal
          overs = overs.floorToDouble() + (balls / 10);
        }
      }

      // Update batsman stats based on type
      if (striker != null) {
        if (extraType == null || extraType == 'no_ball') {
          // Regular runs or no-ball faced by batsman count toward their stats
          striker!.stats['balls'] = (striker!.stats['balls'] ?? 0) + 1;
          
          // Only add runs to batsman if not byes/leg-byes
          if (extraType != 'byes' && extraType != 'leg_byes') {
            striker!.stats['runs'] = (striker!.stats['runs'] ?? 0) + runs;
            if (runs == 4) striker!.stats['fours'] = (striker!.stats['fours'] ?? 0) + 1;
            if (runs == 6) striker!.stats['sixes'] = (striker!.stats['sixes'] ?? 0) + 1;
          }
          
          await updatePlayerStats(striker!);
        }
      }

      // Update bowler stats
      if (currentBowler != null) {
        // All balls except wides count toward bowler's ball count
        if (extraType != 'wide') {
          currentBowler!.stats['balls'] = (currentBowler!.stats['balls'] ?? 0) + 1;
        }
        
        // All runs count toward bowler's runs
        currentBowler!.stats['runs'] = (currentBowler!.stats['runs'] ?? 0) + totalRuns;
        
        // Wickets only count for bowler if not run-out
        if (wicketType != null && wicketType != 'run out') {
          currentBowler!.stats['wickets'] = (currentBowler!.stats['wickets'] ?? 0) + 1;
        }
        
        await updatePlayerStats(currentBowler!);
      }

      // Create and save ball
      final ball = BallModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchId: _currentMatch!.id!,
        batterId: striker?.id ?? '',
        bowlerId: currentBowler?.id ?? '',
        runs: runs,
        extraType: extraType,
        extraRuns: extraRuns,
        wicketType: wicketType,
        dismissedPlayerId: dismissedPlayerId,
        fielderId: fielderId,
        timestamp: DateTime.now(),
        over: overs.floor(),
        ball: balls,
        innings: currentInnings,
        runsInInnings: this.runs + totalRuns,
      );

      // Save ball to database first
      await matchService.addBall(ball);

      // Add to current over
      _currentOverBalls.add(ball);

      // Update total runs
      this.runs += totalRuns;

      // Update current over stats for display
      final ballText = _getBallText(runs, extraType, wicketType, extraRuns);
      currentOverStats = (currentOverStats ?? '') + ' $ballText';

      // Handle strike rotation for odd runs (except on wicket)
      if (wicketType == null && (runs % 2 == 1 || (extraRuns % 2 == 1 && (extraType == 'byes' || extraType == 'leg_byes')))) {
        rotateStrike();
      }

      // Update match summary
      await matchService.updateMatchSummary(
        matchId: _currentMatch!.id!,
        data: {
          'currentInnings': currentInnings,
          'runs': this.runs,
          'wickets': wickets,
          'overs': overs,
          'extras': extras,
          'wides': wides,
          'noBalls': noBalls,
          'byes': byes,
          'legByes': legByes,
          'currentOverBalls': _currentOverBalls.length,
          'lastBall': {
            'runs': runs,
            'extraType': extraType,
            'extraRuns': extraRuns,
            'wicketType': wicketType,
          },
        },
      );

      // Check if innings is complete
      if (wickets >= 10 || overs >= targetOvers) {
        isInningsComplete = true;
        await matchService.updateMatchSummary(
          matchId: _currentMatch!.id!,
          data: {
            'isInningsComplete': true,
            'finalScore': this.runs,
            'wickets': wickets,
            'overs': overs,
          },
        );
        
        // If it's first innings, set target for second innings
        if (currentInnings == 1) {
          await matchService.updateMatchSummary(
            matchId: _currentMatch!.id!,
            data: {'firstInningsScore': this.runs},
          );
          target = this.runs + 1;
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error recording ball: $e');
    }
  }

  String _getBallText(int runs, String? extraType, String? wicketType, int extraRuns) {
    if (wicketType != null) return 'W';
    if (extraType != null) {
      switch (extraType) {
        case 'wide':
          return extraRuns > 0 ? 'Wd+${extraRuns}' : 'Wd';
        case 'no_ball':
          return extraRuns > 0 ? 'Nb+${extraRuns}' : 'Nb';
        case 'byes':
          return 'B${extraRuns}';
        case 'leg_byes':
          return 'Lb${extraRuns}';
        default:
          return '';
      }
    }
    return '$runs';
  }

  // Show dialog to select new bowler
  Future<void> selectBowlerForNextOver(BuildContext context) async {
    final newBowler = await showDialog<PlayerModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select Bowler for Next Over'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: bowlingTeam.length,
            itemBuilder: (context, index) {
              final player = bowlingTeam[index];
              final overs = (player.stats['balls'] ?? 0) ~/ 6;
              final balls = (player.stats['balls'] ?? 0) % 6;
              final runs = player.stats['runs'] ?? 0;
              final wickets = player.stats['wickets'] ?? 0;
              
              return ListTile(
                title: Text(player.name),
                subtitle: Text('O: $overs.${balls} R: $runs W: $wickets'),
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
      ),
    );

    if (newBowler != null) {
      changeBowler(newBowler);
      currentOverStats = '';
      notifyListeners();
    }
  }

  // Handle player selection for caught dismissals
  Future<void> handleFielderSelection(BuildContext context, String wicketType) async {
    final fielder = await showDialog<PlayerModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select ${wicketType == 'stumped' ? 'Wicket-keeper' : 'Fielder'}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: bowlingTeam.length,
            itemBuilder: (context, index) {
              final player = bowlingTeam[index];
              return ListTile(
                title: Text(player.name),
                subtitle: Text('#${player.jerseyNumber}'),
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
      ),
    );

    if (fielder != null && striker != null) {
      await recordBall(
        runs: 0,
        wicketType: wicketType,
        dismissedPlayerId: striker!.id,
        fielderId: fielder.id,
      );
      
      // Mark batsman as out
      if (striker != null) {
        striker!.stats['out'] = true;
        await updatePlayerStats(striker!);
      }
      
      wickets++;
      
      // Prompt for next batsman if not all out
      if (wickets < 10) {
        await selectNextBatsman(context);
      } else {
        isInningsComplete = true;
        await endInnings();
      }
    }
  }

  // Update match summary with current state
  Future<void> updateMatchSummary() async {
    if (_currentMatch == null) return;

    try {
      await matchService.updateMatchSummary(
        matchId: _currentMatch!.id!,
        data: {
          'currentInnings': currentInnings,
          'runs': runs,
          'wickets': wickets,
          'overs': overs,
          'extras': extras,
          'wides': wides,
          'noBalls': noBalls,
          'byes': byes,
          'legByes': legByes,
          'target': target,
          'isInningsComplete': isInningsComplete,
        },
      );
    } catch (e) {
      print('Error updating match summary: $e');
    }
  }

  // Rotate strike between striker and non-striker
  void rotateStrike() {
    if (striker != null && nonStriker != null) {
      final temp = striker;
      striker = nonStriker;
      nonStriker = temp;
      notifyListeners();
    }
  }

  // Set the current bowler
  void changeBowler(PlayerModel newBowler) {
    currentBowler = newBowler;
    notifyListeners();
  }

  // Get a stream of ball events for the match
  Stream<List<BallModel>> getBallsStream() {
    if (_currentMatch == null) return Stream.value([]);
    
    return matchService.getBalls(_currentMatch!.id!)
        .map((balls) => balls..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  // Check if innings can be ended
  bool canEndInnings() {
    return wickets == 10 || overs >= (_currentMatch?.overs ?? 0);
  }

    // Select next batsman after a wicket
  Future<void> selectNextBatsman(BuildContext context) async {
    final nextBatsman = await showDialog<PlayerModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select Next Batsman'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: yetToBat.length,
            itemBuilder: (context, index) {
              final player = yetToBat[index];
              return ListTile(
                title: Text(player.name),
                subtitle: Text('#${player.jerseyNumber}'),
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
      ),
    );

    if (nextBatsman != null) {
      striker = nextBatsman;
      yetToBat.remove(nextBatsman);
      notifyListeners();
    }
  }

  // End the current innings
  Future<void> endInnings() async {
    if (_currentMatch == null) return;

    isInningsComplete = true;    if (currentInnings == 1) {
      await matchService.updateMatchSummary(
        matchId: _currentMatch!.id!,
        data: {'firstInningsScore': runs},
      );
      // Reload the match to get updated firstInningsScore
          }

    await updateMatchSummary();
    notifyListeners();
  }

  // Load the last state of the match from the database
Future<void> loadLastMatchState() async {
    if (_currentMatch == null) return;

    try {
      final matchState = await matchService.getMatchSummary(_currentMatch!.id!);
      if (matchState != null) {
        currentInnings = matchState['currentInnings'] ?? 1;
        runs = matchState['runs'] ?? 0;
        wickets = matchState['wickets'] ?? 0;
        overs = matchState['overs'] ?? 0.0;
        wides = matchState['wides'] ?? 0;
        noBalls = matchState['noBalls'] ?? 0;
        byes = matchState['byes'] ?? 0;
        legByes = matchState['legByes'] ?? 0;
        isInningsComplete = matchState['isInningsComplete'] ?? false;
        
        if (currentInnings == 2) {
          target = matchState['target'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading match state: $e');
    }
  }
}