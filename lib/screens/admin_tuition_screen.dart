import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:class_attendance_management_system/services/tuition_service.dart';

class AdminTuitionScreen extends StatefulWidget {
  const AdminTuitionScreen({super.key});

  @override
  State<AdminTuitionScreen> createState() => _AdminTuitionScreenState();
}

class _AdminTuitionScreenState extends State<AdminTuitionScreen> {
  String selectedStatus = 'ทั้งหมด';
  String searchText = '';
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTuitionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      print('Token: $token');

      if (token == null) throw Exception('No token found');

      final data = await TuitionAdminService.fetchTuitionData(
        token: token,
        selectedStatus: selectedStatus,
        search: searchText,
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
                                Text('ค้นหา : ',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xffEAEAEA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'ค้นหารหัสนักศึกษาหรือชื่อ',
                                        border: InputBorder.none,
                                        // icon: Icon(Icons.search),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          searchText = value;
                                        });
                                        fetchTuitionData();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 15,
                            ),
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
                                              onPressed: () async {
                                                final bool currentPaid =
                                                    status == 'จ่ายแล้ว';

                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                        'ยืนยันการเปลี่ยนสถานะ'),
                                                    content: Text(
                                                      currentPaid
                                                          ? 'เปลี่ยนเป็น "ยังไม่จ่าย"?'
                                                          : 'เปลี่ยนเป็น "จ่ายแล้ว"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: Text('ยกเลิก'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: Text('ยืนยัน'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm != true) return;

                                                try {
                                                  final prefs =
                                                      await SharedPreferences
                                                          .getInstance();
                                                  final token = prefs
                                                      .getString('jwt_token');
                                                  if (token == null) return;

                                                  await TuitionAdminService
                                                      .updateTuitionStatus(
                                                    token: token,
                                                    studentId: id,
                                                    isPaid: !currentPaid,
                                                  );

                                                  fetchTuitionData();

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'อัปเดตสถานะสำเร็จ')),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'เกิดข้อผิดพลาดในการอัปเดต')),
                                                  );
                                                }
                                              },
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
