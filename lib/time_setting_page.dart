import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../pill_sql.dart';
import '../notification.dart';

/// Screen for configuring default meal times.
class TimeSettingPage extends StatefulWidget {
  const TimeSettingPage({super.key});

  @override
  State<TimeSettingPage> createState() => _TimeSettingPageState();
}

/// State management for user meal times and schedule synchronization.
class _TimeSettingPageState extends State<TimeSettingPage> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color cardColor = const Color(0xFFF6EFE6);
  final Color accentColor = const Color(0xFFFCA048);

  String breakfastHour = '08';
  String breakfastMinute = '00';
  String lunchHour = '12';
  String lunchMinute = '00';
  String dinnerHour = '19';
  String dinnerMinute = '00';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealTimes();
  }

  /// Fetches meal time preferences from Firebase Firestore.
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
          List<String> b = (data['meal_breakfast'] ?? '08:00').split(':');
          breakfastHour = b[0];
          breakfastMinute = b[1];

          List<String> l = (data['meal_lunch'] ?? '12:00').split(':');
          lunchHour = l[0];
          lunchMinute = l[1];

          List<String> d = (data['meal_dinner'] ?? '19:00').split(':');
          dinnerHour = d[0];
          dinnerMinute = d[1];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  /// Updates meal times in Firestore and recalculates all local pill schedules.
  Future<void> _saveMealTimes() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);

      String bTime = "$breakfastHour:$breakfastMinute";
      String lTime = "$lunchHour:$lunchMinute";
      String dTime = "$dinnerHour:$dinnerMinute";

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'meal_breakfast': bTime, 'meal_lunch': lTime, 'meal_dinner': dTime},
      );

      final allPills = await DatabaseHelper.instance.readAllPills();

      for (var pill in allPills) {
        String? mType = pill['meal_type'];
        String? tType = pill['timing_type'];

        if (mType == null || tType == null) continue;

        String baseTime = (mType == 'Breakfast')
            ? bTime
            : (mType == 'Lunch' ? lTime : dTime);

        DateTime mealDate = DateFormat("HH:mm").parse(baseTime);
        if (tType == 'Before') {
          mealDate = mealDate.subtract(const Duration(minutes: 30));
        } else if (tType == 'After') {
          mealDate = mealDate.add(const Duration(minutes: 30));
        }

        String newScheduledTime = DateFormat("HH:mm").format(mealDate);

        await DatabaseHelper.instance.updatePillTime(
          pill['id'],
          newScheduledTime,
        );

        await NotificationHelper.cancelNotification(pill['id']);
        await NotificationHelper.scheduleDailyNotification(
          id: pill['id'],
          title: "ถึงเวลากินยาแล้ว! 💊",
          body: "ได้เวลากินยา ${pill['name']}",
          scheduledTime: newScheduledTime,
        );
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal times and medication schedules updated!'),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 15,
                      left: 15,
                      bottom: 10,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Text(
                    'Meal Time Setting',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [
                          _buildMealCard(
                            'Breakfast',
                            breakfastHour,
                            breakfastMinute,
                            (v) => breakfastHour = v,
                            (v) => breakfastMinute = v,
                          ),
                          const SizedBox(height: 20),
                          _buildMealCard(
                            'Lunch',
                            lunchHour,
                            lunchMinute,
                            (v) => lunchHour = v,
                            (v) => lunchMinute = v,
                          ),
                          const SizedBox(height: 20),
                          _buildMealCard(
                            'Dinner',
                            dinnerHour,
                            dinnerMinute,
                            (v) => dinnerHour = v,
                            (v) => dinnerMinute = v,
                          ),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: _saveMealTimes,
                            child: Container(
                              width: 150,
                              height: 50,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Helper to build time selection cards for each meal.
  Widget _buildMealCard(
    String title,
    String hValue,
    String mValue,
    Function(String) onHChanged,
    Function(String) onMChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildTimeDropdown('Hour', hValue, 24, onHChanged),
              const SizedBox(width: 20),
              _buildTimeDropdown('Minute', mValue, 60, onMChanged),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build hour and minute dropdown menus.
  Widget _buildTimeDropdown(
    String label,
    String currentVal,
    int max,
    Function(String) onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 12)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentVal,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: textColor),
                items:
                    List.generate(
                          max,
                          (index) => index.toString().padLeft(2, '0'),
                        )
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => onChanged(val));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
