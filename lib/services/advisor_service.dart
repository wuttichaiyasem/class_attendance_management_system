import 'dart:convert';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://localhost:3000/advisor';

class AdvisorService {
  static Future<List<Map<String, dynamic>>> fetchStudents(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) {
        final summary = item['summary'] ?? {};

        return {
          'student_id': item['student_id'],
          'name': item['full_name'],
          'present': summary['มาเรียน'] ?? '0',
          'late': summary['สาย'] ?? '0',
          'absent': summary['ขาด'] ?? '0',
          'personal_leave': summary['ลากิจ'] ?? '0',
          'sick_leave': summary['ลาป่วย'] ?? '0',
        };
      }).toList();
    } else {
      throw Exception('ไม่สามารถโหลดข้อมูลนักศึกษาได้');
    }
  }

  static Future<Map<String, dynamic>> fetchStudentDetail({
    required String token,
    required String studentId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      print('Error fetching student detail: ${response.body}');
      throw Exception('ไม่สามารถโหลดข้อมูลรายวิชาของนักศึกษาได้');
    }
  }

  static Future<Map<String, dynamic>> fetchStudentClassDetail({
    required String token,
    required String studentId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$studentId/attendance-summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      print('Error fetching student detail: ${response.body}');
      throw Exception('ไม่สามารถโหลดข้อมูลรายวิชาของนักศึกษาได้');
    }
  }

  static Future<bool> checkIfAdvisor(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/check'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return data['isAdvisor'] == true;
    } else {
      throw Exception('Failed to check advisor status');
    }
  }
}
