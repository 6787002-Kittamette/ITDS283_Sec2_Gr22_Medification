import 'package:flutter/material.dart';

/// Screen displayed after successfully adding a medication.
class PillSuccessful extends StatelessWidget {
  const PillSuccessful({super.key});

  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color accentColor = const Color(0xFFFCA048);

  /// Main UI builder displaying the success message and confirmation button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Successfully added your pill',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'You can check your pill in stock page',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    /// Navigates back to the home screen on tap.
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    ),
                    child: Container(
                      width: 150,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF5A3B24),
                        size: 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  /// Builds the custom bottom navigation bar.
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF88C5C4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(context, Icons.add, 0, true),
          _navItem(context, Icons.medication_outlined, 1, false),
          _navItem(context, Icons.home, 2, false),
          _navItem(context, Icons.menu_book_outlined, 3, false),
          _navItem(context, Icons.person_outline, 4, false),
        ],
      ),
    );
  }

  /// Helper to build individual navigation icons and handle routing.
  Widget _navItem(
    BuildContext context,
    IconData icon,
    int index,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0)
            Navigator.pushReplacementNamed(context, '/pill_description');
          else if (index == 1)
            Navigator.pushReplacementNamed(context, '/stock');
          else if (index == 2)
            Navigator.pushReplacementNamed(context, '/home');
          else if (index == 3)
            Navigator.pushReplacementNamed(context, '/history');
          else if (index == 4)
            Navigator.pushNamed(context, '/profile');
        },
        child: Container(
          color: Colors.transparent,
          height: 80,
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFCA048)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF5A3B24), size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
