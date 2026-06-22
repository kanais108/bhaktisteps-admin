import '../../../core/network/api_client.dart';

class ProgramsService {
  final ApiClient apiClient;

  ProgramsService(this.apiClient);

  Future<List<dynamic>> getPrograms() async {
    final response = await apiClient.dio.get('/program-admin/programs');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createProgram({
    required String name,
    String? description,
    int? totalWeeks,
    bool isActive = true,
  }) async {
    final response = await apiClient.dio.post(
      '/program-admin/programs',
      data: {
        'name': name,
        'description': description,
        'totalWeeks': totalWeeks,
        'isActive': isActive,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateProgram({
    required String programId,
    String? name,
    String? description,
    int? totalWeeks,
    bool? isActive,
  }) async {
    final response = await apiClient.dio.patch(
      '/program-admin/programs/$programId',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (totalWeeks != null) 'totalWeeks': totalWeeks,
        if (isActive != null) 'isActive': isActive,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getBatches() async {
    final response = await apiClient.dio.get('/program-admin/batches');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createBatch({
    required String programId,
    required String leaderId,
    String? treeId,
    String? name,
    String? startDate,
    bool isActive = true,
  }) async {
    final response = await apiClient.dio.post(
      '/program-admin/batches',
      data: {
        'programId': programId,
        'leaderId': leaderId,
        'treeId': treeId,
        'name': name,
        'startDate': startDate,
        'isActive': isActive,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateBatch({
    required String batchId,
    String? programId,
    String? leaderId,
    String? treeId,
    String? name,
    String? startDate,
    bool? isActive,
  }) async {
    final response = await apiClient.dio.patch(
      '/program-admin/batches/$batchId',
      data: {
        if (programId != null) 'programId': programId,
        if (leaderId != null) 'leaderId': leaderId,
        if (treeId != null) 'treeId': treeId,
        if (name != null) 'name': name,
        if (startDate != null) 'startDate': startDate,
        if (isActive != null) 'isActive': isActive,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getBatchMembers(String batchId) async {
    final response = await apiClient.dio.get(
      '/program-admin/batches/$batchId/members',
    );

    return response.data as List<dynamic>;
  }

  Future<void> addBatchMember({
    required String batchId,
    required String userId,
  }) async {
    await apiClient.dio.post(
      '/program-admin/batches/$batchId/members',
      data: {'userId': userId},
    );
  }

  Future<void> removeBatchMember({
    required String batchId,
    required String userId,
  }) async {
    await apiClient.dio.delete(
      '/program-admin/batches/$batchId/members/$userId',
    );
  }

  Future<Map<String, dynamic>> copyMembersFromGroup({
    required String batchId,
    required String groupId,
  }) async {
    final response = await apiClient.dio.post(
      '/program-admin/batches/$batchId/copy-members-from-group',
      data: {'groupId': groupId},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getLeaders() async {
    final response = await apiClient.dio.get('/program-admin/leaders');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getTrees() async {
    final response = await apiClient.dio.get('/program-admin/trees');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getGroups() async {
    final response = await apiClient.dio.get('/groups');
    return response.data as List<dynamic>;
  }
}
