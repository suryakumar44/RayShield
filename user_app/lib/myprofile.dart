import 'package:flutter/material.dart';
import 'package:user_app/changepassword.dart';
import 'package:user_app/complain.dart';
import 'package:user_app/editprofile.dart';
import 'package:user_app/indexpage.dart';
import 'package:user_app/login.dart'; // Ensure you import your login page
import 'package:user_app/main.dart';
import 'package:user_app/myorder.dart';

class Myprofile extends StatefulWidget {
  const Myprofile({super.key});
  @override
  State<Myprofile> createState() => _MyprofileState();
}

class _MyprofileState extends State<Myprofile> {
  String name = "";
  String email = "";
  String address = "";
  dynamic photo = "";
  String gender = "";
  String contact = "";

  // Theme Constants
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  @override
  void initState() {
    super.initState();
    fetchuser();
  }

  Future<void> fetchuser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        name = response['user_name'] ?? "No Name Found";
        email = response['user_email'] ?? "No Email Found";
        address = response['user_address'] ?? "No Address Found";
        photo = response['user_photo'] ?? "";
        gender = response['user_gender'] ?? "No Gender Found";
        contact = response['user_contact'] ?? "No Contact Found";
      });
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  // --- LOGOUT LOGIC ---
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        // pushAndRemoveUntil ensures the user cannot go back to the profile after logging out
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()), // Replace with your Login class
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PopupMenuButton<String>(
                      color: const Color(0xFF161B22),
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'support') {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Complaint(),));
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: 'support',
                            child: Row(
                              children: [
                                Icon(Icons.help_outline, color: Color.fromARGB(137, 255, 255, 255)),
                                SizedBox(width: 10),
                                Text('Support',style: TextStyle(color: Colors.white),),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Profile Picture Section
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                    ),
                  ),
                  CircleAvatar(
                    radius: 72,
                    backgroundColor: cardColor,
                    backgroundImage: (photo != null && photo.isNotEmpty)
                        ? NetworkImage(photo)
                        : const AssetImage('assets/clouds.jpg') as ImageProvider,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _buildInfoTile(Icons.location_on_rounded, "Address", address),
                    _buildDivider(),
                    _buildInfoTile(Icons.person_rounded, "Gender", gender),
                    _buildDivider(),
                    _buildInfoTile(Icons.phone_android_rounded, "Contact", contact),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const Editprofile()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text("EDIT PROFILE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const Changepassword()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("CHANGE PASSWORD", style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.2)),
                    ),
                  ),
                   const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersPage()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 29, 255, 255),
                        side: BorderSide(color: const Color.fromARGB(255, 13, 251, 255).withOpacity(0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("MY ORDERS", style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // --- NEW LOGOUT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: TextButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      label: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        ),
                      ),
                    ),
                    
                  ),
                  const SizedBox(height: 40)
                ],
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accentColor, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.05),
      indent: 70,
      endIndent: 20,
    );
  }
}