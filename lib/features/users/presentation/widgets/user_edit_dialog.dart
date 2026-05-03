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

  final roles = ['DEVOTEE', 'GROUP_LEADER', 'ADMIN'];

  @override
  void initState() {
    super.initState();
    selectedRole = widget.user['role']?.toString() ?? 'DEVOTEE';
    selectedManagerId = widget.user['reportsToUserId']?.toString();
    isActive = widget.user['isActive'] == true;
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
              // 🧾 Header
              const Text(
                'Edit User',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // 👤 User Info (read-only)
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

              // 🏷 Role
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: _inputDecoration('Role'),
                items: roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                    selectedManagerId = null; // reset hierarchy
                  });
                },
              ),

              const SizedBox(height: 16),

              // 🧑‍💼 Manager
              DropdownButtonFormField<String?>(
                value: selectedManagerId,
                decoration: _inputDecoration('Reports To (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.assignableManagers.map(
                    (m) => DropdownMenuItem<String>(
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

              // 🔘 Status Toggle
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

              // 🔘 Actions
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
