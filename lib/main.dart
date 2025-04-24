import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/wrapper.dart';
import 'models/user_model.dart';
import 'firebase_options.dart';
import 'screens/match_list_screen.dart';
import 'screens/new_match_screen.dart';
import 'screens/match_details_screen.dart';
import 'models/match_model.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/match_scoring_screen.dart';
import 'screens/match_toss_screen.dart';
import 'screens/team_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controllers/match_controller.dart';
import 'services/match_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      MultiProvider(
        providers: [
          StreamProvider<UserModel?>.value(
            value: AuthService().user,
            initialData: null,
            catchError: (_, __) => null,
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MatchController(
            matchService: MatchService(),
          ),
        ),
        StreamProvider<UserModel?>.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, __) => null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cricket Scoring App',
        theme: ThemeData(
          primaryColor: Colors.blue[900],
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue[900] ?? Colors.blue,
            primary: Colors.blue[900] ?? Colors.blue,
            secondary: Colors.blue[600] ?? Colors.blue,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => AuthWrapper(),
          '/login': (context) => LoginScreen(
            toggleView: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          '/home': (context) => HomeScreen(),
          '/matches': (context) => MatchListScreen(),
          '/new-match': (context) => NewMatchScreen(),
        },
        onGenerateRoute: (settings) {
          final args = settings.arguments;

          switch (settings.name) {
            case '/match-details':
              if (args is MatchModel) {
                return MaterialPageRoute(
                  builder: (_) => MatchDetailsScreen(match: args),
                );
              }
              break;

            case '/match-toss':
              if (args is MatchModel) {
                return MaterialPageRoute(
                  builder: (_) => MatchTossScreen(match: args),
                );
              }
              break;

            case '/team-selection':
              if (args is Map<String, dynamic>) {
                return MaterialPageRoute(
                  builder: (_) => TeamSelectionScreen(
                    match: args['match'],
                  ),
                );
              }
              break;

            case '/match-scoring':
              if (args is MatchModel) {
                return MaterialPageRoute(
                  builder: (_) => MatchScoringScreen(
                    match: args,
                  ),
                );
              }
              break;
          }

          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Route not found')),
            ),
          );
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Page not found')),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen();
        }

        return LoginScreen(
          toggleView: () => Navigator.pushReplacementNamed(context, '/home'),
        );
      },
    );
  }
}
