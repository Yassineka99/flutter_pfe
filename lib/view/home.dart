import 'package:flutter/material.dart';
import 'package:front/model/user_session.dart';
import 'package:front/view/settings.dart';
import 'package:front/view/users_view.dart';
import 'package:front/view/workflows_view.dart';
import 'package:front/viewmodel/process_view_model.dart';
import 'package:front/viewmodel/sub_process_view_model.dart';
import 'package:front/viewmodel/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/user.dart';
import 'dashboard.dart';
import 'login.dart';
import 'mini_widgets/custom_nav_bar.dart';

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
      const DashboardView(),
      const UsersView(),
      const WorkflowView(),
      const SettingsView(),
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
  bottomNavigationBar: SafeArea(
    child: CustomBottomNavBar(
    selectedIndex: _selectedIndex,
    onItemTapped: _onItemTapped,
    icons: [Icons.dashboard, Icons.person, Icons.polyline_rounded, Icons.settings],
    labels: [intl.dashboard, intl.users, intl.workflows, intl.settings],
  ),
  ),
);
  }
}
