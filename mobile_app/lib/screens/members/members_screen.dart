import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<User> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final res = await ApiService.get('/members');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['members'] ?? data['users'] ?? [];
        setState(() => _members = list.map((j) => User.fromJson(j)).toList());
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _scoreColor(int s) {
    if (s >= 750) return Colors.green;
    if (s >= 600) return Colors.blue;
    if (s >= 450) return Colors.orange;
    return Colors.red;
  }

  void _showAddMemberDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passwordC = TextEditingController();
    final phoneC = TextEditingController();
    final joinedC = TextEditingController();
    String role = 'member';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: passwordC, obscureText: true, decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: joinedC, decoration: const InputDecoration(labelText: 'Joined Date (YYYY-MM-DD)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('Member')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (nameC.text.isEmpty || emailC.text.isEmpty || passwordC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, email and password are required')));
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  final body = {
                    'name': nameC.text,
                    'email': emailC.text,
                    'password': passwordC.text,
                    'role': role,
                    if (phoneC.text.isNotEmpty) 'phone': phoneC.text,
                    if (joinedC.text.isNotEmpty) 'joined_date': joinedC.text,
                  };
                  final res = await ApiService.post('/members', body: body);
                  if (res.statusCode == 201 || res.statusCode == 200) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added!')));
                    _fetchMembers();
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setDialogState(() => saving = false);
                }
              },
              child: Text(saving ? 'Saving...' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMemberDialog(User member) {
    final nameC = TextEditingController(text: member.name);
    final emailC = TextEditingController(text: member.email);
    final phoneC = TextEditingController(text: member.phone ?? '');
    String role = member.role;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('Member')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  final body = {
                    'name': nameC.text,
                    'email': emailC.text,
                    'phone': phoneC.text,
                    'role': role,
                  };
                  final res = await ApiService.put('/members/${member.id}', body: body);
                  if (res.statusCode == 200) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member updated!')));
                    _fetchMembers();
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setDialogState(() => saving = false);
                }
              },
              child: Text(saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(User member) {
    final passwordC = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Reset Password: ${member.name}'),
          content: TextField(
            controller: passwordC,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password *', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (passwordC.text.isEmpty) return;
                setDialogState(() => saving = true);
                try {
                  final res = await ApiService.post('/members/${member.id}/reset-password', body: {'password': passwordC.text});
                  if (res.statusCode == 200) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset!')));
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setDialogState(() => saving = false);
                }
              },
              child: Text(saving ? 'Resetting...' : 'Reset'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(User member) async {
    try {
      final res = await ApiService.put('/members/${member.id}/toggle-active');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${member.name} ${member.isActive == 1 ? 'deactivated' : 'activated'}'),
        ));
        _fetchMembers();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _deleteMember(User member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await ApiService.delete('/members/${member.id}');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${member.name} deleted')));
        _fetchMembers();
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchMembers,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _members.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('${_members.length} Members', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              );
            }
            final m = _members[index - 1];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.isActive == 1 ? Colors.blue.shade100 : Colors.grey.shade200,
                  child: Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: m.isActive == 1 ? Colors.blue : Colors.grey),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.role == 'admin' ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.role.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: m.role == 'admin' ? Colors.purple : Colors.blue),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.email, style: const TextStyle(fontSize: 12)),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: _scoreColor(m.creditScore)),
                        const SizedBox(width: 4),
                        Text('${m.creditScore}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _scoreColor(m.creditScore))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: m.isActive == 1 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            m.isActive == 1 ? 'Active' : 'Inactive',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: m.isActive == 1 ? Colors.green : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'edit': _showEditMemberDialog(m); break;
                      case 'reset': _showResetPasswordDialog(m); break;
                      case 'toggle': _toggleActive(m); break;
                      case 'delete': _deleteMember(m); break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.key, size: 18), SizedBox(width: 8), Text('Reset Password')])),
                    PopupMenuItem(value: 'toggle', child: Row(children: [
                      Icon(m.isActive == 1 ? Icons.toggle_off : Icons.toggle_on, size: 18),
                      const SizedBox(width: 8),
                      Text(m.isActive == 1 ? 'Deactivate' : 'Activate'),
                    ])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
