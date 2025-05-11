import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:front/model/user_session.dart';
import 'package:front/repository/workflow_repository.dart';
import 'package:front/services/biometric_auth.dart';
import 'package:front/services/locale_provider.dart';
import 'package:front/services/theme_provider.dart';
import 'package:front/view/home.dart';
import 'package:front/view/manager_home.dart';
import 'package:front/view/spash_screen.dart';
import 'package:front/view/worker_home.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = UserSession();
  await session.loadFromDb();

runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: session),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const MyApp(),
  ),
);
  Timer.periodic(Duration(minutes: 5), (_) => WorkflowRepository().syncWorkflows());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
        supportedLocales: L10n.all,
        locale: localeProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF78A190),
          secondary: const Color(0xFF28445C),
          surface: Colors.white,
          background: Colors.grey[100]!,
          error: const Color(0xFFB00020),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF78A190)),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
        ),

      ),),
      darkTheme: ThemeData(
        colorScheme:const ColorScheme.dark(
          primary:  Color(0xFF507567),
          secondary:  Color(0xFF8BA7B5),
          surface:  Color(0xFF121212),
          background:  Color(0xFF121212),
          error:  Color(0xFFCF6679),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.black,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF507567)),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
        ),

      )),
        home: AuthGate());
      
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _authenticated = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = context.read<UserSession>();

    // Skip biometrics if not enabled
    if (!session.useFingerprint) {
      setState(() {
        _authenticated = true;
        _loading = false;
      });
      return;
    }

    final localAuth = LocalAuthentication();
    final canAuth = await localAuth.canCheckBiometrics;

    if (!canAuth) {
      setState(() {
        _authenticated = true;
        _loading = false;
      });
      return;
    }

    final success = await localAuth.authenticate(
      localizedReason: 'Verify your identity to continue',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (!success) {
      await session.logOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Splash()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _authenticated = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();

    if (!session.isLoggedIn) return const Splash();
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return roleDetector(context);
  }
}


Widget roleDetector(BuildContext context) {
  final session = context.watch<UserSession>();
  
  if (session.user!.role == 1) return const AdminHome();
  if (session.user!.role == 2) return const ManagerHome();
  return const WorkerHome();
}