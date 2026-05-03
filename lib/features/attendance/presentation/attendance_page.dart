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
import '../data/attendance_repository.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late final AttendanceRepository repo;
  final searchController = TextEditingController();

  List<dynamic> attendance = [];
  List<dynamic> filteredAttendance = [];
  bool loading = true;
  String? errorMessage;
  String selectedStatus = 'ALL';

  final statuses = const ['ALL', 'present', 'absent', 'late', 'excused'];

  @override
  void initState() {
    super.initState();
    repo = AttendanceRepository(ApiClient(authStorage: AuthStorage()));
    loadAttendance();
    searchController.addListener(applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadAttendance() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await repo.fetchAttendance();
      setState(() {
        attendance = result;
      });
      applyFilters();
    } on DioException catch (e) {
      setState(() {
        errorMessage = _extractError(e, fallback: 'Failed to load attendance');
      });
    } catch (_) {
      setState(() {
        errorMessage = 'Failed to load attendance';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final result = attendance.where((item) {
      final row = Map<String, dynamic>.from(item as Map);

      final user = row['user'] is Map
          ? Map<String, dynamic>.from(row['user'] as Map)
          : <String, dynamic>{};

      final event = row['event'] is Map
          ? Map<String, dynamic>.from(row['event'] as Map)
          : <String, dynamic>{};

      final markedByUser = row['markedByUser'] is Map
          ? Map<String, dynamic>.from(row['markedByUser'] as Map)
          : <String, dynamic>{};

      final status = (row['status'] ?? '').toString().toLowerCase();

      final matchesStatus =
          selectedStatus == 'ALL' || status == selectedStatus.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          (user['fullName'] ?? '').toString().toLowerCase().contains(query) ||
          (user['email'] ?? '').toString().toLowerCase().contains(query) ||
          (event['title'] ?? '').toString().toLowerCase().contains(query) ||
          (markedByUser['fullName'] ?? '').toString().toLowerCase().contains(
            query,
          ) ||
          status.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();

    setState(() {
      filteredAttendance = result;
    });
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'late':
        return AppColors.warning;
      case 'excused':
        return Colors.deepPurple;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Attendance',
          subtitle: 'Review scoped attendance records across events and users.',
          action: OutlinedButton(
            onPressed: loadAttendance,
            child: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by user, event, marker, status',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Status',
                      ),
                      items: statuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedStatus = value;
                        });
                        applyFilters();
                      },
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 520,
                child: loading
                    ? const LoadingState()
                    : filteredAttendance.isEmpty
                    ? const EmptyState(
                        title: 'No attendance records found',
                        subtitle: 'Try changing filters or refresh the data.',
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Event',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Marked By',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Marked At',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: filteredAttendance.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final row = Map<String, dynamic>.from(
                                  filteredAttendance[index] as Map,
                                );

                                final user = row['user'] is Map
                                    ? Map<String, dynamic>.from(
                                        row['user'] as Map,
                                      )
                                    : <String, dynamic>{};

                                final event = row['event'] is Map
                                    ? Map<String, dynamic>.from(
                                        row['event'] as Map,
                                      )
                                    : <String, dynamic>{};

                                final markedByUser = row['markedByUser'] is Map
                                    ? Map<String, dynamic>.from(
                                        row['markedByUser'] as Map,
                                      )
                                    : <String, dynamic>{};

                                final status = (row['status'] ?? '-')
                                    .toString();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['fullName']?.toString() ??
                                                  '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user['email']?.toString() ?? '-',
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          event['title']?.toString() ?? '-',
                                        ),
                                      ),
                                      Expanded(
                                        child: StatusChip(
                                          label: status,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          markedByUser['fullName']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatDate(
                                            row['markedAt']?.toString(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
