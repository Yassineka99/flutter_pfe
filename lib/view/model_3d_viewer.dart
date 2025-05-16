import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';

class MyWidget extends StatefulWidget {
  final String modelpath ;
  const MyWidget({super.key, required this.modelpath});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  O3DController o3dController = O3DController();
  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 300,
              height: 300,
              child: O3D(
                  src: widget.modelpath,
                  controller: o3dController,
                  ar: false,
                  autoPlay: false,
                  autoRotate: false,
                  
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
