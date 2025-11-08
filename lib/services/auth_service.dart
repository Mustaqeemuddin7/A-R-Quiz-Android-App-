import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '777661093391-4l061mqq5jn4ck2qktj5s3p1c5bo1r1g.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/userinfo.email',
    ],
    signInOption: SignInOption.standard,
    hostedDomain: null,
  );
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isAuthenticated => currentUser != null;
  
  // Google Sign In with Popup
  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // Try silent sign-in first on web
        try {
          googleUser = await _googleSignIn.signInSilently();
        } catch (e) {
          print('Silent sign-in failed: $e');
        }

        // If silent sign-in fails, use popup
        if (googleUser == null) {
          try {
            googleUser = await _googleSignIn.signIn();
          } catch (e) {
            print('Popup sign-in error: $e');
            rethrow;
          }
        }
      } else {
        // Mobile flow
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        print('Sign in was canceled by user');
        return null;
      }

      // Get auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Create/update user document
      if (userCredential.user != null) {
        await FirestoreService().createOrUpdateUser(userCredential.user!);
      }

      notifyListeners();
      return userCredential;

    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Get user display name
  String? getUserName() {
    return currentUser?.displayName;
  }
  
  // Get user email
  String? getUserEmail() {
    return currentUser?.email;
  }
  
  // Get user photo URL
  String? getUserPhotoUrl() {
    return currentUser?.photoURL;
  }
}