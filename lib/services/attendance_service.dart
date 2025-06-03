import 'dart:convert';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://192.168.196.87:3000';

String mapStatusToThai(String status) {
  switch (status) {
    case 'present':
      return 'มาเรียน';
    case 'late':
      return 'สาย';
    case 'absent':
      return 'ขาด';
    case 'personal_leave':
      return 'ลากิจ';
    case 'sick_leave':
      return 'ลาป่วย';
    default:
      return 'ไม่ทราบ';
  }
}

class AttendanceService {
  static Future<List<Map<String, String>>> fetchStudents({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse(
      '$baseUrl/attendance?class_id=$classId&date=$date&start_time=$startTime&end_time=$endTime',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final students =
          List<Map<String, String>>.from(data['students'].map((s) => {
                'id': s['student_id'].toString(),
                'name': s['full_name'].toString(),
                'status': s['status'].toString(),
              }));

      return students;
    } else {
      throw Exception('Failed to fetch students: ${response.body}');
    }
  }

  static Future<void> submitAttendance({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
    required String createdBy,
    required List<Map<String, String>> records,
  }) async {
    final url = Uri.parse('$baseUrl/attendance/mark');

    final body = {
      'class_id': classId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'created_by': createdBy,
      'records': records,
    };
    
    print('date: $date');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit attendance: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAttendanceHistory({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/attendance/history?class_id=$classId&date=$date&start_time=$startTime&end_time=$endTime',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['attendance'];

        return records.map<Map<String, dynamic>>((item) {
          return {
            'id': item['student_id'],
            'name': item['name'],
            'status': mapStatusToThai(item['status']),
          };
        }).toList();
      } else {
        throw Exception('Failed to load attendance');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchHistoryOptions(String token) async {
    final url = Uri.parse('$baseUrl/attendance/history-options');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch history options');
    }
  }

  static Future<void> checkAndMarkAbsent() async {
    try {
      final url = Uri.parse('$baseUrl/attendance/check-absent');
      
      final response = await http.post(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to check absent: ${response.body}');
      }
    } catch (e) {
      print('Error checking absent: $e');
      throw e;
    }
  }

  static Future<void> startAutoAttendanceCheck(String classId, String date, String startTime, String endTime) async {
    try {
      while (true) {
        await Future.delayed(Duration(minutes: 1));

        await checkAndMarkAbsent();

        final now = DateTime.now();
        final classEndTime = DateTime.parse('${date}T$endTime');
        if (now.isAfter(classEndTime)) {
          break;
        }
      }
    } catch (e) {
      print('Error in auto attendance check: $e');
      throw e;
    }
  }
}
