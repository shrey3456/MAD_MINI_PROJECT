import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/ball_model.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add caching for better performance
  Map<String, List<BallModel>> _ballsCache = {};
  Map<String, Map<String, dynamic>> _matchSummaryCache = {};

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<void> createMatch(MatchModel match, String userId) async {
    try {
      print('Creating match with userId: $userId');
      
      final matchData = {
        ...match.toJson(),
        'createdBy': userId,  // Make sure this is the correct user ID
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('Match data to save: $matchData');
      
      // Verify the user ID before saving
      if (userId != await getCurrentUserId()) {
        print('Warning: Creating match with different userId than current user');
      }
      
      final docRef = await _firestore
          .collection('matches')
          .add(matchData);
      
      print('Match created with ID: ${docRef.id}');
    } catch (e) {
      print('Error creating match: $e');
      rethrow;
    }
  }

  Stream<List<MatchModel>> getAllMatches() {
    return _firestore
        .collection('matches')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MatchModel>> getMatchesByStatus(String status) {
    return _firestore
        .collection('matches')
        .where('status', isEqualTo: status)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<MatchModel?> getMatchStream(String matchId) {
    try {
      return _firestore
          .collection('matches')
          .doc(matchId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return MatchModel.fromJson(doc.data()!, doc.id);
          });
    } catch (e) {
      print('Error getting match stream: $e');
      return Stream.value(null);
    }
  }

  Future<void> updateMatch(String matchId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating match: $e');
      rethrow;
    }
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    try {
      await _firestore
          .collection('matches')
          .doc(matchId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Error updating match status: $e');
      rethrow;
    }
  }

  Future<List<MatchModel>> getUserCreatedMatches() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('matches')
          .where('createdBy', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MatchModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user matches: $e');
      return [];
    }
  }

  Future<void> deleteMatch(String matchId) async {
    try {
      final userId = await getCurrentUserId();
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();
      
      if (matchDoc.data()?['createdBy'] != userId) {
        throw Exception('Unauthorized to delete this match');
      }
      
      await _firestore.collection('matches').doc(matchId).delete();
    } catch (e) {
      print('Error deleting match: $e');
      rethrow;
    }
  }

  Stream<List<MatchModel>> searchMatches({
    String? team,
    String? venue,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('matches');

    if (team != null) {
      // Change to check both team1 and team2
      query = query.where(Filter.or(
        Filter('team1', isEqualTo: team),
        Filter('team2', isEqualTo: team),
      ));
    }
    if (venue != null) {
      query = query.where('venue', isEqualTo: venue);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (startDate != null) {
      query = query.where('date', 
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', 
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MatchModel>> getUserMatches(String userId) {
    print('Fetching matches for userId: $userId'); // Debug log

    return _firestore
        .collection('matches')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('Found ${snapshot.docs.length} matches'); // Debug log
          
          return snapshot.docs
              .map((doc) => MatchModel.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<MatchModel>> getUserMatchesByStatus(String userId, String status) {
    return _firestore
        .collection('matches')
        .where('createdBy', isEqualTo: userId)  // Change to match your user ID field
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          final matches = snapshot.docs
              .map((doc) => MatchModel.fromJson(doc.data(), doc.id))
              .toList();
          
          // Sort matches by date
          matches.sort((a, b) {
            if (status == 'completed') {
              return b.date.compareTo(a.date); // Recent first
            }
            return a.date.compareTo(b.date); // Upcoming first
          });
          
          return matches;
        });
  }

  Future<String?> fetchCurrentUserId() async {
    try {
      final user = _auth.currentUser;
      return user?.uid;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<String?> fetchCurrentUserIdAsync() async {
    try {
      final user = _auth.currentUser;
      return user?.uid;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<void> addBall(BallModel ball) async {
    try {
      await _db
          .collection('matches')
          .doc(ball.matchId)
          .collection('balls')
          .add(ball.toJson());
    } catch (e) {
      print('Error adding ball: $e');
      throw e;
    }
  }

  Future<void> updateScore(String matchId, Map<String, dynamic> scoreUpdate) async {
    try {
      await _firestore
          .collection('matches')
          .doc(matchId)
          .update(scoreUpdate);
    } catch (e) {
      print('Error updating score: $e');
      rethrow;
    }
  }

  // Optimize balls stream with caching and pagination
  Stream<List<BallModel>> getBallsStream(String matchId, int innings) {
    if (_ballsCache.containsKey('${matchId}_$innings')) {
      // Return cached data first
      return Stream.value(_ballsCache['${matchId}_${innings}']!).timeout(
        const Duration(seconds: 1),
        onTimeout: (EventSink<List<BallModel>> sink) {
          _fetchBallsFromFirestore(matchId, innings).listen(
            (data) => sink.add(data),
            onError: (error) => sink.addError(error),
            onDone: () => sink.close(),
          );
        },
      );
    }

    return _fetchBallsFromFirestore(matchId, innings);
  }

  Stream<List<BallModel>> _fetchBallsFromFirestore(String matchId, int innings) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('balls')
        .where('innings', isEqualTo: innings)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit query size for better performance
        .snapshots()
        .map((snapshot) {
          final balls = snapshot.docs
              .map((doc) => BallModel.fromJson(doc.data(), doc.id))
              .toList();
          _ballsCache['${matchId}_${innings}'] = balls; // Cache the results
          return balls;
        });
  }

  Stream<List<BallModel>> getBalls(String matchId) {
    try {
      return FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('balls')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => BallModel.fromJson(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error getting balls: $e');
      return Stream.value([]);
    }
  }

  // Update match after toss
  Future<void> updateMatchToss(String matchId, String tossWinner, String decision) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'tossWinner': tossWinner,
        'tossDecision': decision,
        'status': 'toss_completed',
      });
    } catch (e) {
      print('Error updating toss: $e');
      throw Exception('Failed to update toss details');
    }
  }

  // Update playing XI
  Future<void> updatePlayingXI(String matchId, List<PlayerModel> team1Players, List<PlayerModel> team2Players) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'team1Players': team1Players.map((p) => p.toJson()).toList(),
        'team2Players': team2Players.map((p) => p.toJson()).toList(),
        'status': 'teams_selected',
      });
    } catch (e) {
      print('Error updating playing XI: $e');
      throw Exception('Failed to update team selections');
    }
  }

  // Update match summary after each ball
  Future<void> _updateMatchSummary(BallModel ball) async {
    try {
      final matchRef = _firestore.collection('matches').doc(ball.matchId);
      
      await _firestore.runTransaction((transaction) async {
        final matchDoc = await transaction.get(matchRef);
        final currentScore = matchDoc.data()?['score'] ?? {};
        
        final inningsKey = 'innings${ball.innings}';
        if (!currentScore.containsKey(inningsKey)) {
          currentScore[inningsKey] = {
            'runs': 0,
            'wickets': 0,
            'overs': 0.0,
            'extras': {
              'wides': 0,
              'noBalls': 0,
              'byes': 0,
              'legByes': 0,
            }
          };
        }

        // Update runs and extras
        currentScore[inningsKey]['runs'] += ball.runs + ball.extraRuns;
        if (ball.wicketType != null) {
          currentScore[inningsKey]['wickets']++;
        }
        if (ball.extraType != null) {
          switch (ball.extraType) {
            case 'wide':
              currentScore[inningsKey]['extras']['wides']++;
              break;
            case 'no_ball':
              currentScore[inningsKey]['extras']['noBalls']++;
              break;
            case 'byes':
              currentScore[inningsKey]['extras']['byes'] += ball.runs;
              break;
            case 'leg_byes':
              currentScore[inningsKey]['extras']['legByes'] += ball.runs;
              break;
          }
        }

        // Update overs
        if (ball.extraType == null || ball.extraType == 'byes' || ball.extraType == 'leg_byes') {
          final currentOvers = currentScore[inningsKey]['overs'];
          final ballsInOver = ((currentOvers % 1) * 10).round();
          if (ballsInOver == 5) {
            currentScore[inningsKey]['overs'] = currentOvers.floor() + 1.0;
          } else {
            currentScore[inningsKey]['overs'] = currentOvers.floor() + ((ballsInOver + 1) / 10);
          }
        }

        transaction.update(matchRef, {'score': currentScore});
      });
    } catch (e) {
      print('Error updating match summary: $e');
      throw Exception('Failed to update match summary');
    }
  }

  Future<void> updatePlayerStats({
    required String matchId,
    required String playerId,
    required Map<String, dynamic> stats,
  }) async {
    try {
      await _db
          .collection('matches')
          .doc(matchId)
          .collection('players')
          .doc(playerId)
          .set({
        'stats': stats,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating player stats: $e');
      throw e;
    }
  }

  Future<void> updateMatchSummary({
    required String matchId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db
          .collection('matches')
          .doc(matchId)
          .set({
        'summary': data,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating match summary: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getMatchSummary(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    return doc.data()?['summary'] ?? {};
  }

  Future<List<BallModel>> getCurrentOverBalls(String matchId, int over) async {
    final snapshot = await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('balls')
        .where('over', isEqualTo: over)
        .orderBy('ball')
        .get();

    return snapshot.docs
        .map((doc) => BallModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<PlayerStats>> getPlayerStats(String matchId) async {
    final snapshot = await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('players')
        .get();

    return snapshot.docs
        .map((doc) => PlayerStats(
              playerId: doc.id,
              stats: doc.data()['stats'] ?? {},
            ))
        .toList();
  }

  Future<void> removeBall(String matchId, String ballId) async {
    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('balls')
          .doc(ballId)
          .delete();
    } catch (e) {
      print('Error removing ball: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getMatchState(String matchId) async {
    try {
      final doc = await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('state')
          .doc('current')
          .get();
          
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting match state: $e');
      return null;
    }
  }

  Future<void> updateMatchState(String matchId, Map<String, dynamic> state) async {
    try {
      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('state')
          .doc('current')
          .set(state, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating match state: $e');
    }
  }
}

class PlayerStats {
  final String playerId;
  final Map<String, dynamic> stats;

  PlayerStats({required this.playerId, required this.stats});
}