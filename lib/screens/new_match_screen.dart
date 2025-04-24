import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../services/match_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum PlayerRole { batsman, bowler, allRounder }
enum BattingStyle { rightHanded, leftHanded }
enum BowlingStyle { fastPacer, mediumFastPacer, mediumPacer, offSpinner, legSpinner, leftArmSpinner }
enum BowlingArm { rightArm, leftArm }

class NewMatchScreen extends StatefulWidget {
  @override
  _NewMatchScreenState createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matchService = MatchService();
  final _auth = FirebaseAuth.instance;
  
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _venueController = TextEditingController();
  final _oversController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  List<PlayerModel> team1Players = [];
  List<PlayerModel> team2Players = [];
  
  int _currentStep = 0;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Match'),
        backgroundColor: Colors.blue[900],
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 1 && team1Players.length != 15) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Team 1 must have exactly 15 players'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          if (_currentStep == 2 && team2Players.length != 15) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Team 2 must have exactly 15 players'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _submitMatch();
          }
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              ElevatedButton(
                onPressed: _isProcessing ? null : details.onStepContinue,
                child: _isProcessing && _currentStep == 2
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_currentStep == 2 ? 'Create Match' : 'Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              if (_currentStep > 0)
                TextButton(
                  onPressed: _isProcessing ? null : details.onStepCancel,
                  child: Text('Back'),
                ),
            ],
          );
        },
        steps: [
          Step(
            title: Text('Match Details'),
            content: _buildMatchDetailsForm(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: Text('Team 1 Players'),
            content: _buildPlayersForm(true),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: Text('Team 2 Players'),
            content: _buildPlayersForm(false),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _team1Controller,
            decoration: InputDecoration(
              labelText: 'Team 1 Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _team2Controller,
            decoration: InputDecoration(
              labelText: 'Team 2 Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _venueController,
            decoration: InputDecoration(
              labelText: 'Venue',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _oversController,
            decoration: InputDecoration(
              labelText: 'Number of Overs',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 16),
          ListTile(
            title: Text('Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            trailing: Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          ListTile(
            title: Text('Time: ${_selectedTime.format(context)}'),
            trailing: Icon(Icons.access_time),
            onTap: () => _selectTime(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersForm(bool isTeam1) {
    List<PlayerModel> players = isTeam1 ? team1Players : team2Players;
    String teamName = isTeam1 ? _team1Controller.text : _team2Controller.text;

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '$teamName Players (${players.length}/15)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  if (players.length < 15)
                    ElevatedButton.icon(
                      onPressed: () => _showAddPlayerDialog(isTeam1, players),
                      icon: Icon(Icons.add),
                      label: Text('Add Player (${15 - players.length} remaining)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          if (players.isEmpty)
            Center(
              child: Text(
                'Add 15 players to continue',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Column(
              children: players.map((player) => Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[900],
                    child: Text(
                      player.jerseyNumber.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${player.role.toString().split('.').last} • ${player.battingStyle.toString().split('.').last}',
                      ),
                      if (player.bowlingStyle != null)
                        Text(
                          '${player.bowlingArm?.toString().split('.').last ?? ''} ${_formatBowlingStyle(BowlingStyle.values.firstWhere((e) => e.toString().split('.').last == player.bowlingStyle))}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (player.isCaptain)
                        Tooltip(
                          message: 'Captain',
                          child: Icon(Icons.stars, color: Colors.amber, size: 20),
                        ),
                      if (player.isViceCaptain)
                        Tooltip(
                          message: 'Vice Captain',
                          child: Icon(Icons.star_half, color: Colors.amber, size: 20),
                        ),
                      if (player.isWicketKeeper)
                        Tooltip(
                          message: 'Wicket Keeper',
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.sports_cricket, color: Colors.grey, size: 20),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            if (isTeam1) {
                              team1Players.removeAt(players.indexOf(player));
                            } else {
                              team2Players.removeAt(players.indexOf(player));
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value),
      ],
    );
  }

  Future<void> _showAddPlayerDialog(bool isTeam1, List<PlayerModel> players) async {
    final nameController = TextEditingController();
    final jerseyController = TextEditingController();
    
    PlayerRole selectedRole = PlayerRole.batsman;
    BattingStyle selectedBattingStyle = BattingStyle.rightHanded;
    BowlingStyle? selectedBowlingStyle;
    BowlingArm? selectedBowlingArm;
    bool isCaptain = false;
    bool isViceCaptain = false;
    bool isWicketKeeper = false;

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: jerseyController,
                  decoration: InputDecoration(
                    labelText: 'Jersey Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<PlayerRole>(
                  decoration: InputDecoration(
                    labelText: 'Player Role',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedRole,
                  items: PlayerRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                      if (value == PlayerRole.batsman) {
                        selectedBowlingStyle = null;
                      }
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<BattingStyle>(
                  decoration: InputDecoration(
                    labelText: 'Batting Style',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedBattingStyle,
                  items: BattingStyle.values.map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Text(style.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedBattingStyle = value!);
                  },
                ),
                SizedBox(height: 16),
                if (selectedRole != PlayerRole.batsman) Column(
                  children: [
                    DropdownButtonFormField<BowlingArm>(
                      decoration: InputDecoration(
                        labelText: 'Bowling Arm',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_cricket),
                      ),
                      value: selectedBowlingArm,
                      items: BowlingArm.values.map((arm) {
                        return DropdownMenuItem(
                          value: arm,
                          child: Text('${arm.toString().split('.').last} Arm'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedBowlingArm = value);
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<BowlingStyle>(
                      decoration: InputDecoration(
                        labelText: 'Bowling Style',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_cricket),
                      ),
                      value: selectedBowlingStyle,
                      items: BowlingStyle.values.map((style) {
                        String displayName = style.toString().split('.').last;
                        // Format the display name
                        switch (style) {
                          case BowlingStyle.fastPacer:
                            displayName = "Fast";
                            break;
                          case BowlingStyle.mediumFastPacer:
                            displayName = "Medium Fast";
                            break;
                          case BowlingStyle.mediumPacer:
                            displayName = "Medium";
                            break;
                          case BowlingStyle.offSpinner:
                            displayName = "Off Spin";
                            break;
                          case BowlingStyle.legSpinner:
                            displayName = "Leg Spin";
                            break;
                          case BowlingStyle.leftArmSpinner:
                            displayName = "Left Arm Spin";
                            break;
                        }
                        return DropdownMenuItem(
                          value: style,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedBowlingStyle = value);
                      },
                    ),
                  ],
                ),
                Divider(height: 24),
                Text(
                  'Special Roles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                CheckboxListTile(
                  title: Text('Captain'),
                  value: isCaptain,
                  onChanged: (value) {
                    setDialogState(() {
                      isCaptain = value!;
                      if (value) {
                        isViceCaptain = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('Vice Captain'),
                  value: isViceCaptain,
                  onChanged: (value) {
                    setDialogState(() {
                      isViceCaptain = value!;
                      if (value) {
                        isCaptain = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('Wicket Keeper'),
                  value: isWicketKeeper,
                  onChanged: (value) {
                    setDialogState(() => isWicketKeeper = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    jerseyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                // Validate that team doesn't already have a captain/vice-captain
                if (isCaptain && players.any((p) => p.isCaptain)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Team already has a captain')),
                  );
                  return;
                }
                if (isViceCaptain && players.any((p) => p.isViceCaptain)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Team already has a vice captain')),
                  );
                  return;
                }

                final player = PlayerModel(
                  id: UniqueKey().toString(), // Generate a unique ID
                  name: nameController.text,
                  jerseyNumber: int.tryParse(jerseyController.text) ?? 0,
                  role: selectedRole.toString().split('.').last,
                  battingStyle: selectedBattingStyle.toString().split('.').last,
                  bowlingStyle: selectedRole != PlayerRole.batsman ? selectedBowlingStyle?.toString().split('.').last : null,
                  bowlingArm: selectedRole != PlayerRole.batsman ? selectedBowlingArm?.toString().split('.').last : null,
                  isCaptain: isCaptain,
                  isViceCaptain: isViceCaptain,
                  isWicketKeeper: isWicketKeeper,
                );

                setState(() {
                  if (isTeam1) {
                    team1Players.add(player);
                  } else {
                    team2Players.add(player);
                  }
                });

                Navigator.pop(dialogContext);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submitMatch() async {
    if (!mounted) return;

    if (_formKey.currentState?.validate() ?? false) {
      if (team1Players.length != 15 || team2Players.length != 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Each team must have exactly 15 players'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        setState(() => _isProcessing = true);

        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        final match = MatchModel(
          team1: _team1Controller.text,
          team2: _team2Controller.text,
          venue: _venueController.text,
          overs: int.parse(_oversController.text),
          date: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          ),
          time: _selectedTime.format(context), // Add the time parameter
          team1Players: team1Players,
          team2Players: team2Players,
          status: 'upcoming',
          createdBy: userId,
        );

        await _matchService.createMatch(match, userId);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        print('Error creating match: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating match: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _venueController.dispose();
    _oversController.dispose();
    super.dispose();
  }

  String _formatBowlingStyle(BowlingStyle style) {
    switch (style) {
      case BowlingStyle.fastPacer:
        return "Fast";
      case BowlingStyle.mediumFastPacer:
        return "Medium Fast";
      case BowlingStyle.mediumPacer:
        return "Medium";
      case BowlingStyle.offSpinner:
        return "Off Spin";
      case BowlingStyle.legSpinner:
        return "Leg Spin";
      case BowlingStyle.leftArmSpinner:
        return "Left Arm Spin";
      default:
        return style.toString().split('.').last;
    }
  }
}