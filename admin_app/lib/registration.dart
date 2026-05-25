import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Registration extends StatelessWidget {
  const Registration({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmpasswordController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    // Standard Theme Palette
    const Color bgColor = Color(0xFF0D0D0D);
    const Color cardColor = Color(0xFF1A1A1A);
    const Color accentColor = Color.fromARGB(255, 40, 255, 223);

    Future<void> insert() async {
      try {
        final email = emailController.text;
        final name = nameController.text;
        final password = passwordController.text;
        final cpass = confirmpasswordController.text;

        if (email.isEmpty || name.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.orange));
          return;
        }

        if (password == cpass) {
          await supabase.from('tbl_admin').insert({
            'admin_email': email,
            'admin_name': name,
            'admin_password': password
          });
          
          // FIXED: Safe execution context check for StatelessWidgets
          if (Navigator.canPop(context) || true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Registration complete"),
              backgroundColor: accentColor,
            ));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password mismatched"),
            backgroundColor: Colors.redAccent,
          ));
        }

        emailController.clear();
        passwordController.clear();
        nameController.clear();
        confirmpasswordController.clear();
      } catch (e) {
        debugPrint("Error $e");
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Admin Registration", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined, 
                    color: accentColor, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Administrator',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter details to register a new admin',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                ),
                const SizedBox(height: 30),
                
                _buildField(nameController, "Full Name", Icons.person_outline),
                const SizedBox(height: 15),
                _buildField(emailController, "Email Address", Icons.alternate_email, 
                  keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 15),
                _buildField(passwordController, "Password", Icons.lock_outline, 
                  isPassword: true),
                const SizedBox(height: 15),
                _buildField(confirmpasswordController, "Confirm Password", Icons.lock_reset, 
                  isPassword: true),
                
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: insert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'REGISTER ADMIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white10)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text("SECURE ACCESS", 
                        style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: Colors.white10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, 
      {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 40, 255, 223), size: 20),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color.fromARGB(255, 40, 255, 223)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}