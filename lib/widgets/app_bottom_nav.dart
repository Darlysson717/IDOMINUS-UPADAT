import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final BottomNavigationBarType type;
  final double barHeight;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.type = BottomNavigationBarType.fixed,
    this.barHeight = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final paddingBottom = bottomInset;

    return SizedBox(
      height: barHeight + paddingBottom,
      child: Padding(
        padding: EdgeInsets.only(bottom: paddingBottom),
        child: BottomNavigationBar(
          type: type,
          backgroundColor: backgroundColor,
          elevation: 14,
          currentIndex: currentIndex,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          onTap: onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Lojistas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
