import 'dart:io';
import 'package:flutter/material.dart';
import '../pill_sql.dart';
import '../notification.dart';
import 'pill_edit.dart';
import 'nearby_pharmacy_page.dart';

/// Screen for managing medication inventory and tracking stock levels.
class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

/// State management for the stock page.
class _StockPageState extends State<StockPage> {
  int _selectedIndex = 1;

  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color bottomNavColor = const Color(0xFF88C5C4);
  final Color accentColor = const Color(0xFFFCA048);

  List<Map<String, dynamic>> _pills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPills();
  }

  /// Fetches all stored medications from the local database.
  Future<void> _loadPills() async {
    setState(() => _isLoading = true);
    final pills = await DatabaseHelper.instance.readAllPills();
    setState(() {
      _pills = pills;
      _isLoading = false;
    });
  }

  /// Updates pill quantity and triggers low stock notifications if necessary.
  Future<void> _updateQuantity(int id, num currentAmount, num change) async {
    num newAmount = currentAmount + change;
    if (newAmount < 0) newAmount = 0;

    await DatabaseHelper.instance.updatePillAmount(id, newAmount);

    String displayNewAmount = newAmount % 1 == 0
        ? newAmount.toInt().toString()
        : newAmount.toString();

    if (newAmount > 1 && newAmount <= 5 && change < 0) {
      NotificationHelper.showNotification(
        id: id + 1000,
        title: "⚠️ ยาใกล้หมดแล้ว!",
        body: "ยาของคุณเหลือเพียง $displayNewAmount เม็ด อย่าลืมไปซื้อมาเติมนะ",
      );
    } else if (newAmount <= 1 && change < 0) {
      NotificationHelper.showNotification(
        id: id + 1000,
        title: "🚨 ยาหมดสต็อก!",
        body: "กรุณาเติมสต็อกยาเพื่อรักษาความต่อเนื่องในการกินยาครับ",
      );
    }

    _loadPills();
  }

  /// Prompts for confirmation and deletes a pill record.
  Future<void> _deletePill(int id, String? imagePath) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pill'),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deletePill(id);
      await NotificationHelper.cancelNotification(id);
      _loadPills();
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
                      'My Stock',
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
                            Icons.storefront,
                            color: textColor,
                            size: 28,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NearbyPharmacyPage(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.alarm, color: textColor, size: 28),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/time_setting'),
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
                  : _pills.isEmpty
                  ? const Center(child: Text("Your stock is empty."))
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            mainAxisExtent: 230,
                          ),
                      itemCount: _pills.length,
                      itemBuilder: (context, index) {
                        var pill = _pills[index];
                        return _buildPillCard(pill);
                      },
                    ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  /// Builds an individual medication card with quantity controls.
  Widget _buildPillCard(Map<String, dynamic> pill) {
    num amount = pill['amount'] ?? 0;
    String displayAmount = amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toString();
    String? imagePath = pill['image_path'];
    Color statusColor = amount <= 1
        ? const Color(0xFFFF4C4C)
        : (amount <= 5 ? const Color(0xFFFFDE33) : const Color(0xFF38CC00));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            height: 75,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: (imagePath != null && imagePath.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(File(imagePath), fit: BoxFit.cover),
                  )
                : const Icon(
                    Icons.medication,
                    color: Colors.redAccent,
                    size: 40,
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            pill['name'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleBtn(
                Icons.remove,
                () => _updateQuantity(pill['id'], amount, -1),
              ),
              const SizedBox(width: 10),
              Text(
                displayAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 10),
              _circleBtn(
                Icons.add,
                () => _updateQuantity(pill['id'], amount, 1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionBtn(Icons.edit, () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PillEdit(pill: pill)),
                );
                if (result == true) _loadPills();
              }),
              const SizedBox(width: 10),
              _actionBtn(
                Icons.delete_outline,
                () => _deletePill(pill['id'], imagePath),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper for quantity adjustment buttons.
  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.grey, size: 24),
    ),
  );

  /// Helper for edit and delete action buttons.
  Widget _actionBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );

  /// Builds the custom bottom navigation bar.
  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bottomNavColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.add, 0),
          _navItem(Icons.medication_outlined, 1),
          _navItem(Icons.home, 2),
          _navItem(Icons.menu_book, 3),
          _navItem(Icons.person_outline, 4),
        ],
      ),
    );
  }

  /// Individual navigation item helper.
  Widget _navItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0)
            Navigator.pushReplacementNamed(context, '/pill_description');
          else if (index == 2)
            Navigator.pushReplacementNamed(context, '/home');
          else if (index == 3)
            Navigator.pushReplacementNamed(context, '/history');
          else if (index == 4)
            Navigator.pushNamed(context, '/profile');
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
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
