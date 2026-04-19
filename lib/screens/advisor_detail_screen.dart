import 'package:flutter/material.dart';
import '../services/advisor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AdvisorDetailScreen extends StatefulWidget {
  final String studentId;

  const AdvisorDetailScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<AdvisorDetailScreen> createState() => _AdvisorDetailScreenState();
}

class _AdvisorDetailScreenState extends State<AdvisorDetailScreen> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentDetail();
  }

  Future<void> _loadStudentDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) throw Exception('No token found');

      final data = await AdvisorService.fetchStudentClassDetail(
        token: token,
        studentId: widget.studentId,
      );

      setState(() {
        studentData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading student detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถโหลดข้อมูลได้')),
      );
      setState(() => isLoading = false);
    }
  }

  String formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);

      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = (parsed.year + 543);

      return "$day/$month/$year";
    } catch (_) {
      return date;
    }
  }

  Color getTypeColor(String type) {
    switch (type) {
      case 'ขาด':
        return Color(0xffE94C30);
      case 'สาย':
        return Color(0xffEAA31E);
      case 'ลากิจ':
        return Color(0xff33A4C3);
      case 'ลาป่วย':
        return Color(0xffAE62E2);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = studentData;

    return Scaffold(
      backgroundColor: const Color(0xffF3F3F3),
      body: Column(
        children: [
          // Header แบบ custom
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xff00154C),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(200, 100),
              ),
            ),
            padding: const EdgeInsets.only(top: 90, bottom: 60),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AutoSizeText(
                    data?['full_name'] ?? 'นักศึกษา',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    minFontSize: 18,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Positioned(
                  left: 5,
                  top: -15,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data == null
                    ? const Center(child: Text('ไม่พบข้อมูล'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ถ้าต้องการแสดงชื่ออีกครั้งด้านใน สามารถเพิ่ม Text ได้
                            // Text(
                            //   data['full_name'] ?? '',
                            //   style: const TextStyle(
                            //     fontSize: 20,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            // const SizedBox(height: 16),

                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: data['records'].length,
                                itemBuilder: (context, index) {
                                  final record = data['records'][index];
                                  final type = record['type'];
                                  final count = record['count'];
                                  final subjects = record['subjects'];

                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    getTypeColor(type),
                                                child: Text(
                                                  count.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                type,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                                subjects.map<Widget>((sub) {
                                              final name = sub['subject_name'];
                                              final dates = (sub['dates']
                                                      as List)
                                                  .map((d) =>
                                                      formatDate(d.toString()))
                                                  .toList();

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 6, left: 4),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      dates.join(', '),
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
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
          ),
        ],
      ),
    );
  }
}
