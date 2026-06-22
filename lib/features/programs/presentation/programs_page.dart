import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/programs_provider.dart';

class ProgramsPage extends ConsumerStatefulWidget {
  const ProgramsPage({super.key});

  @override
  ConsumerState<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends ConsumerState<ProgramsPage> {
  String? selectedBatchId;

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.red : Colors.green,
        content: Text(message),
      ),
    );
  }

  String _displayDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.contains('T')) return text.split('T').first;
    return text;
  }

  Widget _tableScroll(Widget child) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }

  Future<void> _openProgramDialog({Map<String, dynamic>? program}) async {
    final nameController = TextEditingController(
      text: program?['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: program?['description']?.toString() ?? '',
    );
    final weeksController = TextEditingController(
      text: program?['totalWeeks']?.toString() ?? '',
    );

    bool isActive = program?['isActive'] == false ? false : true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(program == null ? 'Create Program' : 'Edit Program'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Program Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weeksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Weeks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      title: const Text('Active'),
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Program name is required', error: true);
      return;
    }

    final totalWeeks = int.tryParse(weeksController.text.trim());
    final service = ref.read(programsServiceProvider);

    try {
      if (program == null) {
        await service.createProgram(
          name: name,
          description: descriptionController.text.trim(),
          totalWeeks: totalWeeks,
          isActive: isActive,
        );
        _showSnack('Program created');
      } else {
        await service.updateProgram(
          programId: program['id'].toString(),
          name: name,
          description: descriptionController.text.trim(),
          totalWeeks: totalWeeks,
          isActive: isActive,
        );
        _showSnack('Program updated');
      }

      ref.invalidate(programsProvider);
    } catch (e) {
      _showSnack('Failed to save program: $e', error: true);
    }
  }

  Future<void> _openBatchDialog({
    Map<String, dynamic>? batch,
    required List<dynamic> programs,
    required List<dynamic> leaders,
    required List<dynamic> trees,
  }) async {
    String? programId =
        batch?['programId']?.toString() ?? batch?['program']?['id']?.toString();
    String? leaderId =
        batch?['leaderId']?.toString() ?? batch?['leader']?['id']?.toString();
    String? treeId =
        batch?['treeId']?.toString() ?? batch?['tree']?['id']?.toString();

    final nameController = TextEditingController(
      text: batch?['name']?.toString() ?? '',
    );
    final startDateController = TextEditingController(
      text: _displayDate(batch?['startDate']) == '-'
          ? ''
          : _displayDate(batch?['startDate']),
    );

    bool isActive = batch?['isActive'] == false ? false : true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(batch == null ? 'Create Batch' : 'Edit Batch'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: programId,
                        decoration: const InputDecoration(
                          labelText: 'Program',
                          border: OutlineInputBorder(),
                        ),
                        items: programs.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(item['name']?.toString() ?? 'Program'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => programId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: leaderId,
                        decoration: const InputDecoration(
                          labelText: 'Leader',
                          border: OutlineInputBorder(),
                        ),
                        items: leaders.map<DropdownMenuItem<String>>((item) {
                          final name = item['fullName']?.toString() ?? '';
                          final email = item['email']?.toString() ?? '';
                          final role = item['role']?.toString() ?? '';

                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text('$name • $role • $email'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => leaderId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: treeId,
                        decoration: const InputDecoration(
                          labelText: 'Leadership Tree Optional',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('No tree'),
                          ),
                          ...trees.map<DropdownMenuItem<String>>((item) {
                            return DropdownMenuItem<String>(
                              value: item['id'].toString(),
                              child: Text(item['name']?.toString() ?? 'Tree'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            treeId = value == null || value.isEmpty
                                ? null
                                : value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Start Date YYYY-MM-DD',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isActive,
                        title: const Text('Active'),
                        onChanged: (value) {
                          setDialogState(() => isActive = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    if (programId == null || programId!.isEmpty) {
      _showSnack('Program is required', error: true);
      return;
    }

    if (leaderId == null || leaderId!.isEmpty) {
      _showSnack('Leader is required', error: true);
      return;
    }

    final service = ref.read(programsServiceProvider);

    try {
      if (batch == null) {
        await service.createBatch(
          programId: programId!,
          leaderId: leaderId!,
          treeId: treeId,
          name: nameController.text.trim(),
          startDate: startDateController.text.trim().isEmpty
              ? null
              : startDateController.text.trim(),
          isActive: isActive,
        );
        _showSnack('Batch created');
      } else {
        await service.updateBatch(
          batchId: batch['id'].toString(),
          programId: programId,
          leaderId: leaderId,
          treeId: treeId,
          name: nameController.text.trim(),
          startDate: startDateController.text.trim().isEmpty
              ? null
              : startDateController.text.trim(),
          isActive: isActive,
        );
        _showSnack('Batch updated');
      }

      ref.invalidate(programBatchesProvider);
    } catch (e) {
      _showSnack('Failed to save batch: $e', error: true);
    }
  }

  Future<void> _addMemberToBatch(String batchId) async {
    List<dynamic> users;

    try {
      users = await ref.read(programUsersProvider.future);
    } catch (e) {
      _showSnack('Failed to load users: $e', error: true);
      return;
    }

    if (!mounted) return;

    if (users.isEmpty) {
      _showSnack('No users found to add', error: true);
      return;
    }

    final selectedUserIds = <String>{};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Members to Batch'),
              content: SizedBox(
                width: 720,
                height: 520,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selectedUserIds.length} selected',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final userMap = Map<String, dynamic>.from(
                            users[index] as Map,
                          );

                          final userId = userMap['id']?.toString();
                          final name = userMap['fullName']?.toString() ?? '';
                          final email = userMap['email']?.toString() ?? '';
                          final role = userMap['role']?.toString() ?? '';
                          final isActive = userMap['isActive'] == true;

                          if (userId == null || userId.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final selected = selectedUserIds.contains(userId);

                          return CheckboxListTile(
                            value: selected,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              name.isEmpty ? email : name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('$role • $email'),
                            secondary: isActive
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(Icons.cancel, color: Colors.red),
                            onChanged: isActive
                                ? (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedUserIds.add(userId);
                                      } else {
                                        selectedUserIds.remove(userId);
                                      }
                                    });
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedUserIds.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedUserIds.clear();

                      for (final user in users) {
                        final userMap = Map<String, dynamic>.from(user as Map);
                        final userId = userMap['id']?.toString();
                        final isActive = userMap['isActive'] == true;

                        if (userId != null && userId.isNotEmpty && isActive) {
                          selectedUserIds.add(userId);
                        }
                      }
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedUserIds.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: Text('Add ${selectedUserIds.length}'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedUserIds.isEmpty) return;

    try {
      final service = ref.read(programsServiceProvider);

      for (final userId in selectedUserIds) {
        await service.addBatchMember(batchId: batchId, userId: userId);
      }

      _showSnack('${selectedUserIds.length} member(s) added to batch');

      ref.invalidate(programBatchMembersProvider(batchId));
      ref.invalidate(programBatchesProvider);
    } catch (e) {
      _showSnack('Failed to add members: $e', error: true);
    }
  }

  Future<void> _copyMembersFromGroup(String batchId) async {
    final groups = await ref.read(programGroupsProvider.future);

    String? selectedGroupId;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Copy Members From Group'),
              content: SizedBox(
                width: 480,
                child: DropdownButtonFormField<String>(
                  value: selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Select Group',
                    border: OutlineInputBorder(),
                  ),
                  items: groups.map<DropdownMenuItem<String>>((group) {
                    final groupMap = Map<String, dynamic>.from(group as Map);

                    return DropdownMenuItem<String>(
                      value: groupMap['id']?.toString(),
                      child: Text(groupMap['name']?.toString() ?? 'Group'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedGroupId = value);
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Copy'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedGroupId == null) return;

    try {
      final service = ref.read(programsServiceProvider);

      final result = await service.copyMembersFromGroup(
        batchId: batchId,
        groupId: selectedGroupId!,
      );

      _showSnack(result['message']?.toString() ?? 'Members copied');

      ref.invalidate(programBatchMembersProvider(batchId));
      ref.invalidate(programBatchesProvider);
    } catch (e) {
      _showSnack('Failed to copy members: $e', error: true);
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final batchesAsync = ref.watch(programBatchesProvider);
    final leadersAsync = ref.watch(programLeadersProvider);
    final treesAsync = ref.watch(programTreesProvider);

    return Container(
      color: const Color(0xFFF8FAFC),
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Programs',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openProgramDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Program'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              child: programsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load programs: $error'),
                data: (programs) {
                  if (programs.isEmpty) {
                    return const Text('No programs found.');
                  }

                  return _tableScroll(
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Weeks')),
                        DataColumn(label: Text('Active')),
                        DataColumn(label: Text('Batches')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: programs.map<DataRow>((program) {
                        final count = program['_count']?['batches'] ?? 0;

                        return DataRow(
                          cells: [
                            DataCell(Text(program['name']?.toString() ?? '-')),
                            DataCell(
                              Text(program['totalWeeks']?.toString() ?? '-'),
                            ),
                            DataCell(
                              Text(program['isActive'] == true ? 'Yes' : 'No'),
                            ),
                            DataCell(Text(count.toString())),
                            DataCell(
                              TextButton(
                                onPressed: () => _openProgramDialog(
                                  program: Map<String, dynamic>.from(
                                    program as Map,
                                  ),
                                ),
                                child: const Text('Edit'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Program Batches',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      programsAsync.hasValue &&
                          leadersAsync.hasValue &&
                          treesAsync.hasValue
                      ? () => _openBatchDialog(
                          programs: programsAsync.value ?? [],
                          leaders: leadersAsync.value ?? [],
                          trees: treesAsync.value ?? [],
                        )
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Batch'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              child: batchesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load batches: $error'),
                data: (batches) {
                  if (batches.isEmpty) {
                    return const Text('No batches found.');
                  }

                  return _tableScroll(
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Batch')),
                        DataColumn(label: Text('Program')),
                        DataColumn(label: Text('Leader')),
                        DataColumn(label: Text('Start Date')),
                        DataColumn(label: Text('Active')),
                        DataColumn(label: Text('Members')),
                        DataColumn(label: Text('Sessions')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: batches.map<DataRow>((batch) {
                        final program = batch['program'];
                        final leader = batch['leader'];
                        final count = batch['_count'];

                        return DataRow(
                          selected: selectedBatchId == batch['id'].toString(),
                          onSelectChanged: (_) {
                            setState(() {
                              selectedBatchId = batch['id'].toString();
                            });
                          },
                          cells: [
                            DataCell(Text(batch['name']?.toString() ?? '-')),
                            DataCell(Text(program?['name']?.toString() ?? '-')),
                            DataCell(
                              Text(leader?['fullName']?.toString() ?? '-'),
                            ),
                            DataCell(Text(_displayDate(batch['startDate']))),
                            DataCell(
                              Text(batch['isActive'] == true ? 'Yes' : 'No'),
                            ),
                            DataCell(
                              Text(count?['members']?.toString() ?? '0'),
                            ),
                            DataCell(
                              Text(count?['sessions']?.toString() ?? '0'),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed:
                                        programsAsync.hasValue &&
                                            leadersAsync.hasValue &&
                                            treesAsync.hasValue
                                        ? () => _openBatchDialog(
                                            batch: Map<String, dynamic>.from(
                                              batch as Map,
                                            ),
                                            programs: programsAsync.value ?? [],
                                            leaders: leadersAsync.value ?? [],
                                            trees: treesAsync.value ?? [],
                                          )
                                        : null,
                                    child: const Text('Edit'),
                                  ),
                                  TextButton(
                                    onPressed: () => _copyMembersFromGroup(
                                      batch['id'].toString(),
                                    ),
                                    child: const Text('Copy Members'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Batch Members',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: selectedBatchId == null
                      ? null
                      : () => _addMemberToBatch(selectedBatchId!),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add Member'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              child: selectedBatchId == null
                  ? const Text('Select a batch to view members.')
                  : Consumer(
                      builder: (context, ref, _) {
                        final membersAsync = ref.watch(
                          programBatchMembersProvider(selectedBatchId!),
                        );

                        return membersAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) =>
                              Text('Failed to load members: $error'),
                          data: (members) {
                            if (members.isEmpty) {
                              return const Text('No members in this batch.');
                            }

                            return _tableScroll(
                              DataTable(
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Role')),
                                  DataColumn(label: Text('Active')),
                                ],
                                rows: members.map<DataRow>((member) {
                                  final user = member['user'];

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          user?['fullName']?.toString() ?? '-',
                                        ),
                                      ),
                                      DataCell(
                                        Text(user?['email']?.toString() ?? '-'),
                                      ),
                                      DataCell(
                                        Text(user?['role']?.toString() ?? '-'),
                                      ),
                                      DataCell(
                                        Text(
                                          member['isActive'] == true
                                              ? 'Yes'
                                              : 'No',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
