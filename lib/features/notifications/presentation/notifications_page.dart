import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  bool sending = false;

  /// Audience
  String selectedAudience = 'all';
  String selectedRole = 'USER';

  /// Events
  List<dynamic> events = [];
  bool loadingEvents = false;
  String? selectedEventId;
  String? selectedImageUrl;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() => loadingEvents = true);

    try {
      final api = ApiClient(authStorage: AuthStorage());
      final response = await api.dio.get('/events');

      setState(() {
        events = List<dynamic>.from(response.data as List);
        loadingEvents = false;
      });
    } catch (e) {
      debugPrint('Failed to load events: $e');
      setState(() => loadingEvents = false);
    }
  }

  Future<void> sendNotification() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    if (selectedEventId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an event')));
      return;
    }

    setState(() => sending = true);

    try {
      final api = ApiClient(authStorage: AuthStorage());

      final response = await api.dio.post(
        '/notifications/send',
        data: {
          'title': title,
          'body': body,
          'type': 'events',
          'eventId': selectedEventId,
          'imageUrl': selectedImageUrl,
          'audience': selectedAudience,
          if (selectedAudience == 'role') 'role': selectedRole,
        },
      );

      debugPrint('NOTIFICATION RESPONSE -> ${response.data}');

      titleController.clear();
      bodyController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event notification sent 🚀')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => sending = false);
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send Event Notification',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an event and notify users',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              /// EVENT PICKER
              loadingEvents
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedEventId,
                      decoration: const InputDecoration(
                        labelText: 'Select Event',
                        border: OutlineInputBorder(),
                      ),
                      items: events.map((event) {
                        return DropdownMenuItem<String>(
                          value: event['id'].toString(),
                          child: Text(event['title'] ?? 'Untitled'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedEventId = value;

                          final event = events.firstWhere(
                            (e) => e['id'].toString() == value,
                          );

                          /// Auto-fill
                          titleController.text = event['title'] ?? '';
                          bodyController.text =
                              event['description'] ?? 'Join this event';

                          selectedImageUrl = event['posterImageUrl']
                              ?.toString();
                        });
                      },
                    ),

              const SizedBox(height: 16),

              /// TITLE
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              /// BODY
              TextField(
                controller: bodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              /// AUDIENCE
              DropdownButtonFormField<String>(
                value: selectedAudience,
                decoration: const InputDecoration(
                  labelText: 'Audience',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(value: 'role', child: Text('By Role')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedAudience = value);
                  }
                },
              ),

              if (selectedAudience == 'role') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'SUPER_ADMIN',
                      child: Text('Super Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'CIRCLE_LEADER',
                      child: Text('Circle Leader'),
                    ),
                    DropdownMenuItem(value: 'USER', child: Text('User')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
              ],

              const SizedBox(height: 24),

              /// SEND BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sending ? null : sendNotification,
                  child: sending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Notification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
