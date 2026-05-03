import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../groups/data/groups_repository.dart';
import '../../temples/data/temples_repository.dart';
import '../data/events_repository.dart';
import 'widgets/event_form_dialog.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventsRepository repo;
  late final GroupsRepository groupsRepo;
  late final TemplesRepository templesRepo;

  List<dynamic> events = [];
  List<dynamic> groups = [];
  List<dynamic> temples = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(authStorage: AuthStorage());
    repo = EventsRepository(apiClient);
    groupsRepo = GroupsRepository(apiClient);
    templesRepo = TemplesRepository(apiClient);

    loadLookups();
    loadEvents();
  }

  Future<void> loadLookups() async {
    try {
      final results = await Future.wait([
        groupsRepo.fetchGroups(),
        templesRepo.fetchTemples(),
      ]);

      setState(() {
        groups = results[0];
        temples = results[1];
      });
    } catch (_) {
      setState(() {
        groups = [];
        temples = [];
      });
    }
  }

  Future<void> loadEvents() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await repo.fetchEvents();
      setState(() {
        events = result;
      });
    } on DioException catch (e) {
      setState(() {
        errorMessage = _extractError(e, fallback: 'Failed to load events');
      });
    } catch (_) {
      setState(() {
        errorMessage = 'Failed to load events';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> createEvent() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EventFormDialog(temples: temples, groups: groups),
    );

    if (result == null) return;

    try {
      await repo.createEvent(
        templeId: result['templeId']?.toString() ?? '',
        groupId: result['groupId']?.toString(),
        category: result['category']?.toString() ?? 'other',
        title: result['title']?.toString() ?? '',
        description: result['description']?.toString(),
        posterImageUrl: result['posterImageUrl']?.toString(),
        eventMode: result['eventMode']?.toString(),
        locationName: result['locationName']?.toString(),
        startsAtIso: result['startsAt']?.toString() ?? '',
        endsAtIso: result['endsAt']?.toString() ?? '',
        attendanceMode: result['attendanceMode']?.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );
      await loadEvents();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractError(e, fallback: 'Failed to create event')),
        ),
      );
    }
  }

  Future<void> editEvent(Map<String, dynamic> event) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          EventFormDialog(event: event, temples: temples, groups: groups),
    );

    if (result == null) return;

    try {
      await repo.updateEvent(
        eventId: event['id'].toString(),
        templeId: result['templeId']?.toString() ?? '',
        groupId: result['groupId']?.toString(),
        category: result['category']?.toString() ?? 'other',
        title: result['title']?.toString() ?? '',
        description: result['description']?.toString(),
        posterImageUrl: result['posterImageUrl']?.toString(),
        eventMode: result['eventMode']?.toString(),
        locationName: result['locationName']?.toString(),
        startsAtIso: result['startsAt']?.toString() ?? '',
        endsAtIso: result['endsAt']?.toString() ?? '',
        attendanceMode: result['attendanceMode']?.toString(),
        isActive: result['isActive'] == true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
      await loadEvents();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractError(e, fallback: 'Failed to update event')),
        ),
      );
    }
  }

  Future<void> deactivateEvent(String eventId) async {
    try {
      await repo.deactivateEvent(eventId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deactivated successfully')),
      );
      await loadEvents();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _extractError(e, fallback: 'Failed to deactivate event'),
          ),
        ),
      );
    }
  }

  String _extractError(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        return message.join(', ');
      }
      return message.toString();
    }
    return fallback;
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Events',
          subtitle: 'Create, edit, and manage upcoming events.',
          action: ElevatedButton(
            onPressed: createEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Text('Create Event'),
          ),
        ),
        const SizedBox(height: 20),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        Expanded(
          child: AppCard(
            child: SizedBox(
              height: 560,
              child: loading
                  ? const LoadingState()
                  : events.isEmpty
                  ? const EmptyState(
                      title: 'No events found',
                      subtitle: 'Create an event to get started.',
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final event = Map<String, dynamic>.from(
                          events[index] as Map,
                        );
                        final isActive = event['isActive'] == true;
                        final posterImageUrl = event['posterImageUrl']
                            ?.toString();
                        final hasPoster =
                            posterImageUrl != null &&
                            posterImageUrl.trim().isNotEmpty;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          leading: hasPoster
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    posterImageUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported_rounded,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.event_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                          title: Text(
                            event['title']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(event['startsAt']?.toString()),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    StatusChip(
                                      label:
                                          event['category']?.toString() ?? '-',
                                    ),
                                    StatusChip(
                                      label:
                                          event['eventMode']?.toString() ?? '-',
                                    ),
                                    StatusChip(
                                      label:
                                          event['attendanceMode']?.toString() ??
                                          '-',
                                    ),
                                    StatusChip(
                                      label: isActive ? 'Active' : 'Inactive',
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => editEvent(event),
                                child: const Text('Edit'),
                              ),
                              if (isActive)
                                TextButton(
                                  onPressed: () =>
                                      deactivateEvent(event['id'].toString()),
                                  child: const Text(
                                    'Deactivate',
                                    style: TextStyle(color: AppColors.danger),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
