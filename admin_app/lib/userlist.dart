import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Userlist extends StatefulWidget {
  const Userlist({super.key});

  @override
  State<Userlist> createState() => _UserlistState();
}

class _UserlistState extends State<Userlist> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 34, 255, 233);

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await supabase.from('tbl_user').select();
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateStatus(dynamic id, String status) async {
    await supabase
        .from('tbl_user')
        .update({'user_status': status})
        .eq('user_id', id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User marked as ${status.toUpperCase()}'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _users.where((u) => u['user_status'] == null || u['user_status'] == 'pending').toList();
    final approvedList = _users.where((u) => u['user_status'] == 'approved').toList();
    final rejectedList = _users.where((u) => u['user_status'] == 'rejected').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("User Records", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: "PENDING"),
              Tab(text: "APPROVED"),
              Tab(text: "REJECTED"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : TabBarView(
                children: [
                  _buildTableContainer(pendingList, "pending"),
                  _buildTableContainer(approvedList, "approved"),
                  _buildTableContainer(rejectedList, "rejected"),
                ],
              ),
      ),
    );
  }

  Widget _buildTableContainer(List<Map<String, dynamic>> data, String type) {
    if (data.isEmpty) {
      return Center(child: Text("No $type records.", style: const TextStyle(color: Colors.white24)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 1500,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.03)),
          columns: const [
            DataColumn(label: Text("SL.NO", style: TextStyle(color: accentColor))),
            DataColumn(label: Text("PHOTO", style: TextStyle(color: accentColor))),
            DataColumn(label: Text("NAME", style: TextStyle(color: accentColor))),
            DataColumn(label: Text("EMAIL", style: TextStyle(color: accentColor))),
            DataColumn(label: Text("CONTACT", style: TextStyle(color: accentColor))),
            DataColumn(label: Text("STATUS", style: TextStyle(color: accentColor))),
            DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor))),
          ],
          rows: data.asMap().entries.map((entry) {
            final user = entry.value;
            final currentStatus = user['user_status'] ?? 'pending';

            return DataRow(cells: [
              DataCell(Text("${entry.key + 1}", style: const TextStyle(color: Colors.white54))),
              DataCell(CircleAvatar(
                backgroundColor: Colors.white12,
                backgroundImage: user['user_photo'] != null ? NetworkImage(user['user_photo']) : null,
                child: user['user_photo'] == null ? const Icon(Icons.person, color: Colors.white54) : null,
              )),
              DataCell(Text(user['user_name'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
              DataCell(Text(user['user_email'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
              DataCell(Text(user['user_contact'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
              DataCell(_buildStatusChip(currentStatus)),
              DataCell(Row(children: [
                if (currentStatus != 'approved')
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                    onPressed: () => updateStatus(user['user_id'], 'approved'),
                  ),
                if (currentStatus != 'rejected')
                  IconButton(
                    icon: const Icon(Icons.highlight_off, color: Colors.redAccent),
                    onPressed: () => updateStatus(user['user_id'], 'rejected'),
                  ),
              ])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}