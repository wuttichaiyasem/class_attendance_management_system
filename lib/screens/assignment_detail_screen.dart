import 'package:auto_size_text/auto_size_text.dart';
import 'package:class_attendance_management_system/services/homework_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String homeworkId;
  final String subjectName;
  final String title;
  final String dueDate;

  const AssignmentDetailScreen(
      {super.key,
      required this.homeworkId,
      required this.subjectName,
      required this.title,
      required this.dueDate});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  Map<String, String> selectedStatuses = {};
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  final List<String> statusOptions = ['ส่งแล้ว', 'ส่งสาย', 'ไม่ส่ง'];

  final Map<String, Color> statusColors = {
    'ส่งแล้ว': Color(0xff57BC40),
    'ส่งสาย': Color(0xffEAA31E),
    'ไม่ส่ง': Color(0xffE94C30)
  };

  String mapStatusToDb(String status) {
    switch (status) {
      case 'ส่งแล้ว':
        return 'submitted';
      case 'ส่งสาย':
        return 'late';
      case 'ไม่ส่ง':
        return 'missing';
      default:
        return 'missing';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final fetchedStudents =
          await HomeworkService.fetchStudentsByHomeworkId(widget.homeworkId);

      setState(() {
        students.clear();
        students.addAll(fetchedStudents);

        selectedStatuses.clear();
        for (var student in fetchedStudents) {
          final studentId = student['student_id'] ?? '';
          final rawStatus = student['status'] ?? 'เลือก';
          String displayStatus;

          switch (rawStatus) {
            case 'submitted':
              displayStatus = 'ส่งแล้ว';
              break;
            case 'late':
              displayStatus = 'ส่งสาย';
              break;
            case 'missing':
              displayStatus = 'ไม่ส่ง';
              break;
            default:
              displayStatus = 'เลือก';
          }

          selectedStatuses[studentId] = displayStatus;
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
      );
    }
  }

  Future<void> submitSingleHomeworkStatus(
      String studentId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final submittedBy = prefs.getString('user_id') ?? '';

    if (submittedBy.isEmpty) {
      print('ไม่พบ user_id');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final records = [
      {
        'student_id': studentId,
        'status': mapStatusToDb(status),
      }
    ];

    try {
      await HomeworkService.submitHomework(
        homeworkId: widget.homeworkId,
        submittedBy: submittedBy,
        records: records,
      );

      print('บันทึกสำเร็จ: $studentId -> $status');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกสำเร็จ'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกไม่สำเร็จ'),
          duration: Duration(seconds: 1),
        ),
      );
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
                  'การบ้าน',
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _confirmDelete(context, widget.homeworkId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: Size(40, 28),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'ชื่อวิชา : ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: AutoSizeText(
                          widget.subjectName,
                          style: TextStyle(fontSize: 18),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      'หัวข้อ : ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: AutoSizeText(
                          widget.title,
                          style: TextStyle(fontSize: 18),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      'กำหนดส่ง - หมดเขต : ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEAEAEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: AutoSizeText(
                          widget.dueDate,
                          style: TextStyle(fontSize: 18),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
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
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          _tableHeader('รหัสนักศึกษา', flex: 2),
                          _tableHeader('ชื่อ–นามสกุล', flex: 3),
                          _tableHeader('สถานะ', flex: 1, textAlignCenter: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 35),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final id = student['student_id']!;
                          final name = student['full_name']!;
                          final status = selectedStatuses[id] ?? 'เลือก';

                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
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
                                      onPressed: () => _showStatusDialogFor(id),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        backgroundColor: status == 'เลือก'
                                            ? Colors.grey.shade300
                                            : statusColors[status],
                                        foregroundColor: status == 'เลือก'
                                            ? Colors.black
                                            : Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialogFor(String studentId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'เลือก',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: Colors.red),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...statusOptions.map((status) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColors[status],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedStatuses[studentId] = status;
                      });
                      Navigator.of(context).pop();
                      submitSingleHomeworkStatus(studentId, status);
                    },
                    child: Text(status, style: TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

void _confirmDelete(BuildContext context, String homeworkId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Center(
        child: Text(
          'ยืนยันการลบ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        ),
      ),
      content: const Text(
        'คุณแน่ใจหรือไม่ว่าต้องการลบการบ้านนี้?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          child: const Text('ยกเลิก'
          ,style: TextStyle(fontSize: 20,fontWeight: FontWeight.w500,color: Colors.black)),
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('ลบ'
            ,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white)),
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final success = await HomeworkService.deleteHomework(homeworkId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบการบ้านสำเร็จ')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบการบ้านไม่สำเร็จ')),
      );
    }
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
