import 'package:dematologist/appoinments.dart';
import 'package:dematologist/main.dart';
import 'package:dematologist/myprofile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, dynamic>> appoinments = [];

  String name = "";
  String? photo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchuser();
    fetchAppointments();
  }

  // Fetches dermatologist profile using auth session ID
  Future<void> fetchuser() async {
    try {
      final dermatologist = supabase.auth.currentUser;
      if (dermatologist == null) return;

      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_id', dermatologist.id)
          .single();

      if (mounted) {
        setState(() {
          name = response['dermatologist_name'] ?? "Dermatologist";
          photo = response['dermatologist_photo'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  // Fetches appointments booked for this specific dermatologist
  Future<void> fetchAppointments() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_appoinment')
          .select('*, tbl_user(user_name, user_photo, user_contact)')
          .eq('dermatologist_id', user.id)
          .order('appoinment_date', ascending: false);

      if (mounted) {
        setState(() {
          appoinments = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Helper status checker matching your DB schemas
  bool _isConsulted(dynamic dbStatus) {
    final status = dbStatus?.toString().toLowerCase() ?? '';
    return status == 'consulted' || status == 'done' || status == 'completed' || status == '2';
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic metric calculations
    final pendingCount = appoinments.where((item) {
      final status = (item['appoinment_status'] ?? 'pending').toString().toLowerCase();
      return status == 'pending' || status == '0';
    }).length;
    
    // TARGET FIX: Calculate the accepted/approved appointments dynamically
    final acceptedCount = appoinments.where((item) {
      final status = (item['appoinment_status'] ?? '').toString().toLowerCase();
      return status == 'accepted' || status == 'approved' || status == '1';
    }).length;

    final doneCount = appoinments.where((item) {
      return _isConsulted(item['appoinment_status']);
    }).length;

    // Filter "Recent Consultations" to only show completed/consulted ones
    final completedConsultations = appoinments.where((item) {
      return _isConsulted(item['appoinment_status']);
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Welcome Header Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 110,
                    width: double.infinity,
                    color: Colors.black,
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dr. $name',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSettings()));
                          },
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white10,
                            backgroundImage: (photo != null && photo!.isNotEmpty) ? NetworkImage(photo!) : null,
                            child: (photo == null || photo!.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white54, size: 30)
                                : null,
                          ),
                        )
                      ],
                    ),
                  ),

                  // Notifications Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromARGB(255, 42, 40, 40),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.notifications_active, color: Colors.deepOrange),
                          ),
                          Text(
                            pendingCount > 0 
                                ? 'You have $pendingCount pending request(s)' 
                                : 'You have zero pending requests',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Interactive Metric Cards linking to targeted tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricCard(
                        Icons.calendar_today, 
                        Colors.lightBlueAccent, 
                        "$acceptedCount", // TARGET FIX: Changed from totalCount to acceptedCount
                        "Accepted", 
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentManagement(initialIndex: 1), // Index 1 is APPROVED
                          ),
                        ).then((_) => fetchAppointments()),
                      ),
                      _buildMetricCard(
                        Icons.more_horiz_rounded, 
                        Colors.orange, 
                        "$pendingCount", 
                        "pending", 
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentManagement(initialIndex: 0), // Index 0 is PENDING
                          ),
                        ).then((_) => fetchAppointments()),
                      ),
                      _buildMetricCard(
                        Icons.done, 
                        Colors.lightGreenAccent, 
                        "$doneCount", 
                        "done", 
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentManagement(initialIndex: 2), // Index 2 is CONSULTED
                          ),
                        ).then((_) => fetchAppointments()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Earnings Card UI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color.fromARGB(255, 255, 119, 0), Colors.orange],
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text('₹1500', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text('₹', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Recent Consultations',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Only shows patient records who have completed consultation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromARGB(255, 10, 10, 10),
                      ),
                      width: double.infinity,
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                            )
                          : completedConsultations.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40.0),
                                  child: Center(
                                    child: Text(
                                      "No completed consultations yet.",
                                      style: TextStyle(color: Colors.white38, fontSize: 14),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: completedConsultations.length,
                                  itemBuilder: (context, index) {
                                    final appointment = completedConsultations[index];
                                    final patient = appointment['tbl_user'];

                                    if (patient == null) return const SizedBox.shrink();

                                    final String pName = patient['user_name'] ?? 'Unknown';
                                    final String pContact = patient['user_contact'] ?? 'No Contact';
                                    final String? pPhoto = patient['user_photo'];
                                    
                                    return Container(
                                      margin: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 45, 43, 43),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      height: 80,
                                      width: double.infinity,
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CircleAvatar(
                                              radius: 25,
                                              backgroundImage: (pPhoto != null && pPhoto.isNotEmpty) ? NetworkImage(pPhoto) : null,
                                              child: (pPhoto == null || pPhoto.isEmpty)
                                                  ? const Icon(Icons.person, color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pName,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(pContact, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 12.0),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color: Colors.green,
                                              ),
                                              child: const Text(
                                                "CONSULTED",
                                                style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: const Color.fromARGB(255, 31, 255, 236),
          unselectedItemColor: Colors.white,
          backgroundColor: const Color.fromARGB(255, 35, 33, 33),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark_rounded), label: 'Board'),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentManagement()));
                },
                icon: const Icon(Icons.calendar_month),
              ),
              label: 'Visits',
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSettings()));
                },
                icon: const Icon(Icons.person),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Metric card builder accepting action callback parameter
  Widget _buildMetricCard(IconData icon, Color color, String value, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 42, 40, 40),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color.fromARGB(255, 185, 175, 175), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}