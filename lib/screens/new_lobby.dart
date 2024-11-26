import 'package:chatt_app/models/lobby.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatt_app/screens/game.dart';

class NewLobby extends StatefulWidget {
  const NewLobby({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _NewLobbyState();
  }
}

class _NewLobbyState extends State<NewLobby> {
  final _nameController = TextEditingController(text: "test1");
  Duration? _selectedDuration = const Duration(minutes: 5);
  Category _selectedCategory = Category.white;

  void _presentDurationPicker() async {
    final pickedDuration = await showDurationPicker(
      context: context,
      initialTime: const Duration(minutes: 5),
      baseUnit: BaseUnit.minute,
      upperBound: const Duration(minutes: 30),
      lowerBound: const Duration(minutes: 1),
    );
    setState(() {
      _selectedDuration = pickedDuration;
    });
  }

  String _formatDuration(String duration) {
    final durationParts = duration.split(':');
    final minutes = int.parse(durationParts[1]);
    final seconds = int.parse(durationParts[2].split('.')[0]);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatCategory(String category) {
    final categoryParts = category.split('.');
    return categoryParts[1];
  }

  void _submitLobbyData() async {
    if (_nameController.text.trim().isEmpty || _selectedDuration == null) {
      //show error
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invaild input'),
          content: const Text('Please make sure given values are correct'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('Okay'))
          ],
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final lobbyDoc = await FirebaseFirestore.instance.collection('lobbys').add({
      'gameState': {},
      'name': _nameController.text,
      'time': _formatDuration(_selectedDuration.toString()),
      'player1_color': _formatCategory(_selectedCategory.toString()),
      'player1': user.uid,
      'player2': 'unknown',
      'username2': 'Waiting for player',
      'username1': userData.data()!['username'],
      'status': 'waiting',
    });

    final lobbyId = lobbyDoc.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Game(
          gameId: lobbyId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // implement dispose
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Start a game'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    maxLength: 25,
                    decoration: const InputDecoration(
                      label: Text('Name of the lobby'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Align(
                    alignment: Alignment
                        .centerLeft, // Aligns the text to the left within its parent
                    child: Text('Select color:'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton(
                            value: _selectedCategory,
                            items: Category.values
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category.name.toUpperCase(),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedCategory = value;
                              });
                            }),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(_selectedDuration == null
                                ? 'Select time'
                                : _formatDuration(
                                    _selectedDuration.toString())),
                            IconButton(
                              onPressed: _presentDurationPicker,
                              icon: const Icon(
                                Icons.timer,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _submitLobbyData();
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
