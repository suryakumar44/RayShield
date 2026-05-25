import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:user_app/indexpage.dart';
import 'package:user_app/main.dart'; // Imports the global 'supabase' client instance

class MyAppointments extends StatefulWidget {
  const MyAppointments({super.key});

  @override
  State<MyAppointments> createState() => _MyAppointmentsState();
}

class _MyAppointmentsState extends State<MyAppointments> {
  final supabase = Supabase.instance.client;

  // Standard Theme Palette matching the other pages
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  Future<void> _cancelAppointment(String appointmentId) async {
    // 1. Confirm with the user
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: const Text("Cancel Appointment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to cancel this appointment?", 
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm != true) return;

    // 2. Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: accentColor)),
    );

    try {
      // 3. Update Supabase
      await supabase
          .from('tbl_appoinment')
          .update({'appoinment_status': 'cancelled'})
          .eq('appoinment_id', appointmentId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment Cancelled"), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"), 
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Instead of destroying the stack, cleanly replace it or push standardly
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => IndexPage()),
              );
            }
          }
        ),
        title: const Text(
          "My Schedule",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('tbl_appoinment')
            .stream(primaryKey: ['appoinment_id'])
            .eq('user_id', userId ?? '')
            .order('appoinment_date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error fetching data",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final item = appointments[index];
              return FutureBuilder(
                future: supabase
                    .from('tbl_dermatologist')
                    .select('dermatologist_name')
                    .eq('dermatologist_id', item['dermatologist_id'])
                    .maybeSingle(),
                builder: (context, drSnapshot) {
                  String drName = drSnapshot.hasData && drSnapshot.data != null
                      ? drSnapshot.data!['dermatologist_name']
                      : "Dermatologist";

                  return _buildAppointmentCard(item, drName);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data, String drName) {
    final String status = data['appoinment_status'] ?? 'Pending';
    final String dateStr = data['appoinment_date'] ?? '';
    final String timeStr = data['appoinment_time'] ?? '';
    final DateTime? parsedDate = DateTime.tryParse(dateStr);

    final String day = parsedDate != null
        ? DateFormat('dd').format(parsedDate)
        : '--';
    final String month = parsedDate != null
        ? DateFormat('MMM').format(parsedDate).toUpperCase()
        : '---';

    final bool isPending = status.toLowerCase() == 'pending';
    final bool isAccepted = status.toLowerCase() == 'accepted' || status.toLowerCase() == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Box Column
                Column(
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Main Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "REF #${data['appoinment_id']}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Dr. $drName",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            color: Colors.white.withOpacity(0.3),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TARGET FIX: Action Bar for Pending or Accepted/Confirmed Requests
          if (isPending || isAccepted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.03))),
              ),
              child: Row(
                children: [
                  Icon(
                    isPending ? Icons.history_toggle_off : Icons.check_circle_outline_rounded,
                    color: isPending ? const Color.fromARGB(255, 148, 148, 148) : Colors.greenAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPending ? "Awaiting doctor's response" : "Appointment confirmed",
                    style: TextStyle(
                      color: isPending ? const Color.fromARGB(255, 148, 148, 148) : Colors.greenAccent, 
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _cancelAppointment(data['appoinment_id'].toString()),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      isPending ? "Cancel Request" : "Cancel ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live indicator pulse dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return Colors.greenAccent; // Green for success
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent; // Red for failure/cancellation
      case 'pending':
        return Colors.orangeAccent; // Orange for waiting
      default:
        return accentColor; // Theme Accent Cyan for other custom states
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 60,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Appointments",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Your scheduled consultations will appear here",
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }
}