import 'package:dematologist/homepage.dart';
import 'package:dematologist/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Added state variable for functional password toggle
  bool _isPasswordVisible = false;

  Future<void> loginDerma() async {
    try {
      final authResponse = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception("Login failed");
      }

      /// CHECK USER STATUS
      final response = await supabase
          .from('tbl_dermatologist')
          .select('dermatologist_status')
          .eq('dermatologist_id', user.id)
          .single();

      String? status = response['dermatologist_status'];

      if (status == "rejected") {
        /// BLOCKED
        await supabase.auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your account has been blocked by admin"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else if (status == "approved") {
        /// ALLOW LOGIN (Active or Pending but not blocked)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homepage()),
          );
        }
      } else if (status == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your account is pending for admin approval"),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F), // Deep black background
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Professional Dark Radial Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Color(0xFF231B33), // Subtle purple/dark accent
                      Color(0xFF0A0A0F), // Deep black
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Card(
                    elevation: 20,
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 450), // Responsive width
                      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141420), // Dark card background
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.2), // Cyan border
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Login Icon Badge
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.medical_services_outlined, // Changed icon to fit dermatologist
                                color: Color.fromARGB(255, 38, 248, 255), // Cyan
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Doctor Portal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to manage your appointments',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Email Field Container
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.3),
                                ),
                              ),
                              child: TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: "Email",
                                  labelStyle: TextStyle(color: Colors.white54),
                                  hintText: "Enter Email",
                                  hintStyle: TextStyle(color: Colors.white24),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  prefixIcon: Icon(Icons.mail_outline, color: Colors.white54),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field Container (With Functional Eye Icon)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.3),
                                ),
                              ),
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: !_isPasswordVisible, // Toggles based on state
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  hintText: "Enter password",
                                  hintStyle: const TextStyle(color: Colors.white24),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 38, 248, 255), // Cyan
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: loginDerma,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 38, 248, 255),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.5),
                                ),
                                child: const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Divider Text
                            Row(
                              children: const [
                                Expanded(child: Divider(thickness: 1, color: Colors.white12)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'Or sign in with',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ),
                                Expanded(child: Divider(thickness: 1, color: Colors.white12)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Social Options
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  child: const Icon(Icons.facebook, color: Colors.white, size: 26),
                                  color: const Color(0xFF1877F2),
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  child: Image.asset(
                                    'assets/google.png',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 30, color: Colors.white),
                                  ),
                                  color: const Color(0xFF1E1E2E),
                                  hasBorder: true,
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  child: const Icon(Icons.apple, color: Colors.white, size: 26),
                                  color: const Color(0xFF1E1E2E),
                                  hasBorder: true,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
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

  // Helper Widget for Social Buttons
  Widget _buildSocialButton({required Widget child, required Color color, bool hasBorder = false}) {
    return SizedBox(
      width: 72,
      height: 48,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: hasBorder ? 0 : 3,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasBorder ? const BorderSide(color: Colors.white12) : BorderSide.none,
          ),
        ),
        child: child,
      ),
    );
  }
}