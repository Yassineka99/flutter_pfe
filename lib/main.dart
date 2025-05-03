import 'package:flutter/material.dart';
import 'package:front/model/user_session.dart';
import 'package:front/view/home.dart';
import 'package:front/view/spash_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = UserSession();
  await session.loadFromDb();

  runApp(
    ChangeNotifierProvider.value(
      value: session,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session.isLoggedIn
          ? const Home()
          : const Splash(),
    );
  }
}
