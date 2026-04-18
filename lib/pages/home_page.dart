import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../pill_sql.dart';
import '../notification.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;
  String _userName = "";
  String? _profileImagePath;

  List<Map<String, dynamic>> _myPills = [];
  bool _isLoading = true;
  double _progressValue = 0.0;

  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color cardColor = const Color(0xFFF6EFE6);
  final Color bottomNavColor = const Color(0xFF88C5C4);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _refreshHomePills();
  }

  // Fetches user profile data from Firestore
  Future<void> _fetchUserData() async {
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
            _userName = data['username']?.toString().trim() ?? '';
            _profileImagePath = data['profile_image_path'];
          });
        }
      }
    }
  }

  // Reloads the list of pills from the local database
  Future<void> _refreshHomePills() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 300));
    final data = await DatabaseHelper.instance.readAllPills();

    if (mounted) {
      setState(() {
        _myPills = data;
      });
      await _calculateProgress();
      setState(() => _isLoading = false);
    }
  }

  // Calculates the daily intake progress percentage
  Future<void> _calculateProgress() async {
    if (_myPills.isEmpty) {
      if (mounted) setState(() => _progressValue = 0.0);
      return;
    }

    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int totalValidPills = 0;
    int takenCount = 0;

    for (var pill in _myPills) {
      String createdAtStr = pill['created_at'] ?? '';
      bool isAddedLateToday = false;

      if (createdAtStr.isNotEmpty) {
        DateTime createdAt = DateTime.parse(createdAtStr);
        DateTime now = DateTime.now();
        String schedTimeStr = pill['scheduled_time'] ?? '08:00';
        List<String> tParts = schedTimeStr.split(':');

        DateTime schedToday = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(tParts[0]),
          int.parse(tParts[1]),
        );

        if (DateUtils.isSameDay(createdAt, now) &&
            createdAt.isAfter(schedToday)) {
          isAddedLateToday = true;
        }
      }

      if (!isAddedLateToday) {
        totalValidPills++;
        bool taken = await DatabaseHelper.instance.hasTakenPillToday(
          pill['id'],
          todayStr,
        );
        if (taken) takenCount++;
      }
    }

    if (mounted) {
      setState(() {
        _progressValue = totalValidPills == 0
            ? 0.0
            : takenCount / totalValidPills;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_myPills.isEmpty)
                      _buildEmptyState()
                    else
                      _buildMedicineList(),

                    const SizedBox(height: 40),
                    _buildProgressBar(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: textColor,
                  size: 28,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: Icon(Icons.alarm, color: textColor, size: 28),
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/time_setting',
                  );
                  if (result == true) {
                    _refreshHomePills();
                  }
                },
              ),
            ],
          ),
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  _userName.isEmpty ? 'Welcome' : 'Welcome back,\n$_userName',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      child: (_profileImagePath != null && _profileImagePath!.isNotEmpty)
          ? Image.file(File(_profileImagePath!), fit: BoxFit.cover)
          : Icon(Icons.person, color: textColor, size: 35),
    );
  }

  Widget _buildMedicineList() {
    return Column(
      children: [
        _buildTimeSection('Your Medications'),
        ..._myPills
            .map(
              (pill) => MedicineCard(
                pill: pill,
                onStatusChanged: () => _calculateProgress(),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_very_satisfied,
            size: 60,
            color: textColor.withOpacity(0.4),
          ),
          const SizedBox(height: 15),
          Text(
            "No medications scheduled for today.",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the '+' button below to get started.",
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CircularProgressIndicator(
                value: _progressValue,
                strokeWidth: 16,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF38CC00),
              ),
            ),
            Text(
              '${(_progressValue * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A3B24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'Your Progress Today',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF9E8E81),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(color: Color(0xFFDCD6D1), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bottomNavColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.add, 0),
          _buildNavItem(Icons.medication_outlined, 1),
          _buildNavItem(Icons.home, 2),
          _buildNavItem(Icons.menu_book_outlined, 3),
          _buildNavItem(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0)
            Navigator.pushReplacementNamed(context, '/pill_description');
          else if (index == 1)
            Navigator.pushReplacementNamed(context, '/stock');
          else if (index == 3)
            Navigator.pushReplacementNamed(context, '/history');
          else if (index == 4)
            Navigator.pushNamed(context, '/profile');
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

class MedicineCard extends StatefulWidget {
  final Map<String, dynamic> pill;
  final VoidCallback onStatusChanged;

  const MedicineCard({
    super.key,
    required this.pill,
    required this.onStatusChanged,
  });
  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  bool isTaken = false;
  bool isMissed = false;
  bool isAddedLate = false;
  bool isTakenLate = false;
  bool isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  // Evaluates and updates the real-time status of the pill
  Future<void> _checkStatus() async {
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DateTime now = DateTime.now();
    String schedTimeStr = widget.pill['scheduled_time'] ?? '08:00';
    List<String> tParts = schedTimeStr.split(':');
    DateTime schedTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(tParts[0]),
      int.parse(tParts[1]),
    );

    final db = await DatabaseHelper.instance.database;

    final takenRes = await db.query(
      'pill_history',
      where: 'pill_id = ? AND taken_date = ? AND status = ?',
      whereArgs: [widget.pill['id'], todayStr, 'Taken'],
    );
    bool taken = takenRes.isNotEmpty;
    bool lateTaken = false;

    if (taken) {
      String tkTimeStr = takenRes.first['taken_time'] as String;
      List<String> tkParts = tkTimeStr.split(':');
      DateTime tkTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(tkParts[0]),
        int.parse(tkParts[1]),
      );

      if (tkTime.isAfter(schedTime.add(const Duration(minutes: 15)))) {
        lateTaken = true;
      }
    }

    final missedRes = await db.query(
      'pill_history',
      where: 'pill_id = ? AND taken_date = ? AND status = ?',
      whereArgs: [widget.pill['id'], todayStr, 'Missed'],
    );
    bool missedInDB = missedRes.isNotEmpty;

    bool addedLate = false;
    String createdAtStr = widget.pill['created_at'] ?? '';
    if (createdAtStr.isNotEmpty) {
      DateTime createdAt = DateTime.parse(createdAtStr);
      if (DateUtils.isSameDay(createdAt, now) && createdAt.isAfter(schedTime)) {
        addedLate = true;
      }
    }

    bool autoMissed = false;
    if (!taken &&
        !missedInDB &&
        !addedLate &&
        now.difference(schedTime).inHours >= 2) {
      autoMissed = true;
      await DatabaseHelper.instance.insertHistoryLog({
        'pill_id': widget.pill['id'],
        'pill_name': widget.pill['name'],
        'taken_date': todayStr,
        'taken_time': DateFormat('HH:mm').format(now),
        'status': 'Missed',
      });
    }

    if (mounted) {
      setState(() {
        isTaken = taken;
        isTakenLate = lateTaken;
        isMissed = missedInDB || autoMissed;
        isAddedLate = addedLate;
        isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayTime = widget.pill['scheduled_time'] ?? '08:00';
    String? imagePath = widget.pill['image_path'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildLeading(imagePath),
        title: Text(
          widget.pill['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A3B24),
          ),
        ),
        subtitle: Text(
          'Scheduled: $displayTime',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: _buildTrailing(),
      ),
    );
  }

  Widget _buildLeading(String? imagePath) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: (imagePath != null && imagePath.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(imagePath), fit: BoxFit.cover),
            )
          : const Icon(Icons.medication, color: Colors.redAccent, size: 30),
    );
  }

  Widget _buildTrailing() {
    if (isChecking)
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    if (isAddedLate) return _statusTag('Added Late', Colors.grey.shade400);
    if (isMissed) return _statusTag('Missed', Colors.redAccent);

    return GestureDetector(
      onTap: () async {
        if (isTaken) return;

        DateTime now = DateTime.now();
        String schedTimeStr = widget.pill['scheduled_time'] ?? '08:00';
        List<String> tParts = schedTimeStr.split(':');
        DateTime schedTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(tParts[0]),
          int.parse(tParts[1]),
        );
        bool willBeLate = now.isAfter(
          schedTime.add(const Duration(minutes: 15)),
        );

        setState(() {
          isTaken = true;
          isTakenLate = willBeLate;
        });

        num currentAmount = widget.pill['amount'] ?? 0;
        String dosePref = widget.pill['dose'] ?? '1 pill';
        double doseToSubtract = 1.0;

        if (dosePref == '1/2 pills') {
          doseToSubtract = 0.5;
        } else if (dosePref == '2 pills') {
          doseToSubtract = 2.0;
        }

        if (currentAmount > 0) {
          num newAmount = currentAmount - doseToSubtract;
          if (newAmount < 0) newAmount = 0;
          await DatabaseHelper.instance.updatePillAmount(
            widget.pill['id'],
            newAmount,
          );

          String displayNewAmount = newAmount % 1 == 0
              ? newAmount.toInt().toString()
              : newAmount.toString();

          if (newAmount > 1 && newAmount <= 5) {
            NotificationHelper.showNotification(
              id: widget.pill['id'] + 1000,
              title: "⚠️ ยาใกล้หมดแล้ว!",
              body:
                  "ยาของคุณเหลือเพียง $displayNewAmount เม็ด อย่าลืมไปซื้อมาเติมนะ",
            );
          } else if (newAmount <= 1) {
            NotificationHelper.showNotification(
              id: widget.pill['id'] + 1000,
              title: "🚨 ยาหมดสต็อก!",
              body: "กรุณาเติมสต็อกยาเพื่อรักษาความต่อเนื่องในการกินยาครับ",
            );
          }
        }

        await DatabaseHelper.instance.insertHistoryLog({
          'pill_id': widget.pill['id'],
          'pill_name': widget.pill['name'],
          'taken_date': DateFormat('yyyy-MM-dd').format(now),
          'taken_time': DateFormat('HH:mm').format(now),
          'status': 'Taken',
        });

        DateTime temp = schedTime.add(const Duration(hours: 2));
        String missedTimeStr =
            "${temp.hour.toString().padLeft(2, '0')}:${temp.minute.toString().padLeft(2, '0')}";

        await NotificationHelper.scheduleMissedNotification(
          id: widget.pill['id'],
          title: "🚨 แจ้งเตือนลืมกินยา!",
          body:
              "คุณเลยเวลากินยา ${widget.pill['name']} มา 2 ชั่วโมงแล้ว รีบกินเลยครับ!",
          scheduledTime: missedTimeStr,
          skipToday: true,
        );

        widget.onStatusChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isTaken ? 95 : 28,
        height: 28,
        decoration: BoxDecoration(
          color: isTaken
              ? (isTakenLate
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF38CC00))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTaken ? Colors.transparent : Colors.grey.shade400,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: isTaken ? _doneLabel(isTakenLate) : null,
      ),
    );
  }

  Widget _statusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _doneLabel(bool late) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          late ? Icons.access_time : Icons.check,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          late ? 'Late' : 'Done',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
