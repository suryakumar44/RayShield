import 'package:dematologist/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController retypePasswordController = TextEditingController();

  // Variables to track password visibility
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _retypePasswordVisible = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> changePass() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final UserResponse res = await supabase.auth.updateUser(
        UserAttributes(password: newPasswordController.text),
      );

      final response = await supabase
          .from('tbl_dermatologist')
          .select('dermatologist_password')
          .eq('dermatologist_id', user.id)
          .single();

      String dbPassword = response['dermatologist_password'];

      if (oldPasswordController.text != dbPassword) {
        _showErrorDialog("The old password you entered is incorrect.");
        return;
      }

      if (newPasswordController.text != retypePasswordController.text) {
        _showErrorDialog("New passwords do not match.");
        return;
      }

      if (newPasswordController.text.isEmpty) {
        _showErrorDialog("Password cannot be empty.");
        return;
      }

      await supabase
          .from('tbl_dermatologist')
          .update({'dermatologist_password': newPasswordController.text})
          .eq('dermatologist_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
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
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 0, 0, 0),
                Color.fromARGB(255, 0, 0, 0),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color.fromARGB(255, 37, 35, 35),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Updated calls with visibility state
                      _buildPasswordField(
                        "Old Password",
                        oldPasswordController,
                        _oldPasswordVisible,
                        () => setState(
                          () => _oldPasswordVisible = !_oldPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildPasswordField(
                        "New Password",
                        newPasswordController,
                        _newPasswordVisible,
                        () => setState(
                          () => _newPasswordVisible = !_newPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildPasswordField(
                        "Retype Password",
                        retypePasswordController,
                        _retypePasswordVisible,
                        () => setState(
                          () =>
                              _retypePasswordVisible = !_retypePasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: changePass,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated helper widget to include the eye icon toggle
  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback onToggle,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible, // If visibility is true, obscureText is false
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
