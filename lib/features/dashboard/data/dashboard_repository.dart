import '../../../core/network/api_client.dart';

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository(this.apiClient);

  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await apiClient.dio.get('/admin/dashboard');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
