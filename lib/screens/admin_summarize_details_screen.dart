import 'package:class_attendance_management_system/services/summarize_service.dart';
import 'package:flutter/material.dart';

class AdminSummarizeDetailsScreen extends StatefulWidget {
  final String student_id;
  final String name;

  const AdminSummarizeDetailsScreen({
    super.key,
    required this.student_id,
    required this.name,
  });

  @override
  State<AdminSummarizeDetailsScreen> createState() =>
      _AdminSummarizeDetailsScreenState();
}

class _AdminSummarizeDetailsScreenState
    extends State<AdminSummarizeDetailsScreen> {
  List<Map<String, dynamic>> details = [];
  bool isLoading = true;

  Future<void> fetchDetails() async {
    try {
      final result =
          await SummarizeAdminService.fetchStudentDetails(widget.student_id);

      final filtered = (result as List)
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) =>
              item['status'] == 'absent' ||
              item['status'] == 'late' ||
              item['status'] == 'sick_leave' ||
              item['status'] == 'personal_leave')
          .toList();

      final transformed = transformData(filtered);

      setState(() {
        details = List<Map<String, dynamic>>.from(transformed['records']);
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, dynamic> transformData(List<Map<String, dynamic>> raw) {
    Map<String, Map<String, List<String>>> grouped = {};

    for (var item in raw) {
      final status = item['status'];
      final subject = item['subject_name'];
      final date = item['session_date'];

      if (!grouped.containsKey(status)) {
        grouped[status] = {};
      }

      if (!grouped[status]!.containsKey(subject)) {
        grouped[status]![subject] = [];
      }

      grouped[status]![subject]!.add(date.toString());
    }

    List records = [];

    grouped.forEach((status, subjects) {
      records.add({
        "type": _getTypeText(status), // convert to Thai
        "count": subjects.values.fold(0, (sum, list) => sum + list.length),
        "subjects": subjects.entries.map((e) {
          return {
            "subject_name": e.key,
            "dates": e.value,
          };
        }).toList()
      });
    });

    return {"full_name": widget.name, "records": records};
  }

  @override
  void initState() {
    super.initState();
    fetchDetails();
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
                        widget.name,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
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
                  : details.isEmpty
                      ? Center(child: Text("ไม่มีข้อมูล"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: details.length,
                          itemBuilder: (context, index) {
                            final record = details[index];
                            final type = record['type'];
                            final count = record['count'];
                            final subjects = record['subjects'];

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: getTypeColor(type),
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
                                      children: subjects.map<Widget>((sub) {
                                        final name = sub['subject_name'];
                                        final dates = (sub['dates'] as List)
                                            .map(
                                                (d) => formatDate(d.toString()))
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
                                                  fontWeight: FontWeight.w600,
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
                        ))
        ]));
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

  String _getTypeText(String type) {
    switch (type) {
      case 'absent':
        return 'ขาด';
      case 'late':
        return 'สาย';
      case 'sick_leave':
        return 'ลาป่วย';
      case 'personal_leave':
        return 'ลากิจ';
      default:
        return '';
    }
  }
}
