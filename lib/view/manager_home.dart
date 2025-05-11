import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:front/model/user_session.dart';
import 'package:front/view/settings.dart';
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

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  User? user;
  int _selectedIndex = 0;
  SubProcessViewModel sub = SubProcessViewModel();
  ProcessViewModel pro = ProcessViewModel();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
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
    final session = context.watch<UserSession>();

    if (!session.isLoggedIn) {
      return const Login();
    }
    final intl = AppLocalizations.of(context)!;
    user = session.user!;
    print("Welcome user :${user!.name}");

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
    items: [
      TabItem(icon: Icons.dashboard, title: intl.workflows),
      TabItem(icon: Icons.home, title: ''),
      TabItem(icon: Icons.settings, title: intl.settings),
      
    ],
    initialActiveIndex: _selectedIndex,
onTap: (int index) {
  if (index == 1) return; // skip dummy
  _onItemTapped(index > 1 ? index - 1 : index);
}
,
    backgroundColor: Color(0xFFB5927F),
    activeColor: Colors.white,
    color: Colors.white70,
    style: TabStyle.reactCircle,
  ),
    );
  }
}
