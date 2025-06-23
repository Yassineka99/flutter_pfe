import 'package:bcrypt/bcrypt.dart';
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
                color: const Color(0xFFF8F5F3),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4e3a31).withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Auth Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA17A69).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 36,
                        color: const Color(0xFF4e3a31).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BrandonGrotesque',
                        color: const Color(0xFF4e3a31).withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Input Fields
                    TextInput(
                      hint: "Email",
                      controller: _emailController,
                      icon: Icons.email_rounded,
                    ),
                    const SizedBox(height: 20),
                    PasswordInput(
                      hint: "Password",
                      controller: _passwordController,
                      icon: Icons.lock_rounded,
                    ),
                    const SizedBox(height: 36),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB5927F),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          shadowColor: const Color(0xFF4e3a31).withOpacity(0.3),
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'BrandonGrotesque',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
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
    final client =
        await _userViewModel.getClientbyEmail(_emailController.text.trim());
    final passtest = BCrypt.hashpw(_passwordController.text, BCrypt.gensalt());
    print("hashed pass is : $passtest");
    if (client != null &&
        BCrypt.checkpw(_passwordController.text, client.password!))
    //client.password == _passwordController.text
    {
      await session.logIn(client);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _getHomeScreen(client.role!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid credentials'),
          backgroundColor: const Color(0xFFA17A69),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _getHomeScreen(int role) {
    switch (role) {
      case 1:
        return const AdminHome();
      case 2:
        return const ManagerHome();
      default:
        return const WorkerHome();
    }
  }
}
