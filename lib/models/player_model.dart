import 'package:flutter/foundation.dart';

enum PlayerRole {
  batsman,
  bowler,
  allRounder,
  wicketKeeper
}

enum BattingStyle {
  rightHanded,
  leftHanded
}

enum BowlingStyle {
  fastPacer,
  mediumFastPacer,
  mediumPacer,
  offSpinner,
  legSpinner,
  leftArmSpinner
}

enum BowlingArm {
  rightArm,
  leftArm
}

class PlayerModel {
  final String id; // Added 'id' field
  final String name;
  final int jerseyNumber;
  final String role;
  final String battingStyle;
  final String? bowlingStyle;
  final String? bowlingArm;
  final bool isCaptain;
  final bool isViceCaptain;
  final bool isWicketKeeper;
  Map<String, dynamic> stats;

  PlayerModel({
    required this.id, // Initialize 'id'
    required this.name,
    required this.jerseyNumber,
    required this.role,
    required this.battingStyle,
    this.bowlingStyle,
    this.bowlingArm,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.isWicketKeeper = false,
    Map<String, dynamic>? stats,
  }) : stats = stats ?? {
    'runs': 0,
    'balls': 0,
    'fours': 0,
    'sixes': 0,
    'overs': 0.0,
    'maidens': 0,
    'wickets': 0,
    'runsConceded': 0,
  };

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Added 'id' field
      'name': name,
      'jerseyNumber': jerseyNumber,
      'role': role,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'bowlingArm': bowlingArm,
      'isCaptain': isCaptain,
      'isViceCaptain': isViceCaptain,
      'isWicketKeeper': isWicketKeeper,
      'stats': stats,
    };
  }

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id']?.toString() ?? '', // Added 'id' field
      name: json['name']?.toString() ?? '',
      jerseyNumber: (json['jerseyNumber'] as num?)?.toInt() ?? 0,
      role: json['role']?.toString() ?? 'batsman',
      battingStyle: json['battingStyle']?.toString() ?? 'rightHanded',
      bowlingStyle: json['bowlingStyle']?.toString(),
      bowlingArm: json['bowlingArm']?.toString(),
      isCaptain: json['isCaptain'] as bool? ?? false,
      isViceCaptain: json['isViceCaptain'] as bool? ?? false,
      isWicketKeeper: json['isWicketKeeper'] as bool? ?? false,
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
    );
  }

  int get runs => stats['runs'] ?? 0;
  int get balls => stats['balls'] ?? 0;
  int get fours => stats['fours'] ?? 0;
  int get sixes => stats['sixes'] ?? 0;
  double get overs => (stats['overs'] ?? 0).toDouble();
  int get maidens => stats['maidens'] ?? 0;
  int get wickets => stats['wickets'] ?? 0;
  int get runsConceded => stats['runsConceded'] ?? 0;

  double get strikeRate => balls > 0 ? (runs * 100 / balls) : 0.0;
  double get economy => overs > 0 ? (runsConceded / overs) : 0.0;

  void updateStats(String key, dynamic value) {
    stats[key] = value;
  }
}