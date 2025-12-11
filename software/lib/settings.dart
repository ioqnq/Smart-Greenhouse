import 'package:flutter/material.dart';
import 'login.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🔧 Modify profile
            ElevatedButton(
              onPressed: () {
                // aici deschizi pagina de edit profil
              },
              child: const Text('Edit profile'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}



// class Settings extends StatelessWidget {
//   const Settings({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color.fromARGB(255, 0, 170, 170),
//             ),
//             onPressed: () {},
//             child: const Text('Log In'),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color.fromARGB(255, 0, 170, 170),
//             ),
//             onPressed: () {},
//             child: const Text('Registration'),
//           ),
//         ],
//       ),
//     );
//   }
// }