import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF020911);
    const primaryGreen = Color(0xFF00D64F);
    const subtitleColor = Color(0xFF9AA4B2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '프로필',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF072315),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 40,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '프로필 화면',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '준비중입니다',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
