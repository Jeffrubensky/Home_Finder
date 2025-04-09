import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

   ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    final String email = user?.email ?? 'No email';
    final String firstLetter = email.isNotEmpty ? email[0].toUpperCase() : '?';

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
            /// ✅ Icône de profil (avatar avec initiale si pas de photo)
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue, // Couleur de fond de l’avatar
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null, // Utilisation de l’image Firebase si disponible
              child: user?.photoURL == null
                  ? Text(
                      firstLetter,
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null, // Affichage de l'initiale si pas d’image
            ),
            SizedBox(height: 10),

            /// ✅ Affichage de l'email de l'utilisateur
            Text(
              email,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            /// ✅ Bouton de déconnexion
            ElevatedButton.icon(
              onPressed: () async {
                await _auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
