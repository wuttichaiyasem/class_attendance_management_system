import 'package:auto_size_text/auto_size_text.dart';
import 'package:class_attendance_management_system/screens/admin_summarize_details_screen.dart';
import 'package:class_attendance_management_system/services/summarize_service.dart';
import 'package:flutter/material.dart';

class AdminSummarizeScreen extends StatefulWidget {
  final String year;
  final int group;
  final String homeroomId;

  const AdminSummarizeScreen({
    super.key,
    required this.year,
    required this.group,
    required this.homeroomId,
  });

  @override
  State<AdminSummarizeScreen> createState() => _AdminSummarizeScreenState();
}

class _AdminSummarizeScreenState extends State<AdminSummarizeScreen> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  Future<void> fetchSummary() async {
    try {
      final result = await SummarizeAdminService.fetchSummary(
        homeroomId: widget.homeroomId,
      );

      setState(() {
        students = List<Map<String, dynamic>>.from(result);
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xffF3F3F3),
        body: Column(children: [
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
                        'สรุป',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${widget.year} / ห้อง ${widget.group}',
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
            child: Container(
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 🔹 Header row
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xff00154C),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "ชื่อ-นามสกุล",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              "สถานะ",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Data rows
                  Expanded(
                    child: students.isEmpty
                        ? Center(
                            child: Text(
                              "ไม่มีข้อมูล",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminSummarizeDetailsScreen(
                                        student_id: student['student_id'],
                                        name: student['full_name'],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: AutoSizeText(
                                          student['full_name'],
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildStatusBox(
                                              int.parse(
                                                  student['absent'].toString()),
                                              Color(0xffE94C30),
                                              "ขาด",
                                            ),
                                            _buildStatusBox(
                                              int.parse(
                                                  student['late'].toString()),
                                              Color(0xffEAA31E),
                                              "สาย",
                                            ),
                                            _buildStatusBox(
                                              int.parse(student['personal']
                                                  .toString()),
                                              Color(0xff33A4C3),
                                              "ลากิจ",
                                            ),
                                            _buildStatusBox(
                                              int.parse(
                                                  student['sick'].toString()),
                                              Color(0xffAE62E2),
                                              "ลาป่วย",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          )
        ]));
  }

  Widget _buildStatusBox(int count, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 26,
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: 1),
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
