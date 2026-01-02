import 'package:flutter/material.dart';
import 'navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight, 
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,     
              foregroundColor: AppColors.textLight,    
              ),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account created!")),
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NavigationExample(),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message ?? 'Registration failed'),
                    ),
                  );
                }
              },
              child: const Text('Create account'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Already have an account? Login', style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w100,
                    color: AppColors.textGrey,
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
