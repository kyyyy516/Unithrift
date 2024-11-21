import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // Create a new user
  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      developer.log("FirebaseAuthException: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      developer.log("Unexpected error: $e");
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      developer.log("Password reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      developer.log("FirebaseAuthException: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      developer.log("Unexpected error: $e");
      rethrow;
    }
  }

  // Verify if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      developer.log("Error checking email registration: $e");
      rethrow;
    }
  }

  // Send email verification link
  Future<void> sendEmailVerification(String email) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User is not signed in.");
      
      // Send verification email
      await user.sendEmailVerification();
    } catch (e) {
      throw Exception("Error sending email verification: $e");
    }
  }
}