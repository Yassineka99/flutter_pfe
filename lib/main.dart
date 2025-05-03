import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:front/model/user_session.dart';
import 'package:front/services/locale_provider.dart';
import 'package:front/view/home.dart';
import 'package:front/view/manager_home.dart';
import 'package:front/view/spash_screen.dart';
import 'package:front/view/worker_home.dart';
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
    ],
    child: const MyApp(),
  ),
);

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
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
        home: roleDetector(context));
  }
}

Widget roleDetector(BuildContext context) {
  final session = context.watch<UserSession>();
  if (session.isLoggedIn) {
    if (session.user!.role == 1) {
      return const AdminHome();
    } else if (session.user!.role == 2) {
      return const ManagerHome();
    } else {
      return const WorkerHome();
    }
  }
  return const Splash();
}
