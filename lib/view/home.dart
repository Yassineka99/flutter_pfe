import 'package:flutter/material.dart';
import 'package:front/model/user_session.dart';
import 'package:front/view/settings.dart';
import 'package:front/view/users_view.dart';
import 'package:front/viewmodel/process_view_model.dart';
import 'package:front/viewmodel/sub_process_view_model.dart';
import 'package:front/viewmodel/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/user.dart';
import 'dashboard.dart';
import 'login.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  User? user;
  int _selectedIndex = 0;
  SubProcessViewModel sub = SubProcessViewModel();
  ProcessViewModel pro = ProcessViewModel();
  late List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardWidget(processVM: pro, subProcessVM: sub),
      UsersView(),
      SettingsView(),
       SettingsView(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    final session = context.watch<UserSession>();
    if (!session.isLoggedIn) {
      return const Login();
    }
    user = session.user!;
    print("Welcome user :${user!.name}");

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF78A190),
        selectedItemColor: const Color(0xFF28445C),
        unselectedItemColor: const Color(0xFF28445C).withOpacity(.40),
        selectedFontSize: 14,
        unselectedFontSize: 14,
        onTap: _onItemTapped,
        items:  [
          BottomNavigationBarItem(
            label: intl.dashboard,
            icon: Icon(Icons.dashboard),
          ),
          BottomNavigationBarItem(
            label: intl.users,
            icon: Icon(Icons.person),
          ),
          BottomNavigationBarItem(
            label: intl.workflows,
            icon: Icon(Icons.polyline_rounded),
          ),
          BottomNavigationBarItem(
            label: intl.settings,
            icon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
