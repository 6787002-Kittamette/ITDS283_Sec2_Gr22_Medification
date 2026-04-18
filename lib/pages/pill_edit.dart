import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pill_sql.dart';
import '../notification.dart';

class PillEdit extends StatefulWidget {
  final Map<String, dynamic> pill;

  const PillEdit({super.key, required this.pill});

  @override
  State<PillEdit> createState() => _PillEditState();
}

class _PillEditState extends State<PillEdit> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color cardColor = const Color(0xFFF6EFE6);
  final Color accentColor = const Color(0xFFFCA048);

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;

  String _selectedTiming = 'Before';
  String _selectedMeal = 'Breakfast';

  String _bTime = '08:00';
  String _lTime = '12:00';
  String _dTime = '19:00';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pill['name']);
    _descCtrl = TextEditingController(text: widget.pill['description'] ?? '');
    _amountCtrl = TextEditingController(text: widget.pill['amount'].toString());

    _selectedMeal = widget.pill['meal_type'] ?? 'Breakfast';
    _selectedTiming = widget.pill['timing_type'] ?? 'Before';

    if (!['Breakfast', 'Lunch', 'Dinner'].contains(_selectedMeal)) {
      _selectedMeal = 'Breakfast';
    }
    if (!['Before', 'After'].contains(_selectedTiming)) {
      _selectedTiming = 'Before';
    }

    _loadMealTimes();
  }

  // Fetches user meal time preferences
  Future<void> _loadMealTimes() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _bTime = data['meal_breakfast'] ?? '08:00';
          _lTime = data['meal_lunch'] ?? '12:00';
          _dTime = data['meal_dinner'] ?? '19:00';
        });
      }
    }
    setState(() => _isLoading = false);
  }

  // Parses and calculates scheduled time
  String _calculateScheduledTime() {
    String baseTime = _selectedMeal == 'Breakfast'
        ? _bTime
        : (_selectedMeal == 'Lunch' ? _lTime : _dTime);
    List<String> parts = baseTime.split(':');
    DateTime mealTime = DateTime(
      2026,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (_selectedTiming == 'Before') {
      mealTime = mealTime.subtract(const Duration(minutes: 30));
    } else if (_selectedTiming == 'After') {
      mealTime = mealTime.add(const Duration(minutes: 30));
    }
    return "${mealTime.hour.toString().padLeft(2, '0')}:${mealTime.minute.toString().padLeft(2, '0')}";
  }

  // Updates the pill record in database and reschedules notifications
  Future<void> _updatePill() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all details before updating.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    String finalTime = _calculateScheduledTime();

    Map<String, dynamic> updatedData = {
      'id': widget.pill['id'],
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'amount': int.tryParse(_amountCtrl.text) ?? 0,
      'scheduled_time': finalTime,
      'image_path': widget.pill['image_path'],
      'meal_type': _selectedMeal,
      'timing_type': _selectedTiming,
    };

    await DatabaseHelper.instance.updatePill(updatedData);

    await NotificationHelper.cancelNotification(widget.pill['id']);
    await NotificationHelper.scheduleDailyNotification(
      id: widget.pill['id'],
      title: "ถึงเวลากินยาแล้ว! 💊",
      body: "ได้เวลากินยา ${_nameCtrl.text}",
      scheduledTime: finalTime,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: textColor,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
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
                        children: [
                          Text(
                            'Edit Medication',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildImgPreview(widget.pill['image_path']),
                                _buildLabel('Medicine Name'),
                                _buildTextField(_nameCtrl),
                                _buildLabel('Description'),
                                _buildTextField(_descCtrl, maxLines: 3),
                                _buildLabel('Time'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdown(
                                        _selectedTiming,
                                        ['Before', 'After'],
                                        (v) => setState(
                                          () => _selectedTiming = v!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildDropdown(
                                        _selectedMeal,
                                        ['Breakfast', 'Lunch', 'Dinner'],
                                        (v) =>
                                            setState(() => _selectedMeal = v!),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildLabel('Quantity'),
                                _buildTextField(_amountCtrl, isNum: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          GestureDetector(
                            onTap: _updatePill,
                            child: Container(
                              width: 150,
                              height: 50,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFF5A3B24),
                                size: 35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImgPreview(String? path) {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: (path != null && path.isNotEmpty)
          ? Image.file(File(path), fit: BoxFit.cover)
          : const Icon(Icons.medication),
    );
  }

  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 5),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(
    TextEditingController c, {
    int maxLines = 1,
    bool isNum = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: const InputDecoration(border: InputBorder.none),
    ),
  );

  Widget _buildDropdown(
    String v,
    List<String> items,
    Function(String?) onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: v,
        isExpanded: true,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
