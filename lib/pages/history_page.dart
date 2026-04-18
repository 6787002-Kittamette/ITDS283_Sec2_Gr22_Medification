import 'package:flutter/material.dart';
import '../pill_sql.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedIndex = 3;

  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color bottomNavColor = const Color(0xFF88C5C4);
  final Color greenColor = const Color(0xFF38CC00);
  final Color redColor = const Color(0xFFFF4C4C);

  DateTime _currentMonth = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _groupedLogs = {};
  bool _isLoading = true;
  bool _isWeekView = true;

  double _thisWeekProgress = 0.0;
  double _lastWeekProgress = 0.0;
  double _thisMonthProgress = 0.0;
  double _lastMonthProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchHistoryLogs();
  }

  // Fetches and groups history logs
  Future<void> _fetchHistoryLogs() async {
    setState(() => _isLoading = true);

    final allLogs = await DatabaseHelper.instance.readAllHistory();
    Map<String, List<Map<String, dynamic>>> tempGroup = {};

    int totalThisWeek = 0, takenThisWeek = 0;
    int totalLastWeek = 0, takenLastWeek = 0;
    int totalThisMonth = 0, takenThisMonth = 0;
    int totalLastMonth = 0, takenLastMonth = 0;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime startOfThisWeek = today.subtract(
      Duration(days: today.weekday - 1),
    );
    DateTime endOfThisWeek = startOfThisWeek.add(const Duration(days: 6));
    DateTime startOfLastWeek = startOfThisWeek.subtract(
      const Duration(days: 7),
    );
    DateTime endOfLastWeek = startOfThisWeek.subtract(const Duration(days: 1));

    for (var log in allLogs) {
      String dateStr = log['taken_date'];
      if (tempGroup[dateStr] == null) tempGroup[dateStr] = [];
      tempGroup[dateStr]!.add(log);

      DateTime logDate = DateTime.parse(dateStr);
      bool isTaken = log['status'] == 'Taken';

      if (!logDate.isBefore(startOfThisWeek) &&
          !logDate.isAfter(endOfThisWeek)) {
        totalThisWeek++;
        if (isTaken) takenThisWeek++;
      } else if (!logDate.isBefore(startOfLastWeek) &&
          !logDate.isAfter(endOfLastWeek)) {
        totalLastWeek++;
        if (isTaken) takenLastWeek++;
      }

      if (logDate.year == now.year && logDate.month == now.month) {
        totalThisMonth++;
        if (isTaken) takenThisMonth++;
      } else if ((logDate.year == now.year && logDate.month == now.month - 1) ||
          (now.month == 1 &&
              logDate.year == now.year - 1 &&
              logDate.month == 12)) {
        totalLastMonth++;
        if (isTaken) takenLastMonth++;
      }
    }

    setState(() {
      _groupedLogs = tempGroup;

      _thisWeekProgress = totalThisWeek > 0
          ? (takenThisWeek / totalThisWeek)
          : 0.0;
      _lastWeekProgress = totalLastWeek > 0
          ? (takenLastWeek / totalLastWeek)
          : 0.0;
      _thisMonthProgress = totalThisMonth > 0
          ? (takenThisMonth / totalThisMonth)
          : 0.0;
      _lastMonthProgress = totalLastMonth > 0
          ? (takenLastMonth / totalLastMonth)
          : 0.0;

      _isLoading = false;
    });
  }

  String _formatDateString(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Builds the calendar view
  Widget _buildCalendar() {
    DateTime firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    int firstWeekday = firstDayOfMonth.weekday;
    int offset = firstWeekday % 7;

    int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    int totalCells = offset + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < offset) return const SizedBox.shrink();

        int day = index - offset + 1;
        DateTime currentDate = DateTime(
          _currentMonth.year,
          _currentMonth.month,
          day,
        );
        String dateStr = _formatDateString(currentDate);

        List<Map<String, dynamic>> logs = _groupedLogs[dateStr] ?? [];
        bool hasHistory = logs.isNotEmpty;
        bool hasMissed = logs.any((log) => log['status'] == 'Missed');

        Color dotColor = Colors.transparent;
        if (hasHistory) {
          dotColor = hasMissed ? redColor : greenColor;
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String leftLabel = _isWeekView ? 'Last Week' : 'Last Month';
    String rightLabel = _isWeekView ? 'Next Week' : 'Next Month';
    double leftProgress = _isWeekView ? _lastWeekProgress : _lastMonthProgress;
    double centerProgress = _isWeekView
        ? _thisWeekProgress
        : _thisMonthProgress;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 28),
                  Text(
                    'My record',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.alarm, color: textColor, size: 28),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'S',
                    style: TextStyle(
                      color: redColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'M',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'T',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'W',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'TH',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'F',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'S',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCalendar(),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBE6DF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isWeekView = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: _isWeekView
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  color: _isWeekView ? textColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                child: const Text('Week'),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isWeekView = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: !_isWeekView
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  color: !_isWeekView
                                      ? textColor
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                child: const Text('Month'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              leftLabel,
                              key: ValueKey<String>(leftLabel),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: leftProgress),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 8,
                                      backgroundColor: const Color(0xFFF2FBFA),
                                      color: leftProgress > 0
                                          ? redColor
                                          : Colors.transparent,
                                    ),
                                  ),
                                  if (leftProgress > 0)
                                    Text(
                                      '${(value * 100).toInt()}%',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),

                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: centerProgress),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 15,
                                  backgroundColor: const Color(0xFFF2FBFA),
                                  color: greenColor,
                                ),
                              ),
                              Text(
                                '${(value * 100).toInt()}%',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              rightLabel,
                              key: ValueKey<String>(rightLabel),
                              style: const TextStyle(
                                color: Color(0xFF88C5C4),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 0.0,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFFF2FBFA),
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              height: 80,
              decoration: BoxDecoration(color: bottomNavColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.add, 0),
                  _buildNavItem(Icons.medication_outlined, 1),
                  _buildNavItem(Icons.home, 2),
                  _buildNavItem(Icons.menu_book, 3),
                  _buildNavItem(Icons.person_outline, 4),
                ],
              ),
            ),
          ],
        ),
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
          else if (index == 2)
            Navigator.pushReplacementNamed(context, '/home');
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
