import 'package:flutter/material.dart';

class AddGroupMemberDialog extends StatefulWidget {
  final List<dynamic> users;

  const AddGroupMemberDialog({super.key, required this.users});

  @override
  State<AddGroupMemberDialog> createState() => _AddGroupMemberDialogState();
}

class _AddGroupMemberDialogState extends State<AddGroupMemberDialog> {
  String? selectedUserId;

  @override
  Widget build(BuildContext context) {
    final users = widget.users
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return AlertDialog(
      title: const Text('Add Group Member'),
      content: SizedBox(
        width: 460,
        child: DropdownButtonFormField<String>(
          value: selectedUserId,
          decoration: const InputDecoration(
            labelText: 'Select User',
            border: OutlineInputBorder(),
          ),
          items: users
              .map(
                (user) => DropdownMenuItem<String>(
                  value: user['id']?.toString(),
                  child: Text(
                    '${user['fullName']} (${user['email']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedUserId = value;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedUserId == null
              ? null
              : () => Navigator.of(context).pop(selectedUserId),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
