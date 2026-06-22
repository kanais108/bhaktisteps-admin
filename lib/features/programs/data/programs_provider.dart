import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import 'programs_service.dart';

final programsServiceProvider = Provider<ProgramsService>((ref) {
  final apiClient = ApiClient(authStorage: AuthStorage());
  return ProgramsService(apiClient);
});

final programsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(programsServiceProvider);
  return service.getPrograms();
});

final programBatchesProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(programsServiceProvider);
  return service.getBatches();
});

final programLeadersProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(programsServiceProvider);
  return service.getLeaders();
});

final programTreesProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(programsServiceProvider);
  return service.getTrees();
});

final programBatchMembersProvider =
    FutureProvider.family<List<dynamic>, String>((ref, batchId) async {
      final service = ref.read(programsServiceProvider);
      return service.getBatchMembers(batchId);
    });

final programGroupsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(programsServiceProvider);
  return service.getGroups();
});

final programUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(programsServiceProvider);
  return service.getUsers();
});
