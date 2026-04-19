import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = 'http://localhost:3000/summarize';

class SummarizeAdminService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception('No token found');
    return token;
  }

  static Future<List<Map<String, dynamic>>> fetchClasses() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/classes"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed: ${res.body}");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSummary({
    required String homeroomId,
  }) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/admin/summary?homeroom_id=$homeroomId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Failed to load summary");
    }

    final data = jsonDecode(res.body);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<dynamic>> fetchStudentDetails(String studentId) async {
    final token = await _getToken();

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/student-details?student_id=$studentId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to load student details");
      }
    } catch (e) {
      throw Exception("Error fetching student details: $e");
    }
  }
}
