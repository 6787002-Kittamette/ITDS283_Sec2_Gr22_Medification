import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'contact_us_page.dart';

/// Screen for viewing and editing user profile information.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// State management for the profile page.
class _ProfilePageState extends State<ProfilePage> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color bottomNavColor = const Color(0xFF88C5C4);
  final Color cardColor = const Color(0xFFF6EFE6);

  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();

  String? _profileImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Fetches user profile data from Firebase Firestore.
  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _usernameCtrl.text = data['username'] ?? '';
          _nameCtrl.text = data['name'] ?? '';
          _bloodCtrl.text = data['blood_type'] ?? '';
          _weightCtrl.text = data['weight'] ?? '';
          _heightCtrl.text = data['height'] ?? '';
          _allergiesCtrl.text = data['allergies'] ?? '';
          _chronicCtrl.text = data['chronic_conditions'] ?? '';
          _profileImagePath = data['profile_image_path'];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  /// Opens device gallery to pick a profile image.
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("Image Picker Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cannot open gallery: $e')));
      }
    }
  }

  /// Saves updated profile data to Firebase Firestore.
  Future<void> _saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'username': _usernameCtrl.text.trim(),
            'name': _nameCtrl.text.trim(),
            'blood_type': _bloodCtrl.text,
            'weight': _weightCtrl.text,
            'height': _heightCtrl.text,
            'allergies': _allergiesCtrl.text,
            'chronic_conditions': _chronicCtrl.text,
            'profile_image_path': _profileImagePath ?? '',
          });

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    }
  }

  /// Signs out the current user and navigates to login.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  /// Main UI builder for the profile screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 15.0,
                left: 10.0,
                right: 10.0,
                bottom: 10.0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.support_agent,
                            color: textColor,
                            size: 28,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactUsPage(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                            size: 26,
                          ),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child:
                                  (_profileImagePath != null &&
                                      _profileImagePath!.isNotEmpty)
                                  ? Image.file(
                                      File(_profileImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.add_a_photo,
                                      color: textColor.withOpacity(0.5),
                                      size: 40,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to change photo',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),

                          _buildLabel('Username'),
                          _buildTextField(_usernameCtrl),
                          _buildLabel('Full Name'),
                          _buildTextField(_nameCtrl),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Blood Type'),
                                    _buildTextField(_bloodCtrl),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Weight (kg)'),
                                    _buildTextField(_weightCtrl),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Height (cm)'),
                                    _buildTextField(_heightCtrl),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _buildLabel('Allergies'),
                          _buildTextField(_allergiesCtrl, maxLines: 2),
                          _buildLabel('Chronic Conditions'),
                          _buildTextField(_chronicCtrl, maxLines: 2),

                          const SizedBox(height: 20),
                          Text(
                            'Your health information is safely stored on the cloud.',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: _saveProfile,
                            child: Container(
                              width: 150,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCA048),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.save,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  /// Helper to build form labels.
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 5),
    child: Text(
      text,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
  );

  /// Helper to build text input fields.
  Widget _buildTextField(TextEditingController c, {int maxLines = 1}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      );

  /// Builds the custom bottom navigation bar.
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bottomNavColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(context, Icons.add, 0, false),
          _navItem(context, Icons.medication_outlined, 1, false),
          _navItem(context, Icons.home, 2, false),
          _navItem(context, Icons.menu_book, 3, false),
          _navItem(context, Icons.person, 4, true),
        ],
      ),
    );
  }

  /// Individual navigation item helper.
  Widget _navItem(
    BuildContext context,
    IconData icon,
    int index,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/pill_description');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/stock');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/history');
          }
        },
        child: Container(
          color: Colors.transparent,
          height: 80,
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFCA048)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
