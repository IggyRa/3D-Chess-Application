import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:bishop/bishop.dart' as bishop;
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late bishop.Game game;
  late SquaresState state;
  int player = Squares.white;
  late BoardState currentBoard;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  void _resetGame() {
    game = bishop.Game();
    state = game.squaresState(player);
  }

  group('Chess Game Tests', () {
    group('Game State Tests', () {
      test('Initial Board Setup', () {
        _resetGame();
        currentBoard = state.board;
        expect(currentBoard.board, equals([
        'r', 'n', 'b', 'q', 'k', 'b', 'n', 'r',
        'p', 'p', 'p', 'p', 'p', 'p', 'p', 'p',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P',
        'R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R',]));
      });

      test('Valid Move Processing', () {
        _resetGame();
        final move = Move(from: 52, to: 36); // e2-e4
        bool result = game.makeSquaresMove(move);
        
        expect(result, isTrue);
      });

      test('Invalid Move Detection', () {
        _resetGame();
        final move = Move(from: 52, to: 20); //invalid pawn move
        bool result = game.makeSquaresMove(move);
        
        expect(result, isFalse);
      });

      test('Check detection', () {
        game = bishop.Game(fen: "rnbqkbnr/ppppp1pp/8/5p2/4P3/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 2");
        state = game.squaresState(player);
        final move = Move(from: 59, to: 31); // queen moves d1-h5
        bool result = game.makeSquaresMove(move);
        state = game.squaresState(player);
        currentBoard = state.board;
        
        expect(result, isTrue);
        //result should not be null bcs king is in check
        expect(currentBoard.checkSquare, isNot(equals(null)));
      });

      test('Checkmate detection', () {
        game = bishop.Game(fen: "rnbqkbnr/ppppp2p/8/5pp1/4P3/7Q/PPPP1PPP/RNB1KBNR w KQkq - 0 4");
        state = game.squaresState(player);
        final move = Move(from: 47, to: 31); // queen moves h3-h5
        bool result = game.makeSquaresMove(move);
        state = game.squaresState(player);
        state.state;
        
        expect(result, isTrue);
        //result should be finished bcs of checkmate
        expect(state.state, PlayState.finished);
      });
    });

    group('Game Database Tests', () {
      test('Game Creation in Firestore', () async {
        final mockUser = MockUser(uid: 'testUser',displayName: "user123");
        final gameData = {
          'gameState': {},
          'name': 'test1',
          'time': '5:00',
          'player1_color': 'white',
          'player1': mockUser.uid,
          'player2': 'unknown',
          'username2': 'Waiting for player',
          'username1': mockUser.displayName,
          'status': 'waiting',
        };

        final docRef = await firestore.collection('lobbys').add(gameData);
        final doc = await docRef.get();
        
        expect(doc.exists, isTrue);
        expect(doc.data()!['gameState'], equals({}));
        expect(doc.data()!['name'], equals('test1'));
        expect(doc.data()!['time'], equals('5:00'));
        expect(doc.data()!['player1_color'], equals('white'));
        expect(doc.data()!['player1'], equals('testUser'));
        expect(doc.data()!['player2'], equals('unknown'));
        expect(doc.data()!['username2'], equals('Waiting for player'));
        expect(doc.data()!['username1'], equals('user123'));
        expect(doc.data()!['status'], equals('waiting'));

      });

      test('Game State Update', () async {
        _resetGame();
        currentBoard = state.board;
        final docRef = await firestore.collection('lobbys').add({
          'player1': 'testUser',
          'currentBoard': currentBoard.board,
        });

        final move = Move(from: 52, to: 36); // e2-e4
        game.makeSquaresMove(move);
        state = game.squaresState(player);
        currentBoard = state.board;
        
        //update game state
        await docRef.update({
          'currentBoard': currentBoard.board,
          'lastMove': {'from': 52, 'to': 36}
        });

        //verify if state is updated
        final updatedDoc = await docRef.get();
        expect(updatedDoc.data()!['currentBoard'], isNot(equals([
        'r', 'n', 'b', 'q', 'k', 'b', 'n', 'r',
        'p', 'p', 'p', 'p', 'p', 'p', 'p', 'p',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P',
        'R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R',])));
        expect(updatedDoc.data()!['lastMove']['from'], equals(52));
        expect(updatedDoc.data()!['lastMove']['to'], equals(36));
      });
    });
  });
}