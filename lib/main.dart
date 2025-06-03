import 'package:class_attendance_management_system/screens/history_screen.dart';
import 'package:class_attendance_management_system/screens/homework_screen.dart';
import 'package:class_attendance_management_system/screens/select_subject_class_screen.dart';
import 'package:class_attendance_management_system/screens/tuition_screen.dart';
import 'package:flutter/material.dart';
import 'package:class_attendance_management_system/screens/login_screen.dart';
import 'package:class_attendance_management_system/screens/menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final Color primaryBlue = const Color(0xFF00154C);

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Kanit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          surface: Colors.white,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: isLoggedIn ? MenuScreen() : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/menu': (context) => MenuScreen(),
        '/select-subject-class': (context) => SelectSubjectClassScreen(),
        '/history': (context) => HistoryScreen(),
        '/homework': (context) => HomeworkScreen(),
        '/tuition': (context) => TuitionScreen(),
        // '/select-subject': (context) => SelectSubjectScreen(),
        // Add others...
      },
    );
  }
}
