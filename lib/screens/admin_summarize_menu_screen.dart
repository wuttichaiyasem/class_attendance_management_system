import 'package:class_attendance_management_system/screens/admin_summarize_screen.dart';
import 'package:class_attendance_management_system/services/summarize_service.dart';
import 'package:flutter/material.dart';

class AdminSummarizeMenuScreen extends StatefulWidget {
  const AdminSummarizeMenuScreen({super.key});

  @override
  State<AdminSummarizeMenuScreen> createState() =>
      _AdminSummarizeMenuScreenState();
}

class _AdminSummarizeMenuScreenState extends State<AdminSummarizeMenuScreen> {
  List<Map<String, dynamic>> yearData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      final result = await SummarizeAdminService.fetchClasses();

      setState(() {
        yearData = List<Map<String, dynamic>>.from(result);
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> groupByYear() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in yearData) {
      final year = item['year'] ?? 'ไม่ระบุ';

      if (!grouped.containsKey(year)) {
        grouped[year] = [];
      }

      grouped[year]!.add(item);
    }

    return grouped;
  }

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
                        'สรุป',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ห้องเรียน',
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
                  : Builder(builder: (context) {
                      final grouped = groupByYear();

                      if (yearData.isEmpty) {
                        return Center(child: Text("ไม่มีข้อมูล"));
                      }

                      return ListView(
                        padding: const EdgeInsets.all(12),
                        children: grouped.entries.map((entry) {
                          final year = entry.key;
                          final classes = entry.value;

                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔹 Year Header
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xff00154C),
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                  ),
                                  child: Text(
                                    year,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // 🔹 Class list
                                ...classes.map((item) {
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminSummarizeScreen(
                                            year: item['year'],
                                            group: item['group'],
                                            homeroomId: item['homeroom_id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.class_,
                                              color: Color(0xff00154C)),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              "ห้อง ${item['group'] ?? '-'}",
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(Icons.arrow_forward_ios,
                                              size: 16),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),

                                SizedBox(height: 8),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    })),
        ],
      ),
    );
  }
}
