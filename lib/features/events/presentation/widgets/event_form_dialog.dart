import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventFormDialog extends StatefulWidget {
  final Map<String, dynamic>? event;
  final List<dynamic> temples;
  final List<dynamic> groups;

  const EventFormDialog({
    super.key,
    this.event,
    required this.temples,
    required this.groups,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final posterImageController = TextEditingController();

  final categories = const [
    'bhakti_vriksha',
    'bhagavatam_class',
    'mangala_arati',
    'sunday_feast',
    'festival',
    'youth_program',
    'course',
    'other',
  ];

  final eventModes = const ['offline', 'online', 'hybrid'];
  final attendanceModes = const ['qr', 'self', 'admin', 'code'];

  late String selectedCategory;
  late String selectedEventMode;
  late String selectedAttendanceMode;
  late bool isActive;

  String? selectedTempleId;
  String? selectedGroupId;

  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    final event = widget.event;

    titleController.text = event?['title']?.toString() ?? '';
    descriptionController.text = event?['description']?.toString() ?? '';
    locationController.text = event?['locationName']?.toString() ?? '';
    posterImageController.text = event?['posterImageUrl']?.toString() ?? '';

    selectedTempleId = event?['templeId']?.toString();
    selectedGroupId = event?['groupId']?.toString();

    selectedCategory = _safeDropdownValue(
      event?['category']?.toString(),
      categories,
      'other',
    );

    selectedEventMode = _safeDropdownValue(
      event?['eventMode']?.toString(),
      eventModes,
      'offline',
    );

    selectedAttendanceMode = _safeDropdownValue(
      event?['attendanceMode']?.toString(),
      attendanceModes,
      'qr',
    );

    isActive = event?['isActive'] == false ? false : true;

    final start = _parseLocalDateTime(event?['startsAt']?.toString());
    final end = _parseLocalDateTime(event?['endsAt']?.toString());

    if (start != null) {
      selectedDate = DateTime(start.year, start.month, start.day);
      selectedStartTime = TimeOfDay(hour: start.hour, minute: start.minute);
    }

    if (end != null) {
      selectedEndTime = TimeOfDay(hour: end.hour, minute: end.minute);
    }

    posterImageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  String _safeDropdownValue(
    String? value,
    List<String> allowed,
    String fallback,
  ) {
    if (value != null && allowed.contains(value)) return value;
    return fallback;
  }

  DateTime? _parseLocalDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    posterImageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime ?? TimeOfDay.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedStartTime = picked;

      if (selectedEndTime == null) {
        final startAsDate = DateTime(2000, 1, 1, picked.hour, picked.minute);
        final suggestedEnd = startAsDate.add(const Duration(hours: 1));
        selectedEndTime = TimeOfDay(
          hour: suggestedEnd.hour,
          minute: suggestedEnd.minute,
        );
      }
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime ?? selectedStartTime ?? TimeOfDay.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedEndTime = picked;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void submit() {
    final templeId = selectedTempleId?.trim();
    final groupId = selectedGroupId?.trim();

    if (templeId == null || templeId.isEmpty) {
      _showError('Please select a temple.');
      return;
    }

    if (titleController.text.trim().isEmpty) {
      _showError('Please enter an event title.');
      return;
    }

    if (selectedDate == null) {
      _showError('Please select an event date.');
      return;
    }

    if (selectedStartTime == null) {
      _showError('Please select a start time.');
      return;
    }

    if (selectedEndTime == null) {
      _showError('Please select an end time.');
      return;
    }

    final startsAt = _combine(selectedDate!, selectedStartTime!);
    final endsAt = _combine(selectedDate!, selectedEndTime!);

    if (!endsAt.isAfter(startsAt)) {
      _showError('End time must be after start time.');
      return;
    }

    Navigator.of(context).pop({
      'templeId': templeId,
      'groupId': groupId == null || groupId.isEmpty ? null : groupId,
      'category': selectedCategory,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'eventMode': selectedEventMode,
      'locationName': locationController.text.trim(),
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'attendanceMode': selectedAttendanceMode,
      'isActive': isActive,
      'posterImageUrl': posterImageController.text.trim(),
    });
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String _displayDate() {
    if (selectedDate == null) return 'Select event date';
    return DateFormat('EEE, dd MMM yyyy').format(selectedDate!);
  }

  String _displayTime(TimeOfDay? time, String placeholder) {
    if (time == null) return placeholder;
    return time.format(context);
  }

  Widget _pickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: inputDecoration(label),
        child: Row(
          children: [
            Icon(icon, size: 19, color: Colors.blueGrey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temples = widget.temples
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final groups = widget.groups
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final posterUrl = posterImageController.text.trim();

    return AlertDialog(
      title: Text(isEditing ? 'Edit Event' : 'Create Event'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedTempleId,
                decoration: inputDecoration('Temple'),
                items: temples
                    .map(
                      (temple) => DropdownMenuItem<String>(
                        value: temple['id']?.toString(),
                        child: Text(
                          temple['name']?.toString() ??
                              temple['title']?.toString() ??
                              temple['id']?.toString() ??
                              'Temple',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTempleId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedGroupId,
                decoration: inputDecoration('Group (optional)'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No group'),
                  ),
                  ...groups.map(
                    (group) => DropdownMenuItem<String>(
                      value: group['id']?.toString(),
                      child: Text(
                        group['name']?.toString() ??
                            group['title']?.toString() ??
                            group['id']?.toString() ??
                            'Group',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGroupId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: inputDecoration('Category'),
                items: categories
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: titleController,
                decoration: inputDecoration('Title'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: inputDecoration('Description'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: posterImageController,
                decoration: inputDecoration('Poster Image URL'),
              ),

              if (posterUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    posterUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: double.infinity,
                      alignment: Alignment.center,
                      color: Colors.grey.shade100,
                      child: const Text('Poster preview unavailable'),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedEventMode,
                decoration: inputDecoration('Event Mode'),
                items: eventModes
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => selectedEventMode = v!),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: locationController,
                decoration: inputDecoration('Location'),
              ),
              const SizedBox(height: 18),

              _sectionTitle('Event Date & Time'),
              const SizedBox(height: 10),

              _pickerField(
                label: 'Date',
                value: _displayDate(),
                icon: Icons.calendar_today_rounded,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _pickerField(
                      label: 'Start Time',
                      value: _displayTime(
                        selectedStartTime,
                        'Select start time',
                      ),
                      icon: Icons.schedule_rounded,
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pickerField(
                      label: 'End Time',
                      value: _displayTime(selectedEndTime, 'Select end time'),
                      icon: Icons.schedule_rounded,
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedAttendanceMode,
                decoration: inputDecoration('Attendance Mode'),
                items: attendanceModes
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => selectedAttendanceMode = v!),
              ),

              if (isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
