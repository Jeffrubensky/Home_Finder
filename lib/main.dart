import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

// Pages
import 'package:homefinder/welcom_page.dart';
import 'package:homefinder/login_page.dart';
import 'package:homefinder/home_page.dart';
import 'package:homefinder/profile_screen.dart';
import 'package:homefinder/homepage_client.dart';
 // 🔁 Assure-toi d'avoir cette page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase init
  await Supabase.initialize(
    url: 'https://puhwoxbhvhhhzyidpsgn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB1aHdveGJodmhoaHp5aWRwc2duIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzOTI3MzEsImV4cCI6MjA1Nzk2ODczMX0.-YwehHNMPsLG9WUu3eL9IUWh46PLuUY6aQus9ScyRCg',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _determineStartPage();
  }

  /// 🔁 Logique de redirection
  Future<Widget> _determineStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final supabaseUser = Supabase.instance.client.auth.currentUser;

    if (isFirstLaunch) {
      await prefs.setBool('firstLaunch', false);
      return const WelcomePage(); // 🆕 premier lancement
    }

    if (supabaseUser != null) {
      return const HomePage() ; // 👤 utilisateur Supabase
    }

    if (firebaseUser != null) {
      return const HomePageClient(); // 🔐 utilisateur Firebase
    }

    return const LoginPage(); // 👋 accueil pour connexion ou inscription
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<Widget>(
        future: _initialScreen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading app"));
          } else {
            return snapshot.data!;
          }
        },
      ),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/auth': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/homeclient': (context) => const HomePageClient(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
