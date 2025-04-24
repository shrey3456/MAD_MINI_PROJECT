import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<UserModel?> get userStream => user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '1085363878255-k8lfu8ovush4t9u1mu6i31tbl0aeotab.apps.googleusercontent.com'
        : null,
    scopes: [
      'email',
      'profile',
    ],
  );

  // Create user object based on FirebaseUser
  UserModel? _userFromFirebaseUser(User? user) {
    return user != null
        ? UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
          )
        : null;
  }

  // Auth change user stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        print('Auth stream: No user'); // Debug log
        return null;
      }
      print('Auth stream: User ${firebaseUser.uid}'); // Debug log
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
      );
    });
  }

  // Create a new document for the user in Firestore
  Future<void> _createUserDocument(User user, String? name) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': name ?? user.displayName,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignInTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
      // Handle the error but don't throw it to prevent registration failure
    }
  }

  // Register with email & password
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await _createUserDocument(user, name);
        return _userFromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Sign in with email & password
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Updated Google Sign In method
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;
      
      if (kIsWeb) {
        // Web specific sign in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // Add scope to the provider
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Specify custom parameters
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile specific sign in
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? user = userCredential.user;
      if (user != null) {
        // Create or update user document
        await _createUserDocument(user, user.displayName);
        return _userFromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Updated sign out method
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Failed to sign out');
    }
  }
}
