import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../widgets/custom_dialogs.dart';
import 'new_match_screen.dart';
import 'match_list_screen.dart';
import 'match_history_screen.dart';
import 'user_matches_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();
  final MatchService _matchService = MatchService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel?>(
      builder: (context, user, _) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, user),
          body: _buildBody(context, user),
        );
      },
    );
  }

  String _getDisplayName(UserModel user) {
    if (user.displayName.isNotEmpty) {
      return user.displayName;
    }
    // Extract username part before @ from email
    return user.email.split('@')[0];
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel user) {
    final displayName = _getDisplayName(user);
    
    return AppBar(
      backgroundColor: Colors.blue[900],
      elevation: 0,
      title: Text(
        'Welcome, $displayName', // Removed @ symbol
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              displayName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onPressed: () => _showProfileDialog(context, user),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, UserModel user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[900]!, Colors.blue[400]!],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeCard(user),
                const SizedBox(height: 24),
                _buildMenuGrid(context, user),
                const SizedBox(height: 24),
                _buildLiveMatchesCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showProfileDialog(BuildContext context, UserModel user) {
    final displayName = _getDisplayName(user);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[900],
              child: Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName, // Removed @ symbol
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showLogoutConfirmDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWelcomeCard(UserModel user) {
    final displayName = _getDisplayName(user);
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.sports_cricket,
              size: 48,
              color: Colors.blue[900],
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome $displayName', // Removed @ symbol
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scoring your cricket matches',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, UserModel user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMenuCard(
          icon: Icons.add_box,
          title: 'Create Match',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewMatchScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.sports_cricket_rounded,
          title: 'View Matches',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchListScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.history,
          title: 'Match History',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchHistoryScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.person_outline,
          title: 'My Matches',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserMatchesScreen(
                  userId: user.uid,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveMatchesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Matches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildMatchesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.blue[900],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return StreamBuilder<List<MatchModel>>(
      stream: _matchService.getMatchesByStatus('live'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final liveMatches = snapshot.data!;

        if (liveMatches.isEmpty) {
          return Center(
            child: Text(
              'No live matches at the moment',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: liveMatches.length,
          itemBuilder: (context, index) {
            final match = liveMatches[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.sports_cricket,
                  color: Colors.blue[900],
                ),
                title: Text(
                  '${match.team1} vs ${match.team2}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Overs: ${match.overs}'),
                trailing: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/match-details',
                    arguments: match,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLogoutConfirmDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to logout. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}