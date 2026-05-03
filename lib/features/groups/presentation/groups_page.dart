import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../temples/data/temples_repository.dart';
import '../data/groups_repository.dart';
import 'widgets/add_group_member_dialog.dart';
import 'widgets/create_group_dialog.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late final GroupsRepository repo;
  late final TemplesRepository templesRepo;

  List<dynamic> temples = [];
  List<dynamic> groups = [];
  List<dynamic> members = [];
  bool groupsLoading = true;
  bool membersLoading = false;
  String? errorMessage;
  String? selectedGroupId;
  String? selectedGroupName;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(authStorage: AuthStorage());
    repo = GroupsRepository(apiClient);
    templesRepo = TemplesRepository(apiClient);
    loadTemples();
    loadGroups();
  }

  Future<void> loadTemples() async {
    try {
      final result = await templesRepo.fetchTemples();
      setState(() {
        temples = result;
      });
    } catch (_) {
      setState(() {
        temples = [];
      });
    }
  }

  Future<void> loadGroups() async {
    setState(() {
      groupsLoading = true;
      errorMessage = null;
    });

    try {
      final result = await repo.fetchGroups();
      setState(() {
        groups = result;
      });

      if (result.isNotEmpty) {
        final first = Map<String, dynamic>.from(result.first as Map);
        await selectGroup(first);
      } else {
        setState(() {
          selectedGroupId = null;
          selectedGroupName = null;
          members = [];
        });
      }
    } on DioException catch (e) {
      setState(() {
        errorMessage = _extractError(e, fallback: 'Failed to load groups');
      });
    } finally {
      setState(() {
        groupsLoading = false;
      });
    }
  }

  Future<void> selectGroup(Map<String, dynamic> group) async {
    final groupId = group['id']?.toString();
    final groupName = group['name']?.toString();

    if (groupId == null) return;

    setState(() {
      selectedGroupId = groupId;
      selectedGroupName = groupName;
      membersLoading = true;
      members = [];
    });

    try {
      final result = await repo.fetchGroupMembers(groupId);
      setState(() {
        members = result;
      });
    } on DioException catch (e) {
      setState(() {
        errorMessage = _extractError(e, fallback: 'Failed to load members');
      });
    } finally {
      setState(() {
        membersLoading = false;
      });
    }
  }

  Future<void> createGroup() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CreateGroupDialog(temples: temples),
    );

    if (result == null) return;

    try {
      await repo.createGroup(
        templeId: result['templeId']?.toString() ?? '',
        name: result['name']?.toString() ?? '',
        code: result['code']?.toString(),
        groupType: result['groupType']?.toString(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully')),
      );

      await loadGroups();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractError(e, fallback: 'Failed to create group')),
        ),
      );
    }
  }

  Future<void> addMember() async {
    if (selectedGroupId == null) return;

    try {
      final users = await repo.fetchUsers();

      if (!mounted) return;

      final selectedUserId = await showDialog<String>(
        context: context,
        builder: (_) => AddGroupMemberDialog(users: users),
      );

      if (selectedUserId == null) return;

      await repo.addMember(groupId: selectedGroupId!, userId: selectedUserId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member added successfully')),
      );

      final selectedGroup = groups
          .map((e) => Map<String, dynamic>.from(e as Map))
          .firstWhere((g) => g['id'].toString() == selectedGroupId);

      await selectGroup(selectedGroup);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractError(e, fallback: 'Failed to add member')),
        ),
      );
    }
  }

  Future<void> removeMember(String groupMemberId) async {
    try {
      await repo.removeMember(groupMemberId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed successfully')),
      );

      final selectedGroup = groups
          .map((e) => Map<String, dynamic>.from(e as Map))
          .firstWhere((g) => g['id'].toString() == selectedGroupId);

      await selectGroup(selectedGroup);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractError(e, fallback: 'Failed to remove member')),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Groups',
          subtitle: 'Create groups and manage group membership.',
          action: ElevatedButton(
            onPressed: createGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Text('Create Group'),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: AppCard(
                  child: SizedBox(
                    height: 560,
                    child: groupsLoading
                        ? const LoadingState()
                        : groups.isEmpty
                        ? const EmptyState(
                            title: 'No groups found',
                            subtitle: 'Create a group to get started.',
                          )
                        : ListView.separated(
                            itemCount: groups.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final group = Map<String, dynamic>.from(
                                groups[index] as Map,
                              );
                              final isSelected =
                                  selectedGroupId == group['id']?.toString();

                              return Material(
                                color: isSelected
                                    ? AppColors.primarySoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  title: Text(
                                    group['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (group['code'] != null)
                                          StatusChip(
                                            label: 'Code: ${group['code']}',
                                          ),
                                        if (group['groupType'] != null)
                                          StatusChip(
                                            label: group['groupType']
                                                .toString(),
                                          ),
                                      ],
                                    ),
                                  ),
                                  onTap: () => selectGroup(group),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedGroupName == null
                                  ? 'Members'
                                  : '$selectedGroupName Members',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (selectedGroupId != null)
                            ElevatedButton(
                              onPressed: addMember,
                              child: const Text('Add Member'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: selectedGroupId == null
                            ? const EmptyState(
                                title: 'No group selected',
                                subtitle: 'Select a group to view members.',
                              )
                            : membersLoading
                            ? const LoadingState()
                            : members.isEmpty
                            ? const EmptyState(
                                title: 'No members found',
                                subtitle: 'Add members to this group.',
                              )
                            : ListView.separated(
                                itemCount: members.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final member = Map<String, dynamic>.from(
                                    members[index] as Map,
                                  );

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    title: Text(
                                      member['fullName']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            member['email']?.toString() ?? '',
                                          ),
                                          StatusChip(
                                            label:
                                                member['role']?.toString() ??
                                                '-',
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: TextButton(
                                      onPressed: () =>
                                          removeMember(member['id'].toString()),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
