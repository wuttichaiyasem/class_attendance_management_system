import 'package:class_attendance_management_system/screens/menu_screen.dart';
import 'package:class_attendance_management_system/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();
  final ePassportLogin _ePassportLogin = ePassportLogin();

  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอก e-Passport'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } else if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอก Password'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final response = await _ePassportLogin.login(username, password);

      if (response['status'] == 'ok') {
        print(response['username']);
        print(response['name']);
        print(response['email']);

        final backendResponse = await _apiService.saveUser(
          response['username'],
          response['name'],
          response['email'],
        );

        // 👇 ดึง token ที่ backend ส่งกลับมา
        final token = backendResponse['token'];

        // ✅ เก็บ token ลง SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', response['username']);
        await prefs.setString('jwt_token', token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MenuScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login สำเร็จ'),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('e-Passprot หรือ Password ไม่ถูกต้อง'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      print('Login failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('e-Passprot หรือ Password ไม่ถูกต้อง'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xffF3F3F3),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.elliptical(200, 120),
                  ),
                  color: Color(0xff00154C),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 160, bottom: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'เข้าสู่ระบบ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Username',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade500,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Password',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade500,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffF9CA10),
                        elevation: 2,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30), // slightly more rounded
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 36, vertical: 12), // a bit larger
                      ),
                      child: Text(
                        'ตกลง',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
            ],
          ),
        ));
  }
}
