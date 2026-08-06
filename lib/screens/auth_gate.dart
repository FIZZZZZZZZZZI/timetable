import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Root of the app below the theme wrapper: shows [LoginScreen] when no
/// Firebase user is signed in, otherwise the normal [HomeShell] nav. Backed
/// by Firebase Auth's own persisted session (`authStateChanges`), so a
/// previously signed-in user skips the login screen on app start with no
/// extra work here.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const HomeShell();
      },
    );
  }
}
