import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _email;
  bool _isSupabaseUser = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      final supabaseUser = _supabase.auth.currentUser;

      if (supabaseUser != null) {
        _isSupabaseUser = true;
        final userId = supabaseUser.id;

        // 🔎 Requête sur la table Supabase (par exemple 'users')
        final response = await _supabase
            .from('users')
            .select('email')
            .eq('id', userId)
            .single();

        setState(() {
          _email = response['email'];
          _isLoading = false;
        });
      } else if (firebaseUser != null) {
        setState(() {
          _email = firebaseUser.email;
          _isLoading = false;
        });
      } else {
        setState(() {
          _email = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur de chargement utilisateur: $e');
      setState(() {
        _email = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String firstLetter = (_email?.isNotEmpty ?? false) ? _email![0].toUpperCase() : '?';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                firstLetter,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _email ?? 'No email found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                if (_isSupabaseUser) {
                  await _supabase.auth.signOut();
                } else {
                  await _firebaseAuth.signOut();
                }
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
