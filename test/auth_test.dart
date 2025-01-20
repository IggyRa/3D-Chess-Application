import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
  });
group('Authentication and validation tests', () {});
  group('Authentication Tests', () {
    test('User Registration', () async {
      const email = 'test@example.com';
      const password = 'password123';
      const username = 'testUser';

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
      });

      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, equals(email));

      final userData = await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      expect(userData.exists, isTrue);
      expect(userData.data()!['username'], equals(username));
      expect(userData.data()!['email'], equals(email));
    });

    test('User Login', () async {
      const email = 'test@example.com';
      const password = 'password123';

      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await auth.signOut();
      expect(auth.currentUser, isNull);

      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, equals(email));
    });

    test('User Logout', () async {
      const email = 'test@example.com';
      const password = 'password123';

      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      expect(auth.currentUser, isNotNull);

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });

  group('Authentication Validation Tests', () {
    
    group('Email Validation', () {
      test('Valid email formats', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+label@domain.com',
          'simple@example.com'
        ];

        for (var email in validEmails) {
          expect(validateEmail(email), isTrue, 
          reason: 'Email $email should be valid');
        }
      });

      test('Invalid email formats', () {
        final invalidEmails = [
          '',
          'notanemail',
        ];

        for (var email in invalidEmails) {
          expect(validateEmail(email), isFalse, 
          reason: 'Email $email should be invalid');
        }
      });
    });

    group('Password Validation', () {
      test('Valid passwords', () {
        final validPasswords = [
          'password123',
          '12345678',
          'verylongpassword',
          'Pass@word123'
        ];

        for (var password in validPasswords) {
          expect(validatePassword(password), isTrue, 
            reason: 'Password "$password" should be valid');
        }
      });

      test('Invalid passwords - less than 8 characters', () {
        final invalidPasswords = [
          '',
          '123',
          'pass',
          '1234567'
        ];

        for (var password in invalidPasswords) {
          expect(validatePassword(password), isFalse, 
            reason: 'Password "$password" should be invalid');
        }
      });
    });

    group('Username Validation', () {
      test('Valid usernames - minimum 4 characters', () {
        final validUsernames = [
          'user1',
          'john_doe',
          'testuser123',
          'abcd'
        ];

        for (var username in validUsernames) {
          expect(validateUsername(username), isTrue, 
            reason: 'Username "$username" should be valid');
        }
      });

      test('Invalid usernames - less than 4 characters', () {
        final invalidUsernames = [
          '',
          'ac',
          'abc'
        ];

        for (var username in invalidUsernames) {
          expect(validateUsername(username), isFalse, 
            reason: 'Username "$username" should be invalid');
        }
      });
    });

    group('Form Validation', () {
      test('Complete valid form data', () {
        final validForm = {
          'email': 'test@example.com',
          'password': 'password123',
          'username': 'testuser'
        };

        expect(validateForm(validForm), isTrue);
      });

      test('Invalid form combinations', () {
        final invalidForms = [
          {
            'email': 'invalid-email',
            'password': 'password123',
            'username': 'testuser'
          },
          {
            'email': 'test@example.com',
            'password': '123456',
            'username': 'testuser'
          },
          {
            'email': 'test@example.com',
            'password': 'password123',
            'username': 'abc'
          }
        ];

        for (var form in invalidForms) {
          expect(validateForm(form), isFalse);
        }
      });
    });
  });
}

//validation used in real database
bool validateEmail(String email) {
  if (email.trim().isEmpty || !email.contains('@')) {
    return false;
  }
  return true;
}

bool validatePassword(String password) {
  return password.trim().length >= 8;
}

bool validateUsername(String username) {
  return username.trim().length >= 4;
}

bool validateForm(Map<String, String> formData) {
  return validateEmail(formData['email'] ?? '') &&
         validatePassword(formData['password'] ?? '') &&
         validateUsername(formData['username'] ?? '');
}