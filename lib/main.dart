import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:front/model/user_session.dart';
import 'package:front/services/locale_provider.dart';
import 'package:front/services/theme_provider.dart';
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
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
