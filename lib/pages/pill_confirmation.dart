import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pill_sql.dart';
import '../notification.dart';

/// Screen for confirming and editing medication details before saving.
class PillConfirmation extends StatefulWidget {
  const PillConfirmation({super.key});

  @override
  State<PillConfirmation> createState() => _PillConfirmationState();
}

/// State management for medication confirmation and data parsing.
class _PillConfirmationState extends State<PillConfirmation> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color accentColor = const Color(0xFFFCA048);
  final Color cardColor = const Color(0xFFF6EFE6);

  final _nameCtrl = TextEditingController();
  final _useCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '30');
  final _noteCtrl = TextEditingController();

  String timePref1 = 'Before';
  String timePref2 = 'Breakfast';
  String dosePref = '1 pill';

  bool _isDataLoaded = false;
  String? _descImagePath;
  String? _pillImagePath;

  String _breakfastTime = '08:00';
  String _lunchTime = '12:00';
  String _dinnerTime = '19:00';

  @override
  void initState() {
    super.initState();
    _fetchUserMealTimes();
  }

  /// Fetches meal time preferences from Firebase Firestore.
  Future<void> _fetchUserMealTimes() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _breakfastTime = data['meal_breakfast'] ?? '08:00';
            _lunchTime = data['meal_lunch'] ?? '12:00';
            _dinnerTime = data['meal_dinner'] ?? '19:00';
          });
        }
      }
    }
  }

  /// Extracts medication name and quantity from scanned text.
  void _parseScannedText(String text) {
    if (text.isEmpty) return;
    List<String> lines = text.split('\n');
    if (lines.isNotEmpty) _nameCtrl.text = lines.first.trim();
    RegExp qtyRegex = RegExp(
      r'(\d+)\s*(pills|tabs|capsules|เม็ด)',
      caseSensitive: false,
    );
    var qtyMatch = qtyRegex.firstMatch(text);
    if (qtyMatch != null) _qtyCtrl.text = qtyMatch.group(1) ?? '30';
    if (lines.length > 1)
      _useCtrl.text = lines.sublist(1).join('\n').trim();
    else
      _useCtrl.text = text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _parseScannedText(args['text'] ?? '');
        _descImagePath = args['descImagePath'];
        _pillImagePath = args['pillImagePath'];
      }
      _isDataLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.alarm, color: textColor, size: 28),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/time_setting'),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Confirmation',
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
                          _buildImgRow(),
                          _buildLabel('Medicine Name'),
                          _buildTextField(_nameCtrl),
                          _buildLabel('Description'),
                          _buildTextField(_useCtrl, maxLines: 3),
                          _buildLabel('Time'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(timePref1, [
                                  'Before',
                                  'After',
                                ], (v) => setState(() => timePref1 = v!)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdown(timePref2, [
                                  'Breakfast',
                                  'Lunch',
                                  'Dinner',
                                ], (v) => setState(() => timePref2 = v!)),
                              ),
                            ],
                          ),
                          _buildLabel('Dose'),
                          _buildDropdown(dosePref, [
                            '1/2 pills',
                            '1 pill',
                            '2 pills',
                          ], (v) => setState(() => dosePref = v!)),
                          _buildLabel('Quantity'),
                          _buildTextField(_qtyCtrl, isNum: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    GestureDetector(
                      onTap: _savePill,
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

  /// Calculates scheduled times and saves pill data with notifications.
  Future<void> _savePill() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _useCtrl.text.trim().isEmpty ||
        _qtyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all details before confirming.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String baseTime = timePref2 == 'Breakfast'
        ? _breakfastTime
        : (timePref2 == 'Lunch' ? _lunchTime : _dinnerTime);
    List<String> parts = baseTime.split(':');
    DateTime mealDate = DateTime(
      2026,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (timePref1 == 'Before')
      mealDate = mealDate.subtract(const Duration(minutes: 30));
    else if (timePref1 == 'After')
      mealDate = mealDate.add(const Duration(minutes: 30));

    String finalTime =
        "${mealDate.hour.toString().padLeft(2, '0')}:${mealDate.minute.toString().padLeft(2, '0')}";

    Map<String, dynamic> newPill = {
      'name': _nameCtrl.text,
      'description': _useCtrl.text,
      'amount': double.tryParse(_qtyCtrl.text) ?? 0.0,
      'scheduled_time': finalTime,
      'created_at': DateTime.now().toIso8601String(),
      'image_path': _pillImagePath ?? _descImagePath ?? '',
      'meal_type': timePref2,
      'timing_type': timePref1,
      'dose': dosePref,
    };

    int pillId = await DatabaseHelper.instance.insertPill(newPill);

    /// Schedules daily reminder notification.
    await NotificationHelper.scheduleDailyNotification(
      id: pillId,
      title: "ถึงเวลากินยาแล้ว! 💊",
      body: "ได้เวลากินยา ${_nameCtrl.text}",
      scheduledTime: finalTime,
    );

    /// Schedules missed dose notification (2 hours later).
    DateTime tempMissed = mealDate.add(const Duration(hours: 2));
    String missedTimeStr =
        "${tempMissed.hour.toString().padLeft(2, '0')}:${tempMissed.minute.toString().padLeft(2, '0')}";
    await NotificationHelper.scheduleMissedNotification(
      id: pillId,
      title: "🚨 แจ้งเตือนลืมกินยา!",
      body: "คุณเลยเวลากินยา ${_nameCtrl.text} มา 2 ชั่วโมงแล้ว รีบกินเลยครับ!",
      scheduledTime: missedTimeStr,
    );

    if (mounted) Navigator.pushNamed(context, '/pill_successful');
  }

  /// Helper to build medication and prescription images row.
  Widget _buildImgRow() => Row(
    children: [
      Expanded(
        child: Container(
          height: 100,
          color: Colors.grey.shade300,
          child: _descImagePath != null
              ? Image.file(File(_descImagePath!), fit: BoxFit.cover)
              : const Icon(Icons.receipt_long),
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Container(
          height: 100,
          color: Colors.grey.shade300,
          child: _pillImagePath != null
              ? Image.file(File(_pillImagePath!), fit: BoxFit.cover)
              : const Icon(Icons.medication),
        ),
      ),
    ],
  );

  /// Helper to build form labels.
  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 5),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  /// Helper to build text input fields.
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

  /// Helper to build dropdown menus.
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
