import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class UserEditDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> assignableManagers;

  const UserEditDialog({
    super.key,
    required this.user,
    required this.assignableManagers,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  late String selectedRole;
  String? selectedManagerId;
  late bool isActive;

  final roles = const [
    'DEVOTEE',
    'SERVANT_LEADER',
    'SECTOR_LEADER',
    'CIRCLE_LEADER',
    'SUPER_ADMIN',
  ];

  @override
  void initState() {
    super.initState();

    final currentRole = widget.user['role']?.toString() ?? 'DEVOTEE';

    // Safety: if old data still has GROUP_LEADER / ADMIN, map it to current roles.
    if (currentRole == 'GROUP_LEADER') {
      selectedRole = 'SERVANT_LEADER';
    } else if (currentRole == 'ADMIN') {
      selectedRole = 'SUPER_ADMIN';
    } else if (roles.contains(currentRole)) {
      selectedRole = currentRole;
    } else {
      selectedRole = 'DEVOTEE';
    }

    selectedManagerId = widget.user['reportsToUserId']?.toString();
    isActive = widget.user['isActive'] == true;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'DEVOTEE':
        return 'Devotee';
      case 'SERVANT_LEADER':
        return 'Servant Leader';
      case 'SECTOR_LEADER':
        return 'Sector Leader';
      case 'CIRCLE_LEADER':
        return 'Circle Leader';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      default:
        return role;
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void submit() {
    Navigator.of(context).pop({
      'role': selectedRole,
      'reportsToUserId': selectedManagerId,
      'isActive': isActive,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit User',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user['fullName']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user['email']?.toString() ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: _inputDecoration('Role'),
                items: roles
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(_roleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedRole = value;
                    selectedManagerId = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String?>(
                value: selectedManagerId,
                decoration: _inputDecoration('Reports To (optional)'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...widget.assignableManagers.map(
                    (m) => DropdownMenuItem<String?>(
                      value: m['id'].toString(),
                      child: Text(m['fullName']?.toString() ?? ''),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedManagerId = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  value: isActive,
                  onChanged: (val) {
                    setState(() => isActive = val);
                  },
                  title: const Text('Active Status'),
                  subtitle: Text(isActive ? 'Active' : 'Inactive'),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
