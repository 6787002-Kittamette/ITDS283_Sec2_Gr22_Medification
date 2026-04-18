import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; 

// 🌟 ดึงไฟล์ระบบแจ้งเตือนมาใช้งาน
import 'notification.dart';

// 🌟 นำเข้าไฟล์หน้าต่างๆ ทั้งหมดในแอป
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/history_page.dart';
import 'pages/stock_page.dart';
import 'pages/pill_description.dart';
import 'pages/pill_image.dart';
import 'pages/pill_confirmation.dart';
import 'pages/pill_successful.dart';
import 'pages/time_setting_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase Connection
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Notification System Initialization
  await NotificationHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medification',
      theme: ThemeData(
        primaryColor: const Color(0xFF88C5C4), 
      ),
      
      // Auto Login
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      
      // Routing
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/history': (context) => const HistoryPage(),
        '/stock': (context) => const StockPage(),
        '/pill_description': (context) => const PillDescription(),
        '/pill_image': (context) => const PillImage(),
        '/pill_confirmation': (context) => const PillConfirmation(),
        '/pill_successful': (context) => const PillSuccessful(),
        '/time_setting': (context) => const TimeSettingPage(),
      },
    );
  }
}