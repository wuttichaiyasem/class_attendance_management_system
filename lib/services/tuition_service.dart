import 'dart:convert';
import 'package:http/http.dart' as http;

final String baseUrl = 'http://localhost:3000';

class TuitionService {
  static Future<List<Map<String, String>>> fetchTuitionData({
    required String token,
    required String selectedStatus,
  }) async {
    final queryParam = selectedStatus == 'ทั้งหมด'
        ? ''
        : selectedStatus == 'จ่ายแล้ว'
            ? '?status=paid'
            : '?status=unpaid';

    final response = await http.get(
      Uri.parse('$baseUrl/tuition/status$queryParam'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    print('Token: $token');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, String>>((item) {
        return {
          'id': item['student_id'],
          'name': item['full_name'],
          'status': item['is_paid'] == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
        };
      }).toList();
    } else {
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('ไม่สามารถโหลดข้อมูลค่าเทอมได้');
    }
  }
}

class TuitionAdminService {
  static Future<List<Map<String, String>>> fetchTuitionData({
    required String token,
    required String selectedStatus,
    String? search,
  }) async {
    final Map<String, String> queryParams = {};

    if (selectedStatus == 'จ่ายแล้ว') {
      queryParams['status'] = 'paid';
    } else if (selectedStatus == 'ยังไม่จ่าย') {
      queryParams['status'] = 'unpaid';
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/tuition/admin/status')
          .replace(queryParameters: queryParams),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    print('Token: $token');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, String>>((item) {
        return {
          'id': item['student_id'],
          'name': item['full_name'],
          'status': item['is_paid'] == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
        };
      }).toList();
    } else {
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('ไม่สามารถโหลดข้อมูลค่าเทอมได้');
    }
  }

  static Future<void> updateTuitionStatus({
    required String token,
    required String studentId,
    required bool isPaid,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/tuition/admin/status/$studentId',
    );

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'is_paid': isPaid,
      }),
    );

    if (response.statusCode != 200) {
      print('Update failed: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('ไม่สามารถอัปเดตสถานะค่าเทอมได้');
    }
  }
}
