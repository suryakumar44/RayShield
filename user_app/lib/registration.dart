import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemUiOverlayStyle
import 'package:user_app/main.dart';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/welcome.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController contactcontroller = TextEditingController();

  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController confirmpasswordcontroller = TextEditingController();

  // Added state variables for functional password toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  /// CORE LOGIC (Untouched)
  Future<void> insert() async {
    // 1. Validate Fields
    if (emailcontroller.text.isEmpty ||
        passwordcontroller.text.isEmpty ||
        namecontroller.text.isEmpty) {
      _showSnackBar("Please fill in all required fields", Colors.orangeAccent);
      return;
    }

    // 2. Email Validation
    bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(emailcontroller.text);
    if (!emailValid) {
      _showSnackBar("Please enter a valid email", Colors.redAccent);
      return;
    }

    // 3. Password Validation
    if (passwordcontroller.text.length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.redAccent);
      return;
    }

    // 4. Password Match
    if (passwordcontroller.text != confirmpasswordcontroller.text) {
      _showSnackBar("Passwords do not match", Colors.redAccent);
      return;
    }

    // --- Continue with registration logic ---
    try {
      final authResponse = await supabase.auth.signUp(
        email: emailcontroller.text.trim(),
        password: passwordcontroller.text.trim(),
      );

      final String? uid = authResponse.user?.id;
      if (uid == null) throw Exception("Registration failed.");

      String? profileImageUrl = await photoUpload(uid);
      await supabase.from('tbl_user').insert({
        'user_id': uid,
        'user_email': emailcontroller.text.trim(),
        'user_name': namecontroller.text.trim(),
        'user_contact': contactcontroller.text.trim(),
        'user_gender': _gender,
        'type_id': _selectedSkinType,
        'user_photo': profileImageUrl,
        'user_status': 'pending',
      });

      await supabase.auth.signOut();
      if (!mounted) return Navigator.pop(context);

      // 2. Show the success message
      _showSnackBar("Registration complete! Awaiting approval.", Colors.green);

      // 3. Navigate back to the Welcome page (or Login page)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Welcome()),
          (route) => false, // Clears the navigation stack
        );
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _skinTypes = [];
  String? _selectedSkinType;

  @override
  void initState() {
    super.initState();
    _fetchSkinTypes();
  }

  Future<void> _fetchSkinTypes() async {
    try {
      final response = await supabase.from('tbl_type').select();
      setState(() {
        _skinTypes = (response as List)
            .map(
              (item) => {
                'type_name': item['type_name'] as String,
                'type_id': item['type_id'] as int,
              },
            )
            .toList();
      });
    } catch (e) {
      print("Error fetching skin types: $e");
    }
  }

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;

  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker
        .FilePicker.pickFiles(type: file_picker.FileType.image, withData: true);

    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;

    setState(() {});
  }

  /// PHOTO UPLOAD (Untouched)
  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'User';
      final filePath = "profile/$uid.${pickedImage!.extension}";

      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  String? _gender;

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
            // Dark Radial Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Color(0xFF231B33), // Subtle dark purple accent
                      Color(0xFF0A0A0F), // Deep black
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Card(
                      elevation: 20,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 32.0,
                          horizontal: 24.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF141420,
                          ), // Dark card background
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color.fromARGB(
                              255,
                              38,
                              248,
                              255,
                            ).withOpacity(0.2), // Cyan accent border
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
                            mainAxisSize:
                                MainAxisSize.min, // Prevents overflow errors
                            children: [
                              // Registration Icon Badge
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      38,
                                      248,
                                      255,
                                    ).withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                        255,
                                        38,
                                        248,
                                        255,
                                      ).withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Color.fromARGB(
                                    255,
                                    38,
                                    248,
                                    255,
                                  ), // Cyan
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Create an Account',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Image Picker Avatar
                              GestureDetector(
                                onTap: handleImagePick,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF1E1E2E),
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            255,
                                            38,
                                            248,
                                            255,
                                          ).withOpacity(0.5),
                                          width: 2,
                                        ),
                                        image: imageBytes != null
                                            ? DecorationImage(
                                                image: MemoryImage(imageBytes!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: imageBytes == null
                                          ? const Icon(
                                              Icons.camera_alt_rounded,
                                              color: Colors.white54,
                                              size: 32,
                                            )
                                          : null,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          38,
                                          248,
                                          255,
                                        ), // Cyan accent
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF141420),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Name Field
                              _buildTextField(
                                controller: namecontroller,
                                label: "Name",
                                hint: "Enter full name",
                                icon: Icons.person_outline,
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              _buildTextField(
                                controller: emailcontroller,
                                label: "Email",
                                hint: "Enter email address",
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),

                              // Contact Field
                              _buildTextField(
                                controller: contactcontroller,
                                label: "Contact",
                                hint: "Enter phone number",
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),

                              // Gender Selection
                              Row(
                                children: [
                                  Expanded(child: _buildGenderRadio("Male")),
                                  Expanded(child: _buildGenderRadio("Female")),
                                  Expanded(child: _buildGenderRadio("Other")),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Skin Type Dropdown
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      38,
                                      248,
                                      255,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSkinType,
                                  dropdownColor: const Color(
                                    0xFF1E1E2E,
                                  ), // Dark dropdown menu
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white54,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: "Skin Type",
                                    labelStyle: TextStyle(
                                      color: Colors.white54,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  items: _skinTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type['type_id'].toString(),
                                      child: Text(type['type_name'] as String),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSkinType = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password Field with Toggle
                              _buildPasswordField(
                                controller: passwordcontroller,
                                label: "Password",
                                hint: "Enter password",
                                isVisible: _isPasswordVisible,
                                onToggle: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password Field with Toggle
                              _buildPasswordField(
                                controller: confirmpasswordcontroller,
                                label: "Confirm Password",
                                hint: "Re-enter password",
                                isVisible: _isConfirmPasswordVisible,
                                onToggle: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),

                              // Suggest Password Text
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 24.0,
                                  ),
                                  child: Text(
                                    "Suggest password",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(
                                        255,
                                        38,
                                        248,
                                        255,
                                      ).withOpacity(0.8), // Cyan
                                    ),
                                  ),
                                ),
                              ),

                              // Register Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: insert,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      38,
                                      248,
                                      255,
                                    ), // Cyan accent
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color.fromARGB(
                                      255,
                                      38,
                                      248,
                                      255,
                                    ).withOpacity(0.5),
                                  ),
                                  child: const Text(
                                    'Get Registered',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black, // High contrast
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Divider Text
                              Row(
                                children: const [
                                  Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      color: Colors.white12,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Text(
                                      'Or login with',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      color: Colors.white12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Social Options
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialButton(
                                    child: const Icon(
                                      Icons.facebook,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    color: const Color(0xFF1877F2),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildSocialButton(
                                    child: Image.asset(
                                      'assets/google.png',
                                      height: 24,
                                      width: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.g_mobiledata,
                                                size: 30,
                                                color: Colors.white,
                                              ),
                                    ),
                                    color: const Color(0xFF1E1E2E),
                                    hasBorder: true,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildSocialButton(
                                    child: const Icon(
                                      Icons.apple,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    color: const Color(0xFF1E1E2E),
                                    hasBorder: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  // Helper Widget for standard text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          prefixIcon: Icon(icon, color: Colors.white54),
        ),
      ),
    );
  }

  // Helper Widget for password fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 38, 248, 255).withOpacity(0.3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white54,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  // Helper Widget for Gender Radio buttons
  Widget _buildGenderRadio(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _gender,
          activeColor: const Color.fromARGB(255, 38, 248, 255),
          visualDensity: const VisualDensity(
            horizontal: VisualDensity.minimumDensity,
            vertical: VisualDensity.minimumDensity,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          fillColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return const Color.fromARGB(255, 38, 248, 255);
            }
            return Colors.white54;
          }),
          onChanged: (val) {
            setState(() {
              _gender = val;
            });
          },
        ),
        const SizedBox(width: 4), // Tiny gap
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Social Button Widget Helper (Matches Login Screen)
  Widget _buildSocialButton({
    required Widget child,
    required Color color,
    bool hasBorder = false,
  }) {
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
            side: hasBorder
                ? const BorderSide(color: Colors.white12)
                : BorderSide.none,
          ),
        ),
        child: child,
      ),
    );
  }
}
