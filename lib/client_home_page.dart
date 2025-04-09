import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image d'accueil
            Image.asset(
              'assets/2.jpg', // Chemin vers votre image dans les assets
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            
            const SizedBox(height: 20),
            
            // Message de bienvenue
            Text(
              'Hello, ${user?.email ?? 'Cher Client'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}