import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final List<IconData> icons;
  final List<String> labels;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.icons,
    required this.labels,
  });

  double _getTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFB5927F),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final bool isSelected = index == selectedIndex;
            final textStyle = const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            );
            final double textWidth = _getTextWidth(labels[index], textStyle);

            return GestureDetector(
              onTap: () => onItemTapped(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                transform: Matrix4.identity()
                  ..scale(isSelected ? 1.08 : 1.0)
                  ..translate(0.0, isSelected ? -4.0 : 0.0),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFA17A69) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4e3a31).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: const Color(0xFFA17A69).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Top line
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 3,
                      width: isSelected ? textWidth : 50,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.transparent : const Color(0xFF4e3a31),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: isSelected ? 40 : 32,
                      width: isSelected ? 46 : 38,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF5E6DC) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: AnimatedRotation(
                          turns: isSelected ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Icon(
                            icons[index],
                            size: isSelected ? 24 : 20,
                            color: isSelected
                                ? const Color(0xFF4e3a31)
                                : const Color(0xFFA17A69),
                          ),
                        ),
                      ),
                    ),

                    // Label
                    SizedBox(
                      height: 16,
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: AnimatedDefaultTextStyle(
                          style: textStyle.copyWith(color: const Color(0xFF4e3a31)),
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            margin:EdgeInsets.only(top: 0),
                            child: Text(
                              labels[index], 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'BrandonGrotesque'
                              ),),
                          ),
                        ),
                      ),
                    ),

                    // Bottom line
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 3,
                      width: isSelected ? textWidth : 50,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4e3a31) : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}