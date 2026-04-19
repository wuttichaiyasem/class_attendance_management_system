import 'package:class_attendance_management_system/screens/admin_add_student_screen.dart';
import 'package:class_attendance_management_system/screens/admin_add_subject_screen.dart';
import 'package:class_attendance_management_system/screens/admin_add_teacher_screen.dart';
import 'package:class_attendance_management_system/screens/admin_history_screen.dart';
import 'package:class_attendance_management_system/screens/admin_homework_screen.dart';
import 'package:class_attendance_management_system/screens/admin_menu_screen.dart';
import 'package:class_attendance_management_system/screens/admin_schedule_screen.dart';
import 'package:class_attendance_management_system/screens/admin_summarize_menu_screen.dart';
import 'package:class_attendance_management_system/screens/admin_tuition_screen.dart';
import 'package:class_attendance_management_system/screens/advisor_screen.dart';
import 'package:class_attendance_management_system/screens/history_screen.dart';
import 'package:class_attendance_management_system/screens/homework_screen.dart';
import 'package:class_attendance_management_system/screens/schedule_screen.dart';
import 'package:class_attendance_management_system/screens/select_subject_class_screen.dart';
import 'package:class_attendance_management_system/screens/student_menu_screen.dart';
import 'package:class_attendance_management_system/screens/tuition_screen.dart';
import 'package:flutter/material.dart';
import 'package:class_attendance_management_system/screens/login_screen.dart';
import 'package:class_attendance_management_system/screens/menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final role = prefs.getInt('role');

  bool isLoggedIn = false;

  if (token != null && token.isNotEmpty) {
    bool isExpired = JwtDecoder.isExpired(token);

    if (!isExpired) {
      isLoggedIn = true;
    } else {
      await prefs.remove('jwt_token');
      await prefs.remove('role');
    }
  }

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    role: role,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int? role;
  final Color primaryBlue = const Color(0xFF00154C);

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    Widget homeScreen;

    if (!isLoggedIn) {
      homeScreen = LoginScreen();
    } else {
      switch (role) {
        case 1:
          homeScreen = AdminMenuScreen();
          break;

        case 2:
          homeScreen = MenuScreen();
          break;

        case 4:
          homeScreen = StudentMenuScreen();
          break;

        default:
          homeScreen = LoginScreen();
      }
    }
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
      home: homeScreen,
      routes: {
        '/login': (context) => LoginScreen(),
        '/menu': (context) => MenuScreen(),
        '/select-subject-class': (context) => SelectSubjectClassScreen(),
        '/history': (context) => HistoryScreen(),
        '/homework': (context) => HomeworkScreen(),
        '/tuition': (context) => TuitionScreen(),
        '/advisor': (context) => AdvisorScreen(),
        '/schedule': (context) => ScheduleScreen(),
        '/admin_add_teacher': (context) => AdminAddTeacherScreen(),
        '/admin_add_student': (context) => AdminAddStudentScreen(),
        '/admin_add_subject': (context) => AdminAddSubjectScreen(),
        '/admin_tuition': (context) => AdminTuitionScreen(),
        '/admin_history': (context) => AdminHistoryScreen(),
        '/admin_homework': (context) => AdminHomeworkScreen(),
        '/admin_schedule': (context) => AdminScheduleScreen(),
        '/admin_summarize_menu': (context) => AdminSummarizeMenuScreen(),
        // '/select-subject': (context) => SelectSubjectScreen(),
        // Add others...
      },
    );
  }
}
