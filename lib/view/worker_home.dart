import 'package:flutter/material.dart';
import 'package:front/model/user_session.dart';
import 'package:front/view/settings.dart';
import 'package:front/viewmodel/process_view_model.dart';
import 'package:front/viewmodel/sub_process_view_model.dart';
import 'package:front/viewmodel/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/user.dart';
import 'assigned_sub_processes.dart';
import 'dashboard.dart';
import 'login.dart';
import 'mini_widgets/custom_nav_bar.dart';

class WorkerHome extends StatefulWidget {
  const WorkerHome({super.key});

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> {

  int _selectedIndex = 0;
  SubProcessViewModel sub = SubProcessViewModel();
  ProcessViewModel pro = ProcessViewModel();
  late List<Widget> _pages;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    final session = context.watch<UserSession>();
    if (!session.isLoggedIn) {
      return const Login();
    }
    final user = session.user!;
    print("Welcome user :${user!.name}");
    final intl = AppLocalizations.of(context)!;

    final _pages = [
      AssignedSubProcesses(userId: user.id!),
      const SettingsView(),
    ];
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
    child: CustomBottomNavBar(
    selectedIndex: _selectedIndex,
    onItemTapped: _onItemTapped,
    icons: [Icons.task, Icons.settings],
    labels: [intl.assignedSubProcess, intl.settings],
  ),
  ),
    );
  }
}
