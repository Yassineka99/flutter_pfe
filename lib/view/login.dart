import 'package:flutter/material.dart';
import 'package:front/view/worker_home.dart';
import 'package:provider/provider.dart';
import '../model/user.dart';
import '../model/user_session.dart';
import '../viewmodel/user_view_model.dart';
import 'home.dart';
import 'manager_home.dart';
import 'mini_widgets/password_input.dart';
import 'mini_widgets/text_input.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserViewModel _userViewModel = UserViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 60,
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78A190).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 32,
                        color: Color(0xFF28445C),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'BrandonGrotesque',
                        color: Color(0xFF28445C),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Input Fields
                    TextInput(
                      hint: "Email",
                      controller: _emailController,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    PasswordInput(
                      hint: "Password",
                      controller: _passwordController,
                      icon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF78A190),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'BrandonGrotesque',
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    final session = Provider.of<UserSession>(context, listen: false);
    final client = await _userViewModel.getClientbyEmail(_emailController.text.trim());

    if (client != null && client.password == _passwordController.text) {
      await session.logIn(client);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _getHomeScreen(client.role!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _getHomeScreen(int role) {
    switch (role) {
      case 1: return const AdminHome();
      case 2: return const ManagerHome();
      default: return const WorkerHome();
    }
  }
}