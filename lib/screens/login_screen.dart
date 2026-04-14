import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String errorMessage = "";
  bool isLoading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'isOnline': true,
      });

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final role = doc['role'];

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (role == 'security') {
        Navigator.pushReplacementNamed(context, '/security');
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Login failed";
      });
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                )
              ],
            ),
            child: Form(
              key: _formKey, // ✅ FORM ADDED
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// ICON + TITLE
                  const Icon(Icons.lock, size: 40, color: Colors.blue),
                  const SizedBox(height: 10),

                  const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// EMAIL
                  TextFormField(
                    controller: emailController,
                    decoration: inputStyle("Email", Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email is required";
                      }
                      if (!value.contains('@')) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  /// PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: inputStyle("Password", Icons.lock_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password is required";
                      }
                      if (value.length < 6) {
                        return "Minimum 6 characters required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  /// ERROR MESSAGE
                  if (errorMessage.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 15),

                  /// LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}