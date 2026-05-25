import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentManagement extends StatefulWidget {
  final int initialIndex;
  const AppointmentManagement({super.key, this.initialIndex = 0});

  @override
  State<AppointmentManagement> createState() => _AppointmentManagementState();
}

class _AppointmentManagementState extends State<AppointmentManagement> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  // Dark Theme Design Tokens consistent with the app ecosystem
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  @override
  void initState() {
    super.initState();
    // Initialize TabController with the initial index passed from Homepage metric cards
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Updates the appointment status in real-time
  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('tbl_appoinment') // Exact schema table name
          .update({'appoinment_status': newStatus})
          .eq('appoinment_id', id);
      
      if (!mounted) return;

      Color snackColor = accentColor;
      if (newStatus == 'rejected') {
        snackColor = Colors.redAccent;
      } else if (newStatus == 'consulted') {
        snackColor = Colors.greenAccent;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Marked as ${newStatus.toUpperCase()}"),
          backgroundColor: snackColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  // Unified status checker to handle status codes robustly
  bool _matchesStatus(dynamic dbStatus, String filter) {
    final status = dbStatus?.toString().toLowerCase() ?? '';
    if (filter == 'pending') {
      return status == 'pending' || status == '0' || status == '';
    } else if (filter == 'accepted') {
      return status == 'accepted' || status == 'approved' || status == '1';
    } else if (filter == 'consulted') {
      return status == 'consulted' || status == 'done' || status == 'completed' || status == '2';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Management", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          indicatorWeight: 3,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white24,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          tabs: const [
            Tab(text: "PENDING", icon: Icon(Icons.hourglass_empty_rounded, size: 20)),
            Tab(text: "APPROVED", icon: Icon(Icons.check_circle_outline_rounded, size: 20)),
            Tab(text: "CONSULTED", icon: Icon(Icons.history_edu_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('pending'),
          _buildAppointmentList('accepted'),
          _buildAppointmentList('consulted'),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(String statusFilter) {
    final drId = supabase.auth.currentUser?.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('tbl_appoinment') // Listens to real-time events from database
          .stream(primaryKey: ['appoinment_id'])
          .eq('dermatologist_id', drId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentColor));
        }

        final allAppointments = snapshot.data ?? [];
        
        // Dynamic matching filters
        final list = allAppointments.where((item) => 
          _matchesStatus(item['appoinment_status'], statusFilter)
        ).toList();

        // Sort programmatically on client-side to ensure Stream support across versions
        list.sort((a, b) {
          final dateA = a['appoinment_date']?.toString() ?? '';
          final dateB = b['appoinment_date']?.toString() ?? '';
          return dateA.compareTo(dateB);
        });

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 55, color: Colors.white10),
                const SizedBox(height: 16),
                Text(
                  "No ${statusFilter.toUpperCase()} appointments",
                  style: const TextStyle(color: Colors.white24, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            
            return FutureBuilder(
              future: supabase
                  .from('tbl_user')
                  .select()
                  .eq('user_id', item['user_id'])
                  .maybeSingle(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    height: 110,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.02)),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white12),
                      ),
                    ),
                  );
                }
                
                final user = userSnap.data ?? {};
                return _buildPatientRecordCard(item, user, statusFilter);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPatientRecordCard(Map<String, dynamic> appointment, Map<String, dynamic> user, String status) {
    final String pPhoto = user['user_photo'] ?? '';
    final String pName = user['user_name'] ?? 'Guest Patient';
    final String dateString = appointment['appoinment_date']?.toString().split('T')[0] ?? 'N/A';
    final String timeString = appointment['appoinment_time'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white10,
                backgroundImage: pPhoto.isNotEmpty ? NetworkImage(pPhoto) : null,
                child: pPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white38) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pName, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white38),
                        const SizedBox(width: 6),
                        Text(
                          "$dateString | $timeString", 
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons(appointment['appoinment_id'].toString(), status),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, String currentStatus) {
    if (currentStatus == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _actionBtn("ACCEPT", accentColor, Colors.black, () => _updateStatus(id, 'accepted')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn("REJECT", Colors.redAccent.withOpacity(0.1), Colors.redAccent, () => _updateStatus(id, 'rejected')),
          ),
        ],
      );
    } else if (currentStatus == 'accepted') {
      return _actionBtn("MARK AS CONSULTED", accentColor, Colors.black, () => _updateStatus(id, 'consulted'));
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              "CONSULTATION COMPLETED", 
              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }
  }

  Widget _actionBtn(String label, Color btnColor, Color txtColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: txtColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label, 
          style: TextStyle(color: txtColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}