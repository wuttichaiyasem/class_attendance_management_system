import 'package:auto_size_text/auto_size_text.dart';
import 'package:class_attendance_management_system/services/tuition_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TuitionScreen extends StatefulWidget {
  const TuitionScreen({super.key});

  @override
  State<TuitionScreen> createState() => _TuitionScreenState();
}

class _TuitionScreenState extends State<TuitionScreen> {
  String selectedStatus = 'ทั้งหมด';

  List<String> status = ['ทั้งหมด', 'จ่ายแล้ว', 'ยังไม่จ่าย'];

  final Map<String, Color> statusColors = {
    'จ่ายแล้ว': Color(0xff57BC40),
    'ยังไม่จ่าย': Color(0xffE94C30),
  };

  List<Map<String, String>> students = [];

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  @override
  void initState() {
    super.initState();
    fetchTuitionData();
  }

  Future<void> fetchTuitionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      print('Token: $token');

      if (token == null) throw Exception('No token found');

      final data = await TuitionService.fetchTuitionData(
        token: token,
        selectedStatus: selectedStatus,
      );
      setState(() {
        students = data;
      });
    } catch (e) {
      print('Error loading tuition data: $e');
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
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.elliptical(200, 100)),
            ),
            padding: const EdgeInsets.only(top: 90, bottom: 60),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'ค่าเทอม',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Positioned(
                  left: 5,
                  top: -15,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('สถานะ : ',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xffEAEAEA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      value: status.contains(selectedStatus)
                                          ? selectedStatus
                                          : null,
                                      hint: Text('เลือกสถานะ'),
                                      items: status.map((subject) {
                                        return DropdownMenuItem(
                                          value: subject,
                                          child: Text(subject),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedStatus = value!;
                                        });
                                        fetchTuitionData();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ])),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        children: [
                          Container(
                            color: Color(0xFF001B57),
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                _tableHeader('รหัสนักศึกษา', flex: 2),
                                _tableHeader('ชื่อ–นามสกุล', flex: 3),
                                _tableHeader('สถานะ', flex: 1),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 35),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: students.map((record) {
                                  final id = record['id']!;
                                  final name = record['name']!;
                                  final status = record['status'] ?? 'ไม่ทราบ';

                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _tableCell(id, flex: 2),
                                        _tableCell(name, flex: 3),
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                backgroundColor:
                                                    statusColors[status] ??
                                                        Colors.grey.shade300,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: AutoSizeText(
                                                status,
                                                maxLines: 1,
                                                minFontSize: 12,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget _tableHeader(String text, {int flex = 1, bool textAlignCenter = false}) {
  return Expanded(
    flex: flex,
    child: textAlignCenter
        ? Center(
            child: AutoSizeText(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : AutoSizeText(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
  );
}

Widget _tableCell(String text, {int flex = 1, bool textAlignCenter = false}) {
  return Expanded(
    flex: flex,
    child: textAlignCenter
        ? Center(
            child: AutoSizeText(
              text,
              style: TextStyle(fontSize: 16),
              maxLines: 1,
              minFontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : AutoSizeText(
            text,
            style: TextStyle(fontSize: 16),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
  );
}

Widget buildSummaryItem(String label, int count) {
  Color backgroundColor;

  switch (label) {
    case 'มาเรียน':
      backgroundColor = Color(0xff57BC40);
      break;
    case 'สาย':
      backgroundColor = Color(0xffEAA31E);
      break;
    case 'ขาด':
      backgroundColor = Color(0xffE94C30);
      break;
    case 'ลากิจ':
      backgroundColor = Color(0xff33A4C3);
      break;
    case 'ลาป่วย':
      backgroundColor = Color(0xffAE62E2);
      break;
    default:
      backgroundColor = Color(0xff00154C);
  }

  return Column(
    children: [
      Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: AutoSizeText(
            count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
          ),
        ),
      ),
      SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    ],
  );
}
