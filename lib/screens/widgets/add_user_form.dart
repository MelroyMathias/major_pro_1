import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserForm extends StatefulWidget {
  const AddUserForm({super.key});

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final floorController = TextEditingController();
  final cameraController = TextEditingController();

  bool isLoading = false;
  String message = "";

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      message = "";
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'security',
        'floor': floorController.text.trim(),
        'cameraLocation': cameraController.text.trim(),
        'isOnline': false,
        'createdAt': DateTime.now().toString(),
        'currentLocation': {
          'latitude': 0.0,
          'longitude': 0.0,
        },
      });

      setState(() {
        message = "User created successfully";
      });

      nameController.clear();
      emailController.clear();
      passwordController.clear();
      floorController.clear();
      cameraController.clear();
    } on FirebaseAuthException catch (e) {
      setState(() {
        message = e.message ?? "Error creating user";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 700;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black12,
              )
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                /// TITLE
                const Text(
                  "Add Security Guard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 16),

                /// NAME
                TextFormField(
                  controller: nameController,
                  decoration: inputStyle("Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Name required" : null,
                ),

                const SizedBox(height: 12),

                /// EMAIL
                TextFormField(
                  controller: emailController,
                  decoration: inputStyle("Email"),
                  validator: (value) {
                    if (value!.isEmpty) return "Email required";
                    if (!value.contains('@')) return "Invalid email";
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                /// PASSWORD
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: inputStyle("Password"),
                  validator: (value) {
                    if (value!.isEmpty) return "Password required";
                    if (value.length < 6) return "Min 6 characters";
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                /// FLOOR + CAMERA
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: floorController,
                              decoration: inputStyle("Floor"),
                              validator: (value) =>
                                  value!.isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: cameraController,
                              decoration: inputStyle("Camera"),
                              validator: (value) =>
                                  value!.isEmpty ? "Required" : null,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: floorController,
                            decoration: inputStyle("Floor"),
                            validator: (value) =>
                                value!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: cameraController,
                            decoration: inputStyle("Camera"),
                            validator: (value) =>
                                value!.isEmpty ? "Required" : null,
                          ),
                        ],
                      ),

                const SizedBox(height: 14),

                /// MESSAGE
                if (message.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: message.contains("success")
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : createUser,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                        : const Text("Create User"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}