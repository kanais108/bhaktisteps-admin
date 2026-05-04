import '../../../core/network/api_client.dart';

class ContentPagesRepository {
  final ApiClient apiClient;

  ContentPagesRepository(this.apiClient);

  Future<List<dynamic>> fetchContentPages() async {
    final response = await apiClient.dio.get('/content-pages');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> fetchChildren(String parentSlug) async {
    final response = await apiClient.dio.get(
      '/content-pages/$parentSlug/children',
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createContentPage(
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.dio.post('/content-pages', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateContentPage(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.dio.patch(
      '/content-pages/$id',
      data: data,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> saveContentPage(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    if (id != null && id.isNotEmpty) {
      return updateContentPage(id, data);
    }

    return createContentPage(data);
  }
}
