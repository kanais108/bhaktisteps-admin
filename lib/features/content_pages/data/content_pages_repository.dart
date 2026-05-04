import '../../../core/network/api_client.dart';

class ContentPagesRepository {
  final ApiClient apiClient;

  ContentPagesRepository(this.apiClient);

  Future<List<dynamic>> fetchContentPages() async {
    final response = await apiClient.dio.get('/content-pages');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> saveContentPage(
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.dio.post('/content-pages', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
