import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final gridItems = [
      {
        'label': 'เพิ่มอาจารย์',
        'image': 'assets/icons/add_teacher.png',
        'route': '/admin_add_teacher'
      },
      {
        'label': 'เพิ่มนักศึกษา',
        'image': 'assets/icons/add_student.png',
        'route': '/admin_add_student'
      },
      {
        'label': 'เพิ่มรายวิชา',
        'image': 'assets/icons/add_subject.png',
        'route': '/admin_add_subject'
      },
      {
        'label': 'การบ้าน',
        'image': 'assets/icons/homework.png',
        'route': '/admin_homework'
      },
      {
        'label': 'ประวัติการเช็คชื่อ',
        'image': 'assets/icons/history.png',
        'route': '/admin_history'
      },
      {
        'label': 'ค่าเทอม',
        'image': 'assets/icons/tuition.png',
        'route': '/admin_tuition'
      },
      {
        'label': 'ตารางสอน',
        'image': 'assets/icons/schedule.png',
        'route': '/admin_schedule'
      },
      {
        'label': 'สรุป',
        'image': 'assets/icons/research.png',
        'route': '/admin_summarize_menu'
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xffF3F3F3),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 220),
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 16,
                      runSpacing: 38,
                      children: gridItems.map((item) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, item['route']!);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2 - 24,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Image.asset(
                                      item['image'] ?? '',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Color(0xff00154C),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(16),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: Text(
                                        item['label'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(200, 100),
              ),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 2),
                  color: Colors.black38,
                  blurRadius: 8,
                ),
              ],
              color: Color(0xff00154C),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 90, bottom: 50),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'จัดการข้อมูล',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -15,
                    right: 5,
                    child: IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('jwt_token');

                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (route) => false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
