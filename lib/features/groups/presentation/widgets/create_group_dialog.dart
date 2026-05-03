import 'package:flutter/material.dart';

class CreateGroupDialog extends StatefulWidget {
  final List<dynamic> temples;

  const CreateGroupDialog({super.key, required this.temples});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final templeIdController = TextEditingController();
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final groupTypeController = TextEditingController();

  String? selectedTempleId;

  @override
  void dispose() {
    templeIdController.dispose();
    nameController.dispose();
    codeController.dispose();
    groupTypeController.dispose();
    super.dispose();
  }

  void submit() {
    final templeId = selectedTempleId ?? templeIdController.text.trim();

    Navigator.of(context).pop({
      'templeId': templeId,
      'name': nameController.text.trim(),
      'code': codeController.text.trim(),
      'groupType': groupTypeController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final temples = widget.temples
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return AlertDialog(
      title: const Text('Create Group'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (temples.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: selectedTempleId,
                decoration: const InputDecoration(
                  labelText: 'Temple',
                  border: OutlineInputBorder(),
                ),
                items: temples
                    .map(
                      (temple) => DropdownMenuItem<String>(
                        value: temple['id']?.toString(),
                        child: Text(
                          temple['name']?.toString() ??
                              temple['title']?.toString() ??
                              temple['id']?.toString() ??
                              'Temple',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTempleId = value;
                    if (value != null) {
                      templeIdController.text = value;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Or enter Temple ID manually',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: templeIdController,
              decoration: const InputDecoration(
                labelText: 'Temple ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Code (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: groupTypeController,
              decoration: const InputDecoration(
                labelText: 'Group Type (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: submit, child: const Text('Create')),
      ],
    );
  }
}
