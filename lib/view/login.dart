import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/user.dart';
import '../model/user_session.dart';
import '../viewmodel/user_view_model.dart';
import 'home.dart';
import 'mini_widgets/text_input.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  UserViewModel userViewModel = UserViewModel();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // allow the body to resize when the keyboard appears:
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          // this padding pushes content up by the height of the keyboard:
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 150),
                const Text(
                  "Login",
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 40,
                    fontFamily: 'BrandonGrotesque',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 50),
                TextInput(
                  hint: "Email", controller: emailcontroller
                ),
                const SizedBox(height: 10),
                TextInput(
                  hint: "Password", controller: passwordcontroller
                ),
                Container(
                  width: 327,
                  height: 56,
                  margin: const EdgeInsets.only(top: 30),
                  child: ElevatedButton(
                  onPressed: () async {
                  User? client = await userViewModel
                                .getClientbyEmail(emailcontroller.text.trim());
                            if (client != null) {
                              print("Stored password: ${client.password}");
                              print("Entered password: ${passwordcontroller.text}");
                              if (client.password == passwordcontroller.text) {
                                
                                // ignore: use_build_context_synchronously
                               await Provider.of<UserSession>(context, listen: false).logIn(client);
                                     // ignore: use_build_context_synchronously
                                     
                                     Navigator.pushReplacement(
                                     context,
                                      MaterialPageRoute(
                                        builder: (context) => const Home()),
                                  );
                              } else {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid Password'),
                                  ),
                                );
                              }
                            }
                            else {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid Email'),
                                  ),
                                );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFbdc6d9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      "Confirm",
                      style: TextStyle(fontFamily: 'BrandonGrotesque'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
