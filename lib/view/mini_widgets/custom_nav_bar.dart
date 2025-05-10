import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76, 
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFB5927F),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, -4)),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final bool isSelected = index == selectedIndex;
            return GestureDetector(
              onTap: () => onItemTapped(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutExpo,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4e3a31).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: const Color(0xFFF5E6DC).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 3,
                      width: 50,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.transparent : const Color(0xFF4e3a31),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: isSelected ? 40 : 32,
                      width: isSelected ? 46 : 38,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF4e3a31).withOpacity(0.9),
                                  const Color(0xFFB5927F).withOpacity(0.42),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: AnimatedRotation(
                          turns: isSelected ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Icon(
                            icons[index],
                            size: isSelected ? 24 : 20,
                            color: isSelected ? const Color(0xFFF5E6DC) : const Color(0xFFA17A69),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                    height: 16, // Always reserve space
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: AnimatedDefaultTextStyle(
                        style: const TextStyle(
                          color: Color(0xFF4e3a31),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        duration: const Duration(milliseconds: 400),
                        child: Text(labels[index], overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),


                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 3,
                      width: 50,
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