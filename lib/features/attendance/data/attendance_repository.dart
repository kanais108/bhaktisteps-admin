import '../../../core/network/api_client.dart';

class AttendanceRepository {
  final ApiClient apiClient;

  AttendanceRepository(this.apiClient);

  Future<List<dynamic>> fetchAttendance() async {
    final response = await apiClient.dio.get('/attendance');
    return List<dynamic>.from(response.data as List);
  }
}
