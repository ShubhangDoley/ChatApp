import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/group_chat_repository.dart';
import '../../../../data/repositories/user_repository.dart';

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late Future<Map<String, String>> _membersFuture;
  // Maps uid → photoUrl for members, populated alongside _membersFuture.
  final Map<String, String> _memberPhotos = {};

  String? _iconUrl;
  bool _isUploadingIcon = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final url = await context
        .read<GroupChatRepository>()
        .fetchGroupIconUrl(widget.groupId);
    if (mounted) setState(() => _iconUrl = url);
  }

  void _loadMembers() {
    _memberPhotos.clear();
    // Capture repository before async gaps to avoid BuildContext warnings.
    final userRepo = context.read<UserRepository>();
    _membersFuture = context
        .read<GroupChatRepository>()
        .fetchGroupMembersWithNames(widget.groupId)
        .then((members) async {
          for (final uid in members.keys) {
            final user = await userRepo.fetchUserById(uid);
            if (user != null && mounted) {
              _memberPhotos[uid] = user.photoUrl;
            }
          }
          return members;
        });
  }

  // ── Set Group Icon ──────────────────────────────────────────────────────────

  Future<void> _pickAndUploadIcon() async {
    final source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingIcon = true);
    try {
      final url = await context.read<GroupChatRepository>().uploadGroupIcon(
        groupId: widget.groupId,
        imageFile: File(picked.path),
      );
      if (mounted) {
        setState(() {
          _iconUrl = url;
          _isUploadingIcon = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingIcon = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload icon: $e')),
        );
      }
    }
  }

  Future<ImageSource?> _chooseImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Add Members ────────────────────────────────────────────────────────────

  Future<void> _showAddMembersSheet(Map<String, String> currentMembers) async {
    final allUsers = await context
        .read<UserRepository>()
        .fetchAllUsers(
          excludeUid: context.read<AuthRepository>().currentUser?.uid,
        );

    // Filter out users already in the group.
    final candidates = allUsers
        .where((u) => !currentMembers.containsKey(u.uid))
        .toList();

    if (!mounted) return;

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available to add.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMembersSheet(
        candidates: candidates,
        groupId: widget.groupId,
        groupChatRepository: context.read<GroupChatRepository>(),
      ),
    );

    // Refresh member list after sheet closes.
    if (mounted) {
      setState(_loadMembers);
    }
  }

  // ── Delete Group ────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${widget.groupName}"?\n'
          'This will remove the group for all members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context
          .read<GroupChatRepository>()
          .deleteGroup(widget.groupId);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete group: $e')),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: FutureBuilder<Map<String, String>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data ?? {};
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildGroupActions(members)),
              _buildMembersSection(members),
              SliverToBoxAdapter(child: _buildDangerZone()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  // ── Sliver App Bar (hero header) ─────────────────────────────────────────

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.cardColor,
      foregroundColor: AppTheme.textPrimary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7986CB), AppTheme.primaryColor],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Stack(
                children: [
                  // ── Group avatar ──────────────────────────────────────────
                  if (_isUploadingIcon)
                    const CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  else if (_iconUrl != null && _iconUrl!.isNotEmpty)
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: NetworkImage(_iconUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: const Icon(
                        Icons.group,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  // ── Camera badge ──────────────────────────────────────────
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingIcon ? null : _pickAndUploadIcon,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick action tiles (Set Icon, Add Members) ────────────────────────────

  Widget _buildGroupActions(Map<String, String> currentMembers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'GROUP ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          _ActionCard(
            children: [
              _ActionTile(
                icon: Icons.camera_alt_outlined,
                color: AppTheme.primaryColor,
                label: 'Set Group Icon',
                onTap: _isUploadingIcon ? () {} : _pickAndUploadIcon,
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.person_add_alt_1_outlined,
                color: const Color(0xFF43A047),
                label: 'Add Members',
                onTap: () => _showAddMembersSheet(currentMembers),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Members list ──────────────────────────────────────────────────────────

  SliverList _buildMembersSection(Map<String, String> members) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            '${members.length} MEMBER${members.length == 1 ? '' : 'S'}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        if (members.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Loading members…',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ActionCard(
              children: [
                for (int i = 0; i < members.length; i++) ...[
                  _MemberTile(
                    name: members.values.elementAt(i),
                    uid: members.keys.elementAt(i),
                    photoUrl: _memberPhotos[members.keys.elementAt(i)] ?? '',
                  ),
                  if (i < members.length - 1) const _Divider(),
                ],
              ],
            ),
          ),
      ]),
    );
  }

  // ── Danger zone ───────────────────────────────────────────────────────────

  Widget _buildDangerZone() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'DANGER ZONE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.red,
              ),
            ),
          ),
          _ActionCard(
            children: [
              _ActionTile(
                icon: Icons.delete_outline,
                color: Colors.red,
                label: 'Delete Group',
                labelColor: Colors.red,
                onTap: _confirmDeleteGroup,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helper widgets
// ══════════════════════════════════════════════════════════════════════════════

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: labelColor ?? AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.name,
    required this.uid,
    this.photoUrl = '',
  });

  final String name;
  final String uid;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          photoUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(photoUrl),
                )
              : CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.grey.withValues(alpha: 0.15),
      indent: 66,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Add Members Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _AddMembersSheet extends StatefulWidget {
  const _AddMembersSheet({
    required this.candidates,
    required this.groupId,
    required this.groupChatRepository,
  });

  final List<AppUser> candidates;
  final String groupId;
  final GroupChatRepository groupChatRepository;

  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  final Set<String> _selected = {};
  bool _isAdding = false;

  Future<void> _confirmAdd() async {
    if (_selected.isEmpty) return;
    setState(() => _isAdding = true);
    try {
      await widget.groupChatRepository.addMembersToGroup(
        groupId: widget.groupId,
        newMemberIds: _selected.toList(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add members: $e')),
        );
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, controller) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Add Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_selected.isNotEmpty)
                    _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _confirmAdd,
                            child: const Text('Add'),
                          ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // User list
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: widget.candidates.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 72,
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
                itemBuilder: (_, index) {
                  final user = widget.candidates[index];
                  final isSelected = _selected.contains(user.uid);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        val == true
                            ? _selected.add(user.uid)
                            : _selected.remove(user.uid);
                      });
                    },
                    title: Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    activeColor: AppTheme.primaryColor,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
