import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_session.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth;

  ProfileScreen({Key? key})
      : _auth = FirebaseAuth.instance,
        super(key: key);

  /// Récupère l’email depuis Firebase ou UserSession
  String getUserEmail() {
    return UserSession.email ?? _auth.currentUser?.email ?? 'No email';
  }

  /// Récupère la première lettre de l’email
  String getProfileInitial(String email) {
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    final String email = getUserEmail();
    final String firstLetter = getProfileInitial(email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de profil
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),

            // Email affiché
            Text(
              email,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // About App
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => _showAboutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 250, 250, 250),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Text('About App'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Privacy Policy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => _showPrivacyPolicy(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.privacy_tip_outlined),
                    SizedBox(width: 10),
                    Text('Privacy Policy'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () async {
                  await _auth.signOut();
                  UserSession.email = null;
                  UserSession.userType = null;
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About App'),
        content: const Text(
          'This is a real estate application developed to help users find and list properties.\n\n'
          'Version 1.0.0\n\n'
          '© 2023 RealEstate Inc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: const Text(
            'PRIVACY POLICY\n\n'
            '1. Information Collection\n'
            'We collect information you provide when using our app...\n\n'
            '2. Use of Information\n'
            'Your information is used to provide and improve our services...\n\n'
            '3. Data Security\n'
            'We implement security measures to protect your data...\n\n'
            'Last Updated: January 2023',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
