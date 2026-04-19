import 'dart:convert';
import 'package:class_attendance_management_system/screens/admin_add_subject_screen.dart';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://localhost:3000/subjects';

class SubjectService {
  static Future<List<Map<String, dynamic>>> getMySubjects(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }
}

class SubjectAdminService {
  static Future<List<Subject>> getSubjects(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Subject.fromJson(e)).toList();
    } else {
      throw Exception('โหลดรายวิชาไม่สำเร็จ');
    }
  }

  static Future<void> addSubject({
    required String token,
    required String subjectId,
    required String subjectName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'subject_id': subjectId,
        'subject_name': subjectName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('เพิ่มรายวิชาไม่สำเร็จ');
    }
  }

  static Future<void> deleteSubject({
    required String token,
    required String subjectId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/remove/$subjectId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ลบรายวิชาไม่สำเร็จ');
    }
  }

  static Future<Map<String, dynamic>> getSubjectSchedules({
    required String token,
    required String subjectId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/$subjectId/schedule'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<void> updateSubjectSchedule({
    required String token,
    required String subjectId,
    required String teacherId,
    required List<Map<String, dynamic>> schedules,
  }) async {
    final url = Uri.parse('$baseUrl/admin/$subjectId/schedule');

    final body = {
      "teacher_id": teacherId,
      "schedules": schedules,
    };

    print("📡 URL: $url");
    print("📦 BODY: ${jsonEncode(body)}");

    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(body),
    );

    print("📥 STATUS: ${res.statusCode}");
    print("📥 RESPONSE: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Failed API: ${res.body}");
    }
  }

  static Future<void> deleteSubjectSchedule({
    required String token,
    required String sessionId,
  }) async {
    final url = Uri.parse('$baseUrl/admin/session/$sessionId');

    final res = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to delete session");
    }
  }
}
