import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../model/user_session.dart';
import '../view/spash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<bool> _authFuture;

  @override
  void initState() {
    super.initState();
    final session = context.read<UserSession>();
    _authFuture = _verifyAuth(session);
  }

  Future<bool> _verifyAuth(UserSession session) async {
    if (!session.useFingerprint) return true;
    
    final localAuth = LocalAuthentication();
    if (!await localAuth.canCheckBiometrics) return true;
    
    return await localAuth.authenticate(
      localizedReason: 'Verify your identity',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();

    return FutureBuilder<bool>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            session.logOut();
          });
          return const Splash();
        }

        return roleDetector(context);
      },
    );
  }
}