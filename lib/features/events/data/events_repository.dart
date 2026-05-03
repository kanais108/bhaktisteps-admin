import '../../../core/network/api_client.dart';

class EventsRepository {
  final ApiClient apiClient;

  EventsRepository(this.apiClient);

  Future<List<dynamic>> fetchEvents() async {
    final response = await apiClient.dio.get('/events');
    return List<dynamic>.from(response.data as List);
  }

  Future<void> createEvent({
    required String templeId,
    String? groupId,
    required String category,
    required String title,
    String? description,
    String? posterImageUrl,
    String? eventMode,
    String? locationName,
    required String startsAtIso,
    required String endsAtIso,
    String? attendanceMode,
  }) async {
    await apiClient.dio.post(
      '/events',
      data: {
        'templeId': templeId,
        'groupId': groupId?.trim().isEmpty == true ? null : groupId?.trim(),
        'category': category,
        'title': title.trim(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'posterImageUrl': posterImageUrl,
        'eventMode': eventMode,
        'locationName': locationName?.trim().isEmpty == true
            ? null
            : locationName?.trim(),
        'startsAt': startsAtIso,
        'endsAt': endsAtIso,
        'attendanceMode': attendanceMode,
      },
    );
  }

  Future<void> updateEvent({
    required String eventId,
    required String templeId,
    String? groupId,
    required String category,
    String? posterImageUrl,
    required String title,
    String? description,
    String? eventMode,
    String? locationName,
    required String startsAtIso,
    required String endsAtIso,
    String? attendanceMode,
    required bool isActive,
  }) async {
    await apiClient.dio.patch(
      '/events/$eventId',
      data: {
        'templeId': templeId,
        'groupId': groupId?.trim().isEmpty == true ? null : groupId?.trim(),
        'category': category,
        'posterImageUrl': posterImageUrl,
        'title': title.trim(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'eventMode': eventMode,
        'locationName': locationName?.trim().isEmpty == true
            ? null
            : locationName?.trim(),
        'startsAt': startsAtIso,
        'endsAt': endsAtIso,
        'attendanceMode': attendanceMode,
        'isActive': isActive,
      },
    );
  }

  Future<void> deactivateEvent(String eventId) async {
    await apiClient.dio.patch('/events/$eventId/deactivate');
  }
}
