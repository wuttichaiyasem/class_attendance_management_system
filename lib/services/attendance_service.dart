import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = 'http://localhost:3000/attendance';

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
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception('No token found');
    return token;
  }

  static Future<List<Map<String, String>>> fetchStudents({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse(
      '$baseUrl/?class_id=$classId&date=$date&start_time=$startTime&end_time=$endTime',
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
    final url = Uri.parse('$baseUrl/mark');

    final body = {
      'class_id': classId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'created_by': createdBy,
      'records': records,
    };

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
        '$baseUrl/history?class_id=$classId&date=$date&start_time=$startTime&end_time=$endTime',
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
    final url = Uri.parse('$baseUrl/history-options');
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
      final url = Uri.parse('$baseUrl/check-absent');

      final response = await http.post(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to check absent: ${response.body}');
      }
    } catch (e) {
      print('Error checking absent: $e');
      throw e;
    }
  }

  static Future<void> markAllPresent({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
    required String createdBy,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mark-present'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'class_id': classId,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'created_by': createdBy,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark present: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTeacherSchedule() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/schedule"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch schedule");
    }

    final data = jsonDecode(res.body);

    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class AttendanceAdminService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception('No token found');
    return token;
  }

  // 🔹 1. Fetch Subjects (year + group)
  static Future<List<dynamic>> fetchSubjectsByYearAndGroup({
    required int year,
    required int group,
  }) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/subjects?year=$year&group=$group"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(res.body);
  }

  // 🔹 2. Fetch Dates
  static Future<List<dynamic>> fetchDates({
    required String classId,
  }) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/dates?class_id=$classId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(res.body);
  }

  // 🔹 3. Fetch Times
  static Future<List<dynamic>> fetchTimes({
    required String classId,
    required String date,
  }) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/times?class_id=$classId&date=$date"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(res.body);
  }

  static Future<List<Map<String, dynamic>>> fetchAttendanceHistory({
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse(
          "$baseUrl/history?class_id=$classId&date=$date&start_time=$startTime&end_time=$endTime"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(res.body);

    return List<Map<String, dynamic>>.from(data['attendance']);
  }

  static Future<List<Map<String, dynamic>>> fetchSchedule({
    required int year,
    required int group,
  }) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/schedule?year=$year&group=$group"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch schedule");
    }

    final data = jsonDecode(res.body);

    return List<Map<String, dynamic>>.from(data);
  }
}
