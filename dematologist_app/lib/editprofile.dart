import 'dart:typed_data';

import 'package:dematologist/main.dart';
import 'package:dematologist/myprofile.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  TextEditingController nameController = TextEditingController(); 
  TextEditingController contactController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController specializationController = TextEditingController();
  TextEditingController experienceController = TextEditingController();
  TextEditingController proofController = TextEditingController();
  TextEditingController photoController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;
  file_picker.PlatformFile? pickedProof;
  Uint8List? proofBytes;

  String? photo;
  String name = "";
  String email = "";
  String address = "";
  String gender = "";
  String contact = "";
  String specialization = "";
  String experience = "";
  String? existingProofUrl;

  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker
        .FilePicker.pickFiles(type: file_picker.FileType.image, withData: true);

    if (result == null) return;

    setState(() {
      pickedImage = result.files.first;
      imageBytes = pickedImage!.bytes;
    });
  }

  // Picks the proof file (supports images and PDFs)
  Future<void> handleProofPick() async {
    file_picker.FilePickerResult? result =
        await file_picker.FilePicker.pickFiles(
          type: file_picker.FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true,
        );

    if (result == null) return;

    setState(() {
      pickedProof = result.files.first;
      proofBytes = pickedProof!.bytes;
      // Update the text field with the picked file name
      proofController.text = pickedProof!.name;
    });
  }

  /// PROOF UPLOAD
  Future<String?> proofUpload(String uid) async {
    try {
      if (proofBytes == null) return null;

      const bucketName = 'dermatologist';
      // Saves to a distinct folder: proof/uid.extension
      final filePath = "proof/$uid.${pickedProof!.extension}";

      // Set the content type dynamically based on the file extension
      String contentType = 'image/jpeg';
      if (pickedProof!.extension == 'pdf') {
        contentType = 'application/pdf';
      } else if (pickedProof!.extension == 'png') {
        contentType = 'image/png';
      }

      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            proofBytes!,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Proof upload error: ${e.toString()}");
      return null;
    }
  }

  /// PHOTO UPLOAD
  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'dermatologist';
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

  Future<void> fetchdermatologist() async {
    try {
      final user = supabase.auth.currentUser;

      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_id', user!.id)
          .single();

      setState(() {
        nameController.text = response['dermatologist_name'] ?? "";
        experienceController.text = response['dermatologist_experience'] ?? "";
        specializationController.text =
            response['dermatologist_specialization'] ?? "";
        // contactController.text = response['dermatologist_contact'] ?? "";
        proofController.text = response['dermatologist_proof'] ?? "";
        photo = response['dermatologist_photo'];
        existingProofUrl = response['dermatologist_proof'];
        if (existingProofUrl != null && existingProofUrl!.isNotEmpty) {
          proofController.text = "tap to pick proof";
        }
      });
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchdermatologist();
  }

  Future<void> updateDermatologist() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = supabase.auth.currentUser;
      print(user);

      if (user == null) return;

      if (pickedImage != null) {
        final photoUrl = await photoUpload(user.id);
        if (photoUrl != null) {
          photo = photoUrl;
        }
      }
      if (pickedProof != null) {
        final proofUrl = await proofUpload(user.id);
        if (proofUrl != null) {
          proofController.text = proofUrl;
        }
      }

      await supabase
          .from('tbl_dermatologist')
          .update({
            'dermatologist_name': nameController.text.trim(),
            'dermatologist_experience': experienceController.text.trim(),
            'dermatologist_specialization': specializationController.text
                .trim(),
            'dermatologist_proof': proofController.text.trim(),
            'dermatologist_photo': photo,
          })
          .eq('dermatologist_id', user.id);

      debugPrint("Profile updated successfully");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileSettings()),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> handleSave() async {
    setState(() => isLoading = true);
    try {
      final uid = supabase.auth.currentUser!.id;

      // Logic:
      // If proofBytes is NOT null, user picked a NEW file -> Upload it.
      // If proofBytes IS null, keep the existingProofUrl.
      String? finalProofUrl = existingProofUrl;

      if (proofBytes != null) {
        finalProofUrl = await proofUpload(uid);
      }

      await supabase
          .from('tbl_dermatologist')
          .update({
            'dermatologist_name': nameController.text,
            'dermatologist_proof':
                finalProofUrl, // Update with either new or old URL
            // ... other fields
          })
          .eq('dermatologist_id', uid);

      // ... handle success
    } catch (e) {
      // ... handle error
    } finally {
      setState(() => isLoading = false);
    }
  }
  final _cyanColor = const Color(0xFF38FFF8);
  final _darkBg = const Color(0xFF121212);
  final _cardBg = const Color(0xFF1E1E1E);

Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: _cyanColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _cyanColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.cyanAccent)),
        centerTitle: true,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: _cyanColor))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Avatar Section
                  Center(
                    child: GestureDetector(
                      onTap: handleImagePick,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _cyanColor, width: 3),
                              boxShadow: [
                                BoxShadow(color: _cyanColor.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
                              ],
                              image: imageBytes != null
                                  ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                                  : (photo != null && photo != "")
                                      ? DecorationImage(image: NetworkImage(photo!), fit: BoxFit.cover)
                                      : null,
                              color: _cardBg,
                            ),
                            child: (imageBytes == null && (photo == null || photo == ""))
                                ? Icon(Icons.person_add_alt_1_rounded, color: _cyanColor, size: 50)
                                : null,
                          ),
                          Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(color: _cyanColor, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(label: "Full Name", controller: nameController),
                        _buildTextField(label: "Specialization", controller: specializationController),
                        _buildTextField(label: "Experience", controller: experienceController),
                        _buildTextField(
                          label: "Proof Document",
                          controller: proofController,
                          readOnly: true,
                          onTap: handleProofPick,
                          suffixIcon: (existingProofUrl != null && proofBytes == null)
                              ? IconButton(
                                  icon: Icon(Icons.open_in_new, color: _cyanColor),
                                  onPressed: () async {
                                    final Uri url = Uri.parse(existingProofUrl!);
                                    try {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      debugPrint(e.toString());
                                    }
                                  },
                                )
                              : Icon(Icons.attach_file, color: Colors.white.withOpacity(0.3)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: updateDermatologist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyanColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 10,
                        shadowColor: _cyanColor.withOpacity(0.4),
                      ),
                      child: const Text(
                        "SAVE CHANGES",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  // ... (Original Logic methods like fetchdermatologist, updateDermatologist, etc.)
  // Note: Keep your existing fetchdermatologist and updateDermatologist logic here.
}

