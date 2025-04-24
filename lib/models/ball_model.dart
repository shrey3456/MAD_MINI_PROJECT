import 'package:cloud_firestore/cloud_firestore.dart';

class BallModel {
  final String? id;
  final String matchId;
  final String batterId;
  final String? bowlerId;
  final int runs;
  final String? extraType;
  final int extraRuns;
  final String? wicketType;
  final String? dismissedPlayerId;
  final String? fielderId;
  final DateTime timestamp;
  final int over;
  final int ball;
  final int innings;
  final int runsInInnings;
  

  const BallModel({
    this.id,
    required this.matchId,
    required this.batterId,
    this.bowlerId,
    required this.runs,
    this.extraType,
    required this.extraRuns,
    this.wicketType,
    this.dismissedPlayerId,
    this.fielderId,
    required this.timestamp,
    required this.over,
    required this.ball,
    required this.innings,
    required this.runsInInnings,
  });

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'batterId': batterId,
    'bowlerId': bowlerId,
    'runs': runs,
    'extraType': extraType,
    'extraRuns': extraRuns,
    'wicketType': wicketType,
    'dismissedPlayerId': dismissedPlayerId,
    'fielderId': fielderId,
    'timestamp': Timestamp.fromDate(timestamp),
    'over': over,
    'ball': ball,
    'innings': innings,
  };

  factory BallModel.fromJson(Map<String, dynamic> json, String id) {
    return BallModel(
      id: id,
      matchId: json['matchId'],
      batterId: json['batterId'],
      bowlerId: json['bowlerId'] as String?,
      runs: json['runs'],
      extraType: json['extraType'],
      extraRuns: json['extraRuns'] ?? 0,
      wicketType: json['wicketType'],
      dismissedPlayerId: json['dismissedPlayerId'],
      fielderId: json['fielderId'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      over: json['over'],
      ball: json['ball'],
      innings: json['innings'],
      runsInInnings: json['runsInInnings'],
    );
  }

  String get ballDisplay {
    String display = '$runs';
    if (wicketType != null) {
      display = 'W';
    } else if (extraType != null) {
      if (extraType == 'wide') {
        display = 'Wd+$extraRuns';
      } else if (extraType == 'no_ball') {
        display = 'Nb+$extraRuns';
      } else if (extraType == 'byes') {
        display = 'B+$extraRuns';
      }
    }
    return display;
  }

  String get commentary {
    if (wicketType != null) {
      return 'WICKET! ${wicketType!.toUpperCase()}';
    }
    if (extraType != null) {
      return '${extraType!.toUpperCase()}! $extraRuns runs';
    }
    if (runs == 4) {
      return 'FOUR! Beautiful shot';
    }
    if (runs == 6) {
      return 'SIX! Into the crowd';
    }
    return '$runs runs';
  }
}