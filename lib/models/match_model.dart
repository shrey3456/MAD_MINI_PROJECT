import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

enum MatchStatus {
  upcoming,
  live,
  completed
}

class MatchModel {
  final String? id;
  final String team1;
  final String team2;
  final String venue;
  final String? status;
  final String? battingTeam;
  final int? currentScore;
  final int? currentWickets;
  final String? currentOvers;
  final int? currentInnings;
  final int? firstInningsScore;
  final int overs;
  final DateTime date;
  final String? time;
  final String? createdBy;
  final List<PlayerModel>? team1Players;
  final List<PlayerModel>? team2Players;
  final List<PlayerModel>? selectedTeam1Players;  // Add this field
  final List<PlayerModel>? selectedTeam2Players;  // Add this field
  final Map<String, dynamic>? score;
  final String? tossWinner;
  final String? tossDecision;

  MatchModel({
    this.id,
    required this.team1,
    required this.team2,
    required this.venue,
    this.status = 'upcoming',
    this.battingTeam,
    this.currentScore,
    this.currentWickets,
    this.currentOvers,
    this.currentInnings,
    this.firstInningsScore,
    required this.overs,
    required this.date,
    this.time,
    this.createdBy,
    this.team1Players,
    this.team2Players,
    this.selectedTeam1Players,  // Add this parameter
    this.selectedTeam2Players,  // Add this parameter
    this.score,
    this.tossWinner,
    this.tossDecision,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return MatchModel(
      id: docId ?? json['id'],
      team1: json['team1'] ?? '',
      team2: json['team2'] ?? '',
      venue: json['venue'] ?? '',
      status: json['status'] ?? 'upcoming',
      battingTeam: json['battingTeam'],
      currentScore: json['currentScore'],
      currentWickets: json['currentWickets'],
      currentOvers: json['currentOvers'],
      currentInnings: json['currentInnings'],
      firstInningsScore: json['firstInningsScore'],
      overs: json['overs'] ?? 0,
      date: _parseDate(json['date']),  // Use helper method to parse date
      time: json['time'],
      createdBy: json['createdBy'],
      team1Players: (json['team1Players'] as List<dynamic>?)
          ?.map((p) => PlayerModel.fromJson(p))
          .toList(),
      team2Players: (json['team2Players'] as List<dynamic>?)
          ?.map((p) => PlayerModel.fromJson(p))
          .toList(),
      selectedTeam1Players: (json['selectedTeam1Players'] as List<dynamic>?)
          ?.map((p) => PlayerModel.fromJson(p))
          .toList(),
      selectedTeam2Players: (json['selectedTeam2Players'] as List<dynamic>?)
          ?.map((p) => PlayerModel.fromJson(p))
          .toList(),
      score: json['score'] as Map<String, dynamic>?,
      tossWinner: json['tossWinner'],
      tossDecision: json['tossDecision'],
    );
  }

  // Helper method to parse date from different formats
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    
    if (date is Timestamp) {
      return date.toDate();
    }
    
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        print('Error parsing date string: $date');
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'team1': team1,
    'team2': team2,
    'venue': venue,
    'status': status,
    'battingTeam': battingTeam,
    'currentScore': currentScore,
    'currentWickets': currentWickets,
    'currentOvers': currentOvers,
    'currentInnings': currentInnings,
    'firstInningsScore': firstInningsScore,
    'overs': overs,
    'date': date,
    'time': time,
    'createdBy': createdBy,
    'team1Players': team1Players?.map((p) => p.toJson()).toList(),
    'team2Players': team2Players?.map((p) => p.toJson()).toList(),
    'selectedTeam1Players': selectedTeam1Players?.map((p) => p.toJson()).toList(),
    'selectedTeam2Players': selectedTeam2Players?.map((p) => p.toJson()).toList(),
    'score': score,
    'tossWinner': tossWinner,
    'tossDecision': tossDecision,
  };
}
