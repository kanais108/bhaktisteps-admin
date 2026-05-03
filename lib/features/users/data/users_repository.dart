import '../../../core/network/api_client.dart';

class UsersRepository {
  final ApiClient apiClient;

  UsersRepository(this.apiClient);

  Future<Map<String, dynamic>> fetchUsers({
    String? search,
    int page = 1,
    int limit = 10,
    String? role,
    bool? isActive,
  }) async {
    final response = await apiClient.dio.get(
      '/users',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
        if (role != null && role.isNotEmpty) 'role': role,
        if (isActive != null) 'isActive': isActive.toString(),
      },
    );

    final raw = response.data;

    if (raw is List) {
      return {'data': raw, 'total': raw.length};
    }

    if (raw is Map && raw['data'] != null) {
      return Map<String, dynamic>.from(raw);
    }

    throw Exception('Invalid users response format');
  }

  Future<List<dynamic>> fetchAssignableManagers(String role) async {
    final response = await apiClient.dio.get(
      '/users/assignable-managers',
      queryParameters: {'role': role},
    );
    return List<dynamic>.from(response.data as List);
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    await apiClient.dio.post(
      '/users',
      data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      },
    );
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await apiClient.dio.patch('/users/$userId/role', data: {'role': role});
  }

  Future<void> updateUserHierarchy({
    required String userId,
    String? treeId,
    String? reportsToUserId,
  }) async {
    await apiClient.dio.patch(
      '/users/$userId/hierarchy',
      data: {'treeId': treeId, 'reportsToUserId': reportsToUserId},
    );
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await apiClient.dio.patch(
      '/users/$userId/status',
      data: {'isActive': isActive},
    );
  }
}
