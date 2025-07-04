// lib/services/auth_service.dart

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Ganti `supabase` menjadi `Supabase.instance.client`
  Stream<AuthState> get authStateChanges => Supabase.instance.client.auth.onAuthStateChange;
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Future<void> signInWithGoogle() async {
    try {
      const webClientId = '267412875964-j8e40o9nhohbtcaqqn2ps4m1tb6qihrq.apps.googleusercontent.com';
      // const iosClientId = '';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: webClientId,
      );

      final isSignedIn = await googleSignIn.isSignedIn();
      print('Google isSignedIn: $isSignedIn');

      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }
      print("AccessToken: $accessToken");
      print("IDToken: $idToken");

      final session = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken,
      );
      print("Supabase session: ${session.session}");

    } catch (e) {
      print("Error during Google Sign-In with Supabase: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await GoogleSignIn().signOut(); // jika pakai google_sign_in package

      print("Berhasil logout dari Google dan Supabase.");
    } catch (e) {
      print("Error saat logout: $e");
    }
  }

  Future<void> logoutTotal(BuildContext context) async {
    try {
      // Supabase logout
      await signOut();

      // Google Sign-In logout
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut(); // Ini cukup, jangan pakai disconnect
      } catch (e) {
        debugPrint("Google signOut failed: $e");
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Restart app (like fresh start)
      Phoenix.rebirth(context);
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }
}
