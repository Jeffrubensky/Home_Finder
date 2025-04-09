import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:homefinder/my_textfield.dart';
import 'package:homefinder/my_button.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'homepage_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? _selectedUserType; // 'client' ou 'standard'
  bool isLoading = false;

  final supabase = Supabase.instance.client;
  final firebaseAuth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
  if (_selectedUserType == null) {
    showSnackBar("Veuillez sélectionner un type de compte");
    return;
  }

  String email = emailController.text.trim();
  String password = passwordController.text.trim();
  String confirmPassword = confirmPasswordController.text.trim();

  if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
    showSnackBar("Tous les champs sont obligatoires");
    return;
  }

  if (password != confirmPassword) {
    showSnackBar("Les mots de passe ne correspondent pas");
    return;
  }

  showLoadingDialog();

  try {
    if (_selectedUserType == 'client') {
      // Enregistrer uniquement dans Firebase
      await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      showSnackBar("Compte Client créé avec succès !");
    } else {
      // Enregistrer uniquement dans Supabase
      await supabase.from('users').upsert({
        'email': email,
        'password': password,
        'user_type': _selectedUserType,
        'created_at': DateTime.now().toIso8601String(),
      });
      showSnackBar("Compte Standard créé avec succès !");
    }

    // Redirection
    if (mounted) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _selectedUserType == 'client' 
              ? HomePageClient() 
              : HomePage(),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      Navigator.pop(context);
      showSnackBar("Erreur lors de l'inscription: ${e.toString()}");
    }
  }
}


  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);

      // Pour Google Sign-In, demander le type de compte si nouvel utilisateur
      if ((userCredential.additionalUserInfo?.isNewUser ?? false) && mounted) {
        await showUserTypeDialog();
        if (_selectedUserType != null) {
          await supabase.from('users').upsert({
            'firebase_uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'user_type': _selectedUserType,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      showSnackBar("Erreur Google Sign-In: $e");
      return null;
    }
  }

  Future<void> showUserTypeDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Type de compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Client'),
              leading: Radio<String>(
                value: 'client',
                groupValue: _selectedUserType,
                onChanged: (value) {
                  setState(() => _selectedUserType = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Utilisateur Standard'),
              leading: Radio<String>(
                value: 'standard',
                groupValue: _selectedUserType,
                onChanged: (value) {
                  setState(() => _selectedUserType = value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Image d'en-tête
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Image.asset(
                "assets/12.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Formulaire
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Create an account",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Text("Join us today!", style: TextStyle(color: Colors.grey[600])),

                    const SizedBox(height: 25),
                    MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                    const SizedBox(height: 10),
                    MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                    const SizedBox(height: 10),
                    MyTextField(controller: confirmPasswordController, hintText: 'Confirm Password', obscureText: true),

                    // Sélection du type de compte
                    const SizedBox(height: 15),
                    Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Account Type",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              children: [
                                ChoiceChip(
                                  label: const Text('Client'),
                                  selected: _selectedUserType == 'client',
                                  onSelected: (selected) {
                                    setState(() => _selectedUserType = selected ? 'client' : null);
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Standard User'),
                                  selected: _selectedUserType == 'standard',
                                  onSelected: (selected) {
                                    setState(() => _selectedUserType = selected ? 'standard' : null);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),


                    const SizedBox(height: 15),
                    MyButton(
                      onTap: registerUser,
                      text: "Sign Up",
                    ),

                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400])),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Or continue with', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400])),
                      ],
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final user = await signInWithGoogle();
                        if (user != null && mounted && _selectedUserType != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _selectedUserType == 'client' 
                                  ?HomePageClient() 
                                  : HomePage(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/google.png', height: 24),
                          const SizedBox(width: 10),
                          const Text(
                            "Continue with Google",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}