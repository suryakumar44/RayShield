import 'package:dematologist/changepassword.dart';
import 'package:dematologist/complain.dart';
import 'package:dematologist/editprofile.dart';
import 'package:dematologist/login.dart';
import 'package:dematologist/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  String name = "";
  String email = "";
  String address = "";
  String? photo;
  String gender = "";
  String contact = "";
  String specialization = "";
  String experience = "";

  Future<void> fetchderma() async {
    try {
      final dermatologist = supabase.auth.currentUser;
      if (dermatologist == null) return; // Guard clause

      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_id', dermatologist.id)
          .single();

      if (mounted) {
        setState(() {
          name = response['dermatologist_name'] ?? "Dermatologist";
          email = response['dermatologist_email'] ?? "No Email";
          specialization =
              response['dermatologist_specialization'] ?? "No Specialization";
          experience = response['dermatologist_experience'] ?? "No Experience";
          photo = response['dermatologist_photo'];
          print("Fetched Photo URL: $photo"); // Ensure it's not null
          contact = response['dermatologist_contact'] ?? "No Contact";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  void initState() {
    super.initState();
    fetchderma();
  }

  Future<void> handleLogout() async {
    try {
      // 1. Sign out from Supabase
      await supabase.auth.signOut();

      if (mounted) {
        // 2. Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logged out successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // 3. Clear navigation stack and go to Login
        // Replace 'LoginPage' with the actual name of your login widget
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              /// FIXED HEADER (Pinned at the top)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Profile Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Spacer(),
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
              ),

              /// SCROLLABLE CONTENT AREA
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      /// PROFILE IMAGE SECTION
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromARGB(255, 59, 255, 255).withOpacity(0.5),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 59, 255, 255).withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: const Color(0xFF161B22),
                                // Check if photo is NOT null and NOT empty
                                backgroundImage:
                                    (photo != null && photo!.isNotEmpty)
                                    ? NetworkImage(photo!)
                                    : null,
                                // Show an Icon if the image is missing
                                child: (photo == null || photo!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.white24,
                                      )
                                    : null,
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: const Color.fromARGB(255, 59, 255, 255),
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// INFO CARD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(Icons.person_outline, 'Name', name,),
                              const Divider(color: Colors.white10, height: 30),
                              _buildInfoRow(
                                Icons.medication_outlined,
                                'Specialization',
                                specialization,
                              ),
                              const Divider(color: Colors.white10, height: 30),
                              _buildInfoRow(
                                Icons.history_edu_outlined,
                                'Experience',
                                experience,
                              ),
                              const Divider(color: Colors.white10, height: 30),
                              _buildInfoRow(
                                Icons.email_outlined,
                                'Email',
                                email,
                              ),
                              const Divider(color: Colors.white10, height: 30),
                              _buildInfoRow(
                                Icons.phone_outlined,
                                'Contact',
                                contact,
                              ),
                              const Divider(color: Colors.white10, height: 30),
                              _buildInfoRow(
                                Icons.location_on_outlined,
                                'Location',
                                address,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// ACTIONS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildActionButton(
                              context,
                              'Edit Profile',
                              Icons.edit,
                              const [Color.fromARGB(255, 99, 254, 79), Color.fromARGB(255, 43, 255, 145)],
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Editprofile(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildActionButton(
                              
                              context,
                              'Reset Password',
                              Icons.lock_reset,
                              const [Color.fromARGB(255, 52, 211, 255), Color.fromARGB(255, 62, 162, 255)],
                              
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Changepassword(),
                                ),
                                
                              ),
                              
                            ),
                            const SizedBox(height: 15),
                            _buildActionButton(
                              context,
                              'Logout',
                              Icons.logout,
                              const [Color(0xFFff0844), Color(0xFFffb199)],
                              () {
                                // Show a confirmation dialog before logging out
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      title: const Text(
                                        "Logout",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        "Are you sure you want to logout?",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            ); // Close dialog
                                            handleLogout(); // Call the logout function
                                          },
                                          child: const Text(
                                            "Logout",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromARGB(255, 30, 255, 255), size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value.isEmpty ? 'Not Provided' : value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
