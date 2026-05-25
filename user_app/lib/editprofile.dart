import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:user_app/main.dart'; 

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  // Theme Constants
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController contactcontroller = TextEditingController();

  Uint8List? _webImage;
  PlatformFile? _pickedFile;
  String? currentImageUrl; // To store the existing photo URL

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Load current data on startup
  }

  // --- Fetch Existing Data ---
  Future<void> fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        namecontroller.text = data['user_name'] ?? "";
        emailcontroller.text = data['user_email'] ?? "";
        contactcontroller.text = data['user_contact'] ?? "";
        currentImageUrl = data['user_photo']; // Set the current image URL
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // --- Image Picker Logic ---
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          _webImage = _pickedFile!.bytes;
        });
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }

  // --- Update Profile Logic ---
  Future<void> updateProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? imageUrl;

      // 1. Upload new image if a NEW one was picked
      if (_webImage != null && _pickedFile != null) {
        final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
        final path = 'user_photos/$fileName';

        await supabase.storage.from('user').uploadBinary(path, _webImage!);
        imageUrl = supabase.storage.from('user').getPublicUrl(path);
      }

      // 2. Prepare Update Data
      Map<String, dynamic> updateData = {
        'user_name': namecontroller.text,
        'user_email': emailcontroller.text,
        'user_contact': contactcontroller.text,
      };

      // Only update photo column if a new image was uploaded
      if (imageUrl != null) {
        updateData['user_photo'] = imageUrl;
      }

      // 3. Update Database
      await supabase.from('tbl_user').update(updateData).eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully"), backgroundColor: accentColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile"), backgroundColor: Colors.redAccent),
      );
    }
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
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // --- PROFILE IMAGE DISPLAY ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                        color: cardColor,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: _webImage != null
                            ? Image.memory(_webImage!, fit: BoxFit.cover) // Show newly picked image
                            : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                                ? Image.network(currentImageUrl!, fit: BoxFit.cover) // Show existing DB image
                                : const Icon(Icons.person, color: Colors.white24, size: 80), // Fallback icon
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              _buildTextField(namecontroller, "Full Name", Icons.person_outline),
              const SizedBox(height: 20),
              _buildTextField(emailcontroller, "Email Address", Icons.email_outlined, isEmail: true),
              const SizedBox(height: 20),
              _buildTextField(contactcontroller, "Contact Number", Icons.phone_android_outlined, isNumber: true),
              
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "UPDATE PROFILE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isEmail = false, bool isNumber = false, }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        ),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accentColor.withOpacity(0.7), size: 20),
            filled: true,
            fillColor: cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: accentColor),
            ),
          ),
        ),
      ],
    );
  }
}