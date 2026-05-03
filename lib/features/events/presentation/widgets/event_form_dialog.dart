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
  final templeIdController = TextEditingController();
  final groupIdController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final startsAtController = TextEditingController();
  final endsAtController = TextEditingController();

  /// ✅ NEW
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

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    final event = widget.event;

    templeIdController.text = event?['templeId']?.toString() ?? '';
    groupIdController.text = event?['groupId']?.toString() ?? '';
    titleController.text = event?['title']?.toString() ?? '';
    descriptionController.text = event?['description']?.toString() ?? '';
    locationController.text = event?['locationName']?.toString() ?? '';

    /// ✅ NEW
    posterImageController.text = event?['posterImageUrl']?.toString() ?? '';

    startsAtController.text = _formatForInput(event?['startsAt']?.toString());
    endsAtController.text = _formatForInput(event?['endsAt']?.toString());

    selectedTempleId = event?['templeId']?.toString();
    selectedGroupId = event?['groupId']?.toString();

    selectedCategory = event?['category']?.toString() ?? 'other';
    selectedEventMode = event?['eventMode']?.toString() ?? 'offline';
    selectedAttendanceMode = event?['attendanceMode']?.toString() ?? 'qr';
    isActive = event?['isActive'] == false ? false : true;
  }

  String _formatForInput(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _toIso(String value) {
    final parsed = DateFormat('yyyy-MM-dd HH:mm').parse(value, true).toLocal();
    return parsed.toUtc().toIso8601String();
  }

  @override
  void dispose() {
    templeIdController.dispose();
    groupIdController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    startsAtController.dispose();
    endsAtController.dispose();

    /// ✅ NEW
    posterImageController.dispose();

    super.dispose();
  }

  void submit() {
    Navigator.of(context).pop({
      'templeId': selectedTempleId ?? templeIdController.text.trim(),
      'groupId': selectedGroupId ?? groupIdController.text.trim(),
      'category': selectedCategory,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'eventMode': selectedEventMode,
      'locationName': locationController.text.trim(),
      'startsAt': _toIso(startsAtController.text.trim()),
      'endsAt': _toIso(endsAtController.text.trim()),
      'attendanceMode': selectedAttendanceMode,
      'isActive': isActive,

      /// ✅ NEW FIELD
      'posterImageUrl': posterImageController.text.trim(),
    });
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
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

    return AlertDialog(
      title: Text(isEditing ? 'Edit Event' : 'Create Event'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// EXISTING FIELDS (unchanged)...
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

              /// 🔥 NEW IMAGE FIELD
              TextField(
                controller: posterImageController,
                decoration: inputDecoration('Poster Image URL'),
              ),

              const SizedBox(height: 8),

              /// 🔥 LIVE PREVIEW
              if (posterImageController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      posterImageController.text,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              TextField(
                controller: locationController,
                decoration: inputDecoration('Location'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: startsAtController,
                decoration: inputDecoration('Starts At'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: endsAtController,
                decoration: inputDecoration('Ends At'),
              ),
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
