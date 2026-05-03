import '../../../core/network/api_client.dart';

class GroupsRepository {
  final ApiClient apiClient;

  GroupsRepository(this.apiClient);

  Future<List<dynamic>> fetchGroups() async {
    final response = await apiClient.dio.get('/groups');
    return List<dynamic>.from(response.data as List);
  }

  Future<void> createGroup({
    required String templeId,
    required String name,
    String? code,
    String? groupType,
  }) async {
    await apiClient.dio.post(
      '/groups',
      data: {
        'templeId': templeId,
        'name': name.trim(),
        'code': code?.trim().isEmpty == true ? null : code?.trim(),
        'groupType': groupType?.trim().isEmpty == true
            ? null
            : groupType?.trim(),
      },
    );
  }

  Future<List<dynamic>> fetchGroupMembers(String groupId) async {
    final response = await apiClient.dio.get(
      '/group-members',
      queryParameters: {'groupId': groupId},
    );
    return List<dynamic>.from(response.data as List);
  }

  Future<void> addMember({
    required String groupId,
    required String userId,
  }) async {
    await apiClient.dio.post(
      '/group-members',
      data: {'groupId': groupId, 'userId': userId},
    );
  }

  Future<void> removeMember(String groupMemberId) async {
    await apiClient.dio.delete('/group-members/$groupMemberId');
  }

  Future<List<dynamic>> fetchUsers({String? search}) async {
    final response = await apiClient.dio.get(
      '/users',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return List<dynamic>.from(response.data as List);
  }
}
