import 'package:chatt_app/screens/game.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LobbyList extends StatelessWidget {
  const LobbyList({super.key});

   Future<void> _joinLobby(BuildContext context, String lobbyId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final lobbyDoc = FirebaseFirestore.instance.collection('lobbys').doc(lobbyId);
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    await lobbyDoc.update({
      'player2': user.uid,
      'username2': userData.data()!['username'],
      //change that when done debug
      //'status': 'in-progress'
      'status': 'waiting',
    });

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Join the game'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lobbys').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred!'));
          }

          final lobbies = snapshot.data?.docs ?? [];

          if (lobbies.isEmpty) {
            return const Center(child: Text('No lobbies available.'));
          }

          return ListView.builder(
            itemCount: lobbies.length,
            itemBuilder: (ctx, index) {
              final lobbyData = lobbies[index].data() as Map<String, dynamic>;
              final lobbyId = lobbies[index].id;
              final lobbyName = lobbyData['name'];
              final lobbyTime = lobbyData['time'];
              final lobbyUsername = lobbyData['username1'];
              final lobbyCategory = lobbyData['player1_color'];
              final lobbyStatus = lobbyData['status'];

              return Card(
                child: ListTile(
                  leading: Image.asset('assets/images/chess2.png'),
                  trailing: lobbyStatus != 'in-progress'
                        ? Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ) :const Text('Playing'),
                  title: Text(lobbyName),
                  onTap: lobbyStatus == 'in-progress'
                      ? null
                      : () {
                          _joinLobby(context, lobbyId);
                        },
                  hoverColor:Colors.green,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('$lobbyUsername\'s game'),
                      Text('Time: $lobbyTime'),
                      Text(lobbyCategory),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
