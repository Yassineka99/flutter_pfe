import 'package:flutter/material.dart';

import 'login.dart';


class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(    
      duration: const Duration(seconds: 2), 
      vsync: this,);
          _animation = Tween<double>(begin: 0.0, end: 1.0) // fade from 0 (invisible) to 1 (visible)
        .animate(_controller)
..addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    _controller.reverse();
  } else if (status == AnimationStatus.dismissed) {
    // Wait until the current frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    });
  }
});


    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: FadeTransition(
      opacity: _animation,
      child: Center(
        child: Image.asset(
          'assets/images/22222-removebg-preview.png',
          width: 284,
          height: 305.05,
        ),
      ),
    ),
  );
}
}