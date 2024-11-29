import 'dart:async';

import 'package:chatt_app/screens/generation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bishop/bishop.dart' as bishop;
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Game extends StatefulWidget {
  const Game({super.key, required this.gameId});
  final String gameId;
  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  late bishop.Game game;
  late SquaresState state;
  int player = Squares.white;
  bool flipBoard = false;
  Map<String, dynamic>? lobbyData;
  late StreamSubscription<DocumentSnapshot> _lobbyStream;
  final user = FirebaseAuth.instance.currentUser!;
  late BoardState currentBoard;
  bool isListenerCancelled = false;

  @override
  void initState() {
    _resetGame(false);
    super.initState();
    _initializeLobby();
  }

  Future<void> _initializeLobby() async {
    //
    final lobbyRef =
        FirebaseFirestore.instance.collection('lobbys').doc(widget.gameId);
    _lobbyStream = lobbyRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          lobbyData = snapshot.data();
          //for player 1
          if (lobbyData!['player1'] == user.uid) {
            if (lobbyData!['player1_color'] == 'white') {
              print('player 1 got white color');
              player = Squares.white;

              _resetGame(false);
            } else {
              player = Squares.black;
              print('player 1 got black color');
              _resetGame(false);
            }
          }
          //for player 2
          if (lobbyData!['player2'] == user.uid) {
            if (lobbyData!['player1_color'] == 'white') {
              player = Squares.black;
              print('player 2 got black color');
              _resetGame(false);
            } else {
              player = Squares.white;
              print('player 2 got white color');
              _resetGame(false);
            }
          }
          if (lobbyData!['username2'] != "Waiting for player") {
            print("subscription got cancelled");
            _lobbyStream.cancel();
            _initializeGameUpdates();
          }
          ;
        });
      }
    });
  }

  Future<void> _initializeGameUpdates() async {
    print("we now listening to game updates");
    final gameRef =
        FirebaseFirestore.instance.collection('lobbys').doc(widget.gameId);
    gameRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          lobbyData = snapshot.data();
          _getGameFromFirestore();
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _resetGame([bool ss = true]) {
    game = bishop.Game(variant: bishop.Variant.standard());
    state = game.squaresState(player);
    print("Board got reseted");
    if (ss) setState(() {});
  }

  void _onMove(Move move) async {
    print("onMove tiggered");
    bool result = game.makeSquaresMove(move);
    print(result);
    print("move details");
    print(move.from);
    print(move.to);
    print(move.piece);
    if (result) {
      setState(() {
        state = game.squaresState(player);
        print(state);
      });
      currentBoard = state.board;
      _updateGameStateInFirestore();
    }
  }

  _updateGameStateInFirestore() async {
    final lobbyRef =
        FirebaseFirestore.instance.collection('lobbys').doc(widget.gameId);

    Map<String, dynamic> boardData = {
      'board': currentBoard.board,
      'turn': currentBoard.turn,
      // 'orientation': currentBoard.orientation,
      // 'lastFrom': currentBoard.lastFrom,
      // 'lastTo': currentBoard.lastTo,
      // 'checkSquare': currentBoard.checkSquare,
    };
    print('Updating Firestore with turn: ${currentBoard.turn}');
    await lobbyRef.update({
      'gameState': boardData,
    });
  }

  Future<void> _getGameFromFirestore() async {
    Map<String, dynamic> boardData = lobbyData!['gameState'];
    if (boardData['turn'] == player) {
      BoardState newBoard = BoardState(
        board: List<String>.from(boardData['board']),
        turn: boardData['turn'],
        //orientation: boardData['orientation'],
        //lastFrom: boardData['lastFrom'],
        //lastTo: boardData['lastTo'],
        //checkSquare: boardData['checkSquare'],
      );
      //moving = bishop.GameMove(from: );
      setState(() {
        print('Opponent moved, updating board');
        _resetGame(false);
        state = state.copyWith(board: newBoard, state: PlayState.ourTurn,orientation: 1);
        
        print(state.moves);
        print('Board updated for Black: $newBoard');
        print('Who turn it is:');
        print(newBoard.turn==1?"black":"White");
      });
    }
  }

  Future<void> _exitGame() async {
    final lobbyRef =
        FirebaseFirestore.instance.collection('lobbys').doc(widget.gameId);
    //if player 2 leaves, lobby stays open
    if (lobbyData!['player2'] == user.uid) {
      await lobbyRef.update({
        'status': "waiting",
        'player2': "unknown",
        'username2': "Waiting for player",
      });
    } else {
      await lobbyRef.delete();
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (lobbyData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: AppBar(
          title: const Text('Loading...'), // Placeholder title
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(), // Loading spinner
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(lobbyData!['name']),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _exitGame();
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(lobbyData!['player2'] == user.uid
                    ? lobbyData!['username1']
                    : lobbyData!['username2']),
                trailing: Text(lobbyData!['time']),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BoardController(
                state: flipBoard ? state.board.flipped() : state.board,
                playState: state.state,
                pieceSet: PieceSet.merida(),
                theme: BoardTheme.blueGrey,
                moves: state.moves,
                onMove: _onMove,
                onPremove: _onMove,
                markerTheme: MarkerTheme(
                  empty: MarkerTheme.dot,
                  piece: MarkerTheme.corners(),
                ),
                promotionBehaviour: PromotionBehaviour.autoPremove,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(lobbyData!['player2'] == user.uid
                    ? lobbyData!['username2']
                    : lobbyData!['username1']),
                trailing: Text(lobbyData!['time']),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GenerateScreen()),
                );
              },
              label: const Text('Generate board'),
              icon: const Icon(Icons.threed_rotation_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

  //_flipBoard() => setState(() => flipBoard = !flipBoard);

  //this worked for playing with computer
  // void _onMove(Move move) async {
  //   bool result = game.makeSquaresMove(move);
  //   if (result) {
  //     setState(() {
  //       state = game.squaresState(player);
  //       print(state);
  //     });
  //   }
  //   // if (state.state == PlayState.theirTurn) {
  //   //   game.makeRandomMove();
  //   //   setState(() {
  //   //     state = game.squaresState(player);
  //   //   });
  //   // }
  // }