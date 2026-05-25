import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/main.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController retypePasswordController = TextEditingController();

  // State variables to track password visibility
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isRetypePasswordVisible = false;

  Future<void> updatePassword() async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final retypePassword = retypePasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || retypePassword.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.redAccent);
      return;
    }

    if (newPassword != retypePassword) {
      _showSnackBar("New passwords do not match", Colors.redAccent);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.redAccent);
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final userData = await supabase
          .from('tbl_user')
          .select('user_password')
          .eq('user_id', user.id)
          .single();

      if (userData['user_password'] != oldPassword) {
        _showSnackBar("Old password is incorrect", Colors.redAccent);
        return;
      }

      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      await supabase
          .from('tbl_user')
          .update({'user_password': newPassword})
          .eq('user_id', user.id);

      _showSnackBar("Password updated successfully!", Colors.greenAccent);

      oldPasswordController.clear();
      newPasswordController.clear();
      retypePasswordController.clear();
    } catch (e) {
      debugPrint("Update Error: $e");
      _showSnackBar("Error: ${e.toString()}", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: color,
      ),
    );
  }

  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);
  static const Color fieldColor = Color(0xFF0D0D0D);

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
        title: const Text("Security", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withOpacity(0.1)),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: accentColor, size: 50),
              ),
              const SizedBox(height: 20),
              const Text("Update Password",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Ensure your account is using a strong password",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _buildPasswordField(
                      oldPasswordController,
                      "Old Password",
                      _isOldPasswordVisible,
                      () => setState(() => _isOldPasswordVisible = !_isOldPasswordVisible),
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      newPasswordController,
                      "New Password",
                      _isNewPasswordVisible,
                      () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      retypePasswordController,
                      "Retype Password",
                      _isRetypePasswordVisible,
                      () => setState(() => _isRetypePasswordVisible = !_isRetypePasswordVisible),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("UPDATE PASSWORD",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Updated helper widget
  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible, // Hide text if isVisible is false
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(Icons.vpn_key_outlined, color: accentColor.withOpacity(0.6), size: 20),
        
        // --- Added Suffix Icon Button ---
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white38,
            size: 20,
          ),
          onPressed: toggleVisibility,
        ),
        
        filled: true,
        fillColor: fieldColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor),
        ),
      ),
    );
  }
}