import 'package:dematologist/login.dart';
import 'package:dematologist/registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  static const Color cyan = Color.fromARGB(255, 38, 248, 255);
  static const Color bgBlack = Color(0xFF0A0A0F);

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
        backgroundColor: bgBlack,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Professional Dark Radial Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [Color(0xFF231B33), bgBlack],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(),
                    
                    // App Logo Placeholder
                    const Icon(Icons.medical_services_outlined, size: 80, color: cyan),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Dermatologist Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Manage your patients and schedule\nwith ease.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    
                    const Spacer(flex: 2),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Registration())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cyan,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Log in Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Login())),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: cyan, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Log in', style: TextStyle(fontWeight: FontWeight.bold, color: cyan, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}