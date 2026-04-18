import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

/// Screen for new user registration.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

/// State management for the registration screen and Firebase integration.
class _RegisterPageState extends State<RegisterPage> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color accentColor = const Color(0xFFFCA048);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  /// Displays error messages via an alert dialog.
  void _showErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFCA048),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles user registration and database initialization.
  Future<void> _register() async {
    if (_emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty ||
        _confirmPasswordCtrl.text.trim().isEmpty) {
      _showErrorPopup(
        'Incomplete Form',
        'Please fill out all fields before proceeding.',
      );
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showErrorPopup(
        'Password Mismatch',
        'The passwords you entered do not match. Please try again.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );

      final counterRef = FirebaseFirestore.instance
          .collection('system_data')
          .doc('user_counter');
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
        int currentId = 0;
        if (counterSnapshot.exists) {
          currentId =
              (counterSnapshot.data() as Map<String, dynamic>)['last_id'] ?? 0;
        }

        int newId = currentId + 1;
        String customUserId = newId.toString().padLeft(3, '0');

        transaction.set(counterRef, {'last_id': newId});
        transaction.set(userRef, {
          'userid': customUserId,
          'name': '',
          'blood_type': '',
          'weight': '',
          'height': '',
          'allergies': '',
          'chronic_conditions': '',
        });
      });

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage =
            'The password provided is too weak (minimum 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      _showErrorPopup('Registration Failed', errorMessage);
    } catch (e) {
      _showErrorPopup('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Main UI builder for the registration screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/Medification_Logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Join Medification for smart medication management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField('Email', _emailCtrl, false),
                const SizedBox(height: 15),
                _buildTextField('Password', _passwordCtrl, true),
                const SizedBox(height: 15),
                _buildTextField('Confirm Password', _confirmPasswordCtrl, true),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                        onTap: _register,
                        child: Container(
                          width: double.infinity,
                          height: 55,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                  child: Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to build text input fields.
  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    bool isObscure,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }
}
