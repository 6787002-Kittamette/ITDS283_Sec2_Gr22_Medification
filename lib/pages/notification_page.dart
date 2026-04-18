import 'package:flutter/material.dart';
import '../pill_sql.dart';

/// Page for displaying medication and notification history.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

/// State management for NotificationPage.
class _NotificationPageState extends State<NotificationPage> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color cardColor = const Color(0xFFF6EFE6);
  final Color subTextColor = const Color(0xFF9E8E81);
  final Color dividerColor = const Color(0xFFE5DDD5);

  Map<String, List<Map<String, dynamic>>> _groupedLogs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotificationHistory();
  }

  /// Fetches logs from database and groups them by date.
  Future<void> _fetchNotificationHistory() async {
    final allLogs = await DatabaseHelper.instance.readAllHistory();
    Map<String, List<Map<String, dynamic>>> tempGroup = {};

    for (var log in allLogs) {
      String dateStr = log['taken_date'];
      if (tempGroup[dateStr] == null) {
        tempGroup[dateStr] = [];
      }
      tempGroup[dateStr]!.add(log);
    }

    setState(() {
      _groupedLogs = tempGroup;
      _isLoading = false;
    });
  }

  /// Main UI builder for the notification history screen.
  @override
  Widget build(BuildContext context) {
    List<String> sortedDates = _groupedLogs.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 10,
                right: 20,
                bottom: 20,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: subTextColor,
                        size: 18,
                      ),
                      label: Text(
                        'Home',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  Text(
                    'Notification History',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groupedLogs.isEmpty
                  ? Center(
                      child: Text(
                        "No history found.",
                        style: TextStyle(color: subTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        String date = sortedDates[index];
                        List<Map<String, dynamic>> logs = _groupedLogs[date]!;

                        final now = DateTime.now();
                        final todayStr =
                            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                        String displayDate = (date == todayStr)
                            ? 'Today'
                            : date;

                        List<Widget> logWidgets = [];
                        for (int i = 0; i < logs.length; i++) {
                          var log = logs[i];
                          bool showDivider = i != (logs.length - 1);
                          logWidgets.add(
                            _buildNotificationItem(
                              log['status'] == 'Taken' ? 'Consuming' : 'Missed',
                              log['pill_name'],
                              log['taken_time'],
                              showDivider: showDivider,
                              isRead: (date != todayStr),
                              isMissed: log['status'] == 'Missed',
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(displayDate),
                            _buildNotificationGroup(logWidgets),
                            const SizedBox(height: 25),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// UI component for the date section header.
  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        date,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Container for grouping notification items.
  Widget _buildNotificationGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  /// Individual notification item widget.
  Widget _buildNotificationItem(
    String title,
    String subtitle,
    String time, {
    required bool showDivider,
    bool isRead = false,
    bool isMissed = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isMissed ? Colors.redAccent : textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (!isRead)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),
              Text(
                time,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }
}
