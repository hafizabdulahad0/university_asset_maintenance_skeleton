// File: lib/screens/admin/admin_dashboard_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/notification_badge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart' as app_models;
import '../../auth/profile_screen.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/hover_scale.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Complaint> _all = [];
  bool _firstLoad = true;
  int _total = 0, _unassigned = 0, _assigned = 0, _needsVer = 0, _closed = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final notifProv = context.read<NotificationProvider>();
    final oldIds = _all.map((c) => c.id).whereType<int>().toSet();
    final list = await SupabaseService.getAllComplaints();

    if (!_firstLoad) {
      for (var c in list) {
        if (c.id != null && !oldIds.contains(c.id)) {
          notifProv.add(
            title: 'New Complaint #${c.id}',
            body: 'Teacher ID ${c.teacherId} reported "${c.title}".',
          );
        }
      }
    }

    setState(() {
      _all = list;
      _total = list.length;
      _unassigned = list.where((c) => c.status == 'unassigned').length;
      _assigned = list.where((c) => c.status == 'assigned').length;
      _needsVer = list.where((c) => c.status == 'needs_verification').length;
      _closed = list.where((c) => c.status == 'closed').length;
    });

    _firstLoad = false;
  }

  Future<void> _assignDialog(Complaint c) async {
    final staffList = await SupabaseService.getStaffList();
    String? selectedStaffId;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Assign Complaint #${c.id}'),
        content: staffList.isEmpty
            ? const Text('No staff available')
            : DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Staff'),
                items: staffList
                    .map((app_models.User u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Text('${u.name} (${u.email})'),
                        ))
                    .toList(),
                onChanged: (v) => selectedStaffId = v,
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final id = selectedStaffId;
              if (id == null || id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a staff member')),
                );
                return;
              }
              try {
                await SupabaseService.assignComplaintToStaff(
                  complaintId: c.id!,
                  staffId: id,
                );
                final staff = await SupabaseService.getUserById(id);
                final staffName = staff?.name ?? 'unknown';
                context.read<NotificationProvider>().add(
                  title: 'Complaint Assigned',
                  body: 'Complaint #${c.id} assigned to $staffName.',
                );
                Navigator.pop(context);
                _reload();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assignment failed: ${e.toString()}')),
                );
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text(value.toString(),
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme     = context.watch<ThemeProvider>();
    final auth      = context.watch<AuthProvider>();
    final adminName = auth.user?.name ?? 'Admin';

    // Styles
    final headerStyle = Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(fontWeight: FontWeight.bold);
    final dataStyle   = Theme.of(context).textTheme.bodyMedium!;

    // Pick a contrasting heading row color
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: theme.isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => theme.toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Welcome header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Welcome, $adminName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            // Vertical stats cards
            HoverScale(child: _buildStatCard('Total',      _total,      Colors.blue)),
            HoverScale(child: _buildStatCard('Unassigned', _unassigned, Colors.orange)),
            HoverScale(child: _buildStatCard('Assigned',   _assigned,   Colors.indigo)),
            HoverScale(child: _buildStatCard('Needs Ver.', _needsVer,   Colors.purple)),
            HoverScale(child: _buildStatCard('Closed',     _closed,     Colors.green)),

            const Divider(thickness: 1, height: 32),

            // Complaints title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('All Complaints',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
            ),

            // Horizontal scrollable table
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(headingColor),
                  columns: [
                    DataColumn(label: Text('ID',      style: headerStyle)),
                    DataColumn(label: Text('Title',   style: headerStyle)),
                    DataColumn(label: Text('Teacher', style: headerStyle)),
                    DataColumn(label: Text('Staff',   style: headerStyle)),
                    DataColumn(label: Text('Status',  style: headerStyle)),
                    DataColumn(label: Text('Media',   style: headerStyle)),
                    DataColumn(label: Text('Actions', style: headerStyle)),
                  ],
                  rows: _all.map((c) => DataRow(cells: [
                    DataCell(Text('${c.id}', style: dataStyle)),
                    DataCell(Text(c.title,    style: dataStyle)),
                    DataCell(Text('${c.teacherId}', style: dataStyle)),
                    DataCell(Text(c.staffId?.toString() ?? '-', style: dataStyle)),
                    DataCell(Text(c.status.replaceAll('_', ' ').toUpperCase(),
                        style: dataStyle)),
                    DataCell(
                      c.mediaPath != null
                          ? (c.mediaIsVideo
                              ? Icon(Icons.videocam, color: Theme.of(context).primaryColor)
                              : Image.file(File(c.mediaPath!), width: 48, fit: BoxFit.cover))
                          : Text('-', style: dataStyle),
                    ),
                    DataCell(Row(
                      children: [
                        if (c.status == 'unassigned')
                          ElevatedButton(
                            onPressed: () => _assignDialog(c),
                            child: const Text('Assign',
                                style: TextStyle(fontSize: 12)),
                          ),
                        if (c.status == 'needs_verification')
                          ElevatedButton(
                            onPressed: () async {
                              c.status = 'closed';
                              await SupabaseService.updateComplaint(c);
                              context.read<NotificationProvider>().add(
                                title: 'Complaint Resolved',
                                body: 'Complaint #${c.id} closed.',
                              );
                              _reload();
                            },
                            child: const Text('Verify'),
                          ),
                      ],
                    )),
                  ])).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
