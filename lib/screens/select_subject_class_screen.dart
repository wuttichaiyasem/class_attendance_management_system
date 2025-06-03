import 'package:class_attendance_management_system/screens/subject_detail_screen.dart';
import 'package:class_attendance_management_system/services/subject_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectSubjectClassScreen extends StatefulWidget {
  const SelectSubjectClassScreen({super.key});

  @override
  State<SelectSubjectClassScreen> createState() =>
      _SelectSubjectClassScreenState();
}

class _SelectSubjectClassScreenState extends State<SelectSubjectClassScreen> {
  List<Map<String, dynamic>> yearData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      print('Token: $token');

      if (token == null) throw Exception('No token found');

      final data = await SubjectService.getMySubjects(token);
      setState(() {
        yearData = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching subjects: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3F3F3),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xff00154C),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(200, 100),
              ),
            ),
            padding: const EdgeInsets.only(top: 80, bottom: 50),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'เช็คชื่อนักศึกษา',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'เลือกรายวิชา / ห้องเรียน',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 5,
                  top: -15,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: yearData.length,
                    itemBuilder: (context, index) {
                      final year = yearData[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      year['year'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 8),
                                      height: 0.5,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ],
                                ),
                                children: [
                                  ...year['subjects'].map<Widget>((subject) {
                                    String subjectTitle ='${subject['subject_name']} กลุ่มที่ ${subject['group']}';
                                    String date =subject['date_this_week'] ?? 'ไม่ระบุ';
                                    String time = subject['time'] ?? 'ไม่ระบุ';
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left:10.0),
                                          child: ListTile(
                                            tileColor: Colors.white,
                                            title: Text(
                                              subjectTitle,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            dense: true,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SubjectDetailScreen(
                                                        classId: subject['class_id'],
                                                        subjectName: subjectTitle,
                                                        date: date,
                                                        time: time,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 24),
                                          height: 0.5,
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
