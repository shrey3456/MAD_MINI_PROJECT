import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.user,
      builder: (context, AsyncSnapshot<UserModel?> snapshot) {
        print('Auth state changed: ${snapshot.data}'); // Debug log

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Auth error: ${snapshot.error}'); // Debug log
          return Scaffold(
            body: Center(
              child: Text('Authentication Error: ${snapshot.error}'),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          print('User authenticated: ${user.uid}'); // Debug log
          return HomeScreen();
        }

        print('No authenticated user'); // Debug log
        return LoginScreen(toggleView: () {
          // Add logic to toggle between login and register screens
        });
      },
    );
  }
}