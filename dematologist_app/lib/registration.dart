import 'package:dematologist/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:supabase_flutter/supabase_flutter.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController contactcontroller = TextEditingController();
  TextEditingController specializationcontroller = TextEditingController();
  TextEditingController experiencecontroller = TextEditingController();
  TextEditingController proofcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController confirmpasswordcontroller = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;
  file_picker.PlatformFile? pickedProof;
  Uint8List? proofBytes;

  static const Color cyan = Color.fromARGB(255, 38, 248, 255);
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color cardBg = Color(0xFF141420);

  Future<void> insert() async {
    try {
      if (passwordcontroller.text == confirmpasswordcontroller.text) {
        final authResponse = await supabase.auth.signUp(
          email: emailcontroller.text,
          password: passwordcontroller.text,
        );

        final String? uid = authResponse.user?.id;
        if (uid == null) throw Exception("Registration failed.");

        String? profileImageUrl = await photoUpload(uid);
        String? proofUrl = await proofUpload(uid);

        await supabase.from('tbl_dermatologist').insert({
          'dermatologist_id': uid,
          'dermatologist_email': emailcontroller.text,
          'dermatologist_name': namecontroller.text,
          'dermatologist_password': passwordcontroller.text,
          'dermatologist_experience': experiencecontroller.text,
          'dermatologist_specilization': specializationcontroller.text,
          'dermatologist_proof': proofUrl,
          'dermatologist_photo': profileImageUrl,
          'dermatologist_status': 'pending',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration complete!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- Upload Helpers (Kept your logic) ---
  Future<void> handleImagePick() async {
    final result = await file_picker.FilePicker.pickFiles(type: file_picker.FileType.image, withData: true);
    if (result != null) setState(() { pickedImage = result.files.first; imageBytes = pickedImage!.bytes; });
  }

  Future<void> handleProofPick() async {
    final result = await file_picker.FilePicker.pickFiles(type: file_picker.FileType.custom, allowedExtensions: ['jpg', 'pdf'], withData: true);
    if (result != null) setState(() { pickedProof = result.files.first; proofBytes = pickedProof!.bytes; proofcontroller.text = pickedProof!.name; });
  }

  Future<String?> photoUpload(String uid) async {
    if (imageBytes == null) return null;
    final path = "profile/$uid.${pickedImage!.extension}";
    await supabase.storage.from('dermatologist').uploadBinary(path, imageBytes!);
    return supabase.storage.from('dermatologist').getPublicUrl(path);
  }

  Future<String?> proofUpload(String uid) async {
    if (proofBytes == null) return null;
    final path = "proof/$uid.${pickedProof!.extension}";
    await supabase.storage.from('dermatologist').uploadBinary(path, proofBytes!);
    return supabase.storage.from('dermatologist').getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(center: Alignment.topRight, radius: 1.2, colors: [Color(0xFF231B33), darkBg]),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: cyan.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.medical_services, size: 50, color: cyan),
                        const SizedBox(height: 16),
                        const Text("Doctor Registration", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        
                        // Inputs
                        _buildField(namecontroller, "Full Name", Icons.person_outline),
                        _buildField(emailcontroller, "Email", Icons.mail_outline, keyboard: TextInputType.emailAddress),
                        _buildField(specializationcontroller, "Specialization", Icons.medical_information_outlined),
                        _buildField(experiencecontroller, "Years of Experience", Icons.work_outline, keyboard: TextInputType.number),
                        _buildField(proofcontroller, "Upload Proof (PDF/JPG)", Icons.attach_file, readOnly: true, onTap: handleProofPick),
                        _buildPasswordField(passwordcontroller, "Password", _isPasswordVisible, () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                        _buildPasswordField(confirmpasswordcontroller, "Confirm Password", _isConfirmPasswordVisible, () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                        
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: insert,
                            style: ElevatedButton.styleFrom(backgroundColor: cyan, foregroundColor: Colors.black),
                            child: const Text("REGISTER", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboard, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: cyan),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool isVisible, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.lock_outline, color: cyan),
          suffixIcon: IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: cyan), onPressed: toggle),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}