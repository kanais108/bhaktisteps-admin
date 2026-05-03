import '../../../core/network/api_client.dart';

class TemplesRepository {
  final ApiClient apiClient;

  TemplesRepository(this.apiClient);

  Future<List<dynamic>> fetchTemples() async {
    final response = await apiClient.dio.get('/temples');
    return List<dynamic>.from(response.data as List);
  }
}
