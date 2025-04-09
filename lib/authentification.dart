import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'homepage_client.dart';
//import 'client_home_page.dart';

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final firebaseAuth = firebase_auth.FirebaseAuth.instance;

    return Scaffold(
      body: StreamBuilder<firebase_auth.User?>(
        stream: firebaseAuth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.hasData && authSnapshot.data != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _getUserData(supabase, authSnapshot.data!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userType = userSnapshot.data!['user_type'] as String?;
                  return userType == 'client' ?HomePageClient() : HomePage();
                }

                return _handleMissingUserData(context);
              },
            );
          }
          return LoginPage();
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserData(SupabaseClient supabase, String uid) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('firebase_uid', uid)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Chargement de votre profil...'),
          ],
        ),
      ),
    );
  }

  Widget _handleMissingUserData(BuildContext context) {
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil utilisateur introuvable')),
      );
      firebase_auth.FirebaseAuth.instance.signOut();
    });
    return LoginPage();
  }
}