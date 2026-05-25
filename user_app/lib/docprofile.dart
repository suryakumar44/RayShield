import 'package:flutter/material.dart';
import 'package:user_app/appoinment.dart';

class DoctorProfile extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorProfile({super.key, required this.doctor});

  // Theme Constants to match your app
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 52, 240, 253);

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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image Header
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor, Colors.blue.withOpacity(0.5)],
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: bgColor,
                    backgroundImage: doctor['dermatologist_photo'] != null
                        ? NetworkImage(doctor['dermatologist_photo'])
                        : null,
                    child: doctor['dermatologist_photo'] == null
                        ? const Icon(Icons.person, color: Colors.white38, size: 60)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Name and Specialization
            Text(
              doctor['dermatologist_name'] ?? "Unknown Doctor",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Specialist Dermatologist",
              style: TextStyle(
                color: accentColor.withOpacity(0.8),
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 30),

            // Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.email_outlined, "Email", doctor['dermatologist_email'] ?? "Not available"),
                    const Divider(color: Colors.white10, height: 30),
                    _buildInfoRow(Icons.phone_outlined, "Contact", doctor['dermatologist_contact'] ?? "Not available"),
                    const Divider(color: Colors.white10, height: 30),
                    _buildInfoRow(Icons.location_on_outlined, "Location", "Medical Center, HQ"),
                    const Divider(color: Colors.white10, height: 30),
                    // Logic added here to fetch experience from Supabase data
                    _buildInfoRow(Icons.history_edu_outlined, "Experience", "${doctor['dermatologist_experience'] ?? '0'} Years"),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Appointment Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointment(doctor: doctor),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 49, 251, 234),
                    foregroundColor: const Color.fromARGB(255, 14, 14, 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 10,
                    shadowColor: accentColor.withOpacity(0.3),
                  ),
                  child: const Text(
                    "BOOK APPOINTMENT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color.fromARGB(255, 54, 254, 254), size: 20),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}