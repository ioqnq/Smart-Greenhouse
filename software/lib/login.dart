import 'package:flutter/material.dart';
import 'navigation.dart';
import 'register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = true;
  bool isLoading = false;
  bool obscurePass = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in email and password.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(
          rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight, 
      appBar: AppBar(
        title: const Text('Login'),
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
              obscureText: obscurePass,
              onSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePass = !obscurePass;
                    });
                  },
                  icon: Icon(
                    obscurePass ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,     
              foregroundColor: AppColors.textLight,    
              ),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NavigationExample(),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Login failed')),
                  );
                }
              },
              child: const Text('Login'),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                );
              },
              child: const Text("Don't have an account? Register", style: TextStyle(
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
