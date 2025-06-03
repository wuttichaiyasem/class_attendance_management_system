import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gridItems = [
      {
        'label': 'เช็คชื่อนักศึกษา',
        'image': 'assets/icons/check_student.png',
        'route': '/select-subject-class'
      },
      {
        'label': 'ประวัติการเช็คชื่อ',
        'image': 'assets/icons/history.png',
        'route': '/history'
      },
      {
        'label': 'การบ้าน',
        'image': 'assets/icons/homework.png',
        'route': '/homework'
      },
      {
        'label': 'ค่าเทอม',
        'image': 'assets/icons/tuition.png',
        'route': '/tuition'
      },
    ];

    return Scaffold(
        backgroundColor: Color(0xffF3F3F3),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
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
                            'เมนู',
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
            const SizedBox(height: 30),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              itemCount: gridItems.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 38,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final item = gridItems[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, item['route']!);
                  },
                  child: Container(
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
                              item['image'] ??
                                  '', // use asset path like 'assets/icons/check_icon.png'
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
              },
            ),
            const SizedBox(height: 20),
          ],
        ));
  }
}
