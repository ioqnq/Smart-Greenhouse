import 'package:flutter/material.dart';
import 'login.dart';
import 'constants/colors.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  double imageSize(BuildContext context) {
    if (kIsWeb) return 400;
    if (Platform.isAndroid || Platform.isIOS) return 250;
    return 400; // desktop
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🌱 Imaginea
            Image.asset(
              'images/greenhouse.png',
              width: imageSize(context),
            ),

            const SizedBox(height: 40),

            // 🔘 Butonul
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Start your smart greenhouse!",
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
