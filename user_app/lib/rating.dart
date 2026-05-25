import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRatingScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isUpdating;

  const ProductRatingScreen({
    super.key, 
    required this.product, 
    this.isUpdating = false,
  });

  @override
  State<ProductRatingScreen> createState() => _ProductRatingScreenState();
}

class _ProductRatingScreenState extends State<ProductRatingScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  int _ratingValue = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingExisting = false;

  // TARGET FIX: Added image picker variables
  XFile? _pickedImageFile;
  String? _existingImageUrl;

  // Theme Palette matching the other pages
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  @override
  void initState() {
    super.initState();
    if (widget.isUpdating) {
      _loadExistingReviewData();
    }
  }

  Future<void> _loadExistingReviewData() async {
    setState(() => _isLoadingExisting = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // TARGET FIX: Fetches rating_image column along with existing rating details
      final data = await supabase
          .from('tbl_rating')
          .select('rating_value, rating_content, rating_image')
          .eq('user_id', user.id)
          .eq('product_id', widget.product['product_id'])
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _ratingValue = int.tryParse(data['rating_value'].toString()) ?? 0;
          _reviewController.text = data['rating_content'] ?? '';
          _existingImageUrl = data['rating_image'];
        });
      }
    } catch (e) {
      debugPrint("Error loading existing review: $e");
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  // Pick an image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() {
          _pickedImageFile = image;
          _existingImageUrl = null; // Clear old URL state since we picked a new one
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_ratingValue == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a star rating before submitting.", style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User authentication missing.");
      }

      String? imageUrl = _existingImageUrl;

      // TARGET FIX: Upload picked image to Supabase 'rating' storage bucket and get publicUrl
      if (_pickedImageFile != null) {
        final fileBytes = await _pickedImageFile!.readAsBytes();
        final fileExtension = _pickedImageFile!.name.split('.').last;
        final fileName = "${user.id}_${widget.product['product_id']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension";

        await supabase.storage.from('rating').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: FileOptions(contentType: 'image/$fileExtension', upsert: true),
        );

        imageUrl = supabase.storage.from('rating').getPublicUrl(fileName);
      }

      // Upserting table rows cleanly with matching rating_image URL parameter
      await supabase.from('tbl_rating').upsert({
        'user_id': user.id,
        'product_id': widget.product['product_id'],
        'rating_value': _ratingValue,
        'rating_content': _reviewController.text.trim(),
        'rating_image': imageUrl, // Saves public storage link dynamically
        'rating_datetime': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,product_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isUpdating ? "Your review has been updated successfully!" : "Thank you for your feedback!", 
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Review submission failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submission failed. Please try again.", style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isUpdating ? 'Edit Review' : 'Write Review', 
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: cardColor,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: accentColor, size: 18),
            ),
          ),
        ),
      ),
      body: _isLoadingExisting
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  _buildProductHero(widget.product),
                  const SizedBox(height: 30),
                  
                  Text(
                    "How was your overall experience?",
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _ratingValue = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Icon(
                            index < _ratingValue ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: index < _ratingValue ? accentColor : Colors.white24,
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 35),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Write your thoughts (Optional)",
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Tell us what you liked or disliked about this item...",
                      hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
                      fillColor: cardColor,
                      filled: true,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: accentColor, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // TARGET FIX: Beautiful Image Picker section added with full preview capabilities
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Add Review Image (Optional)",
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImagePickerArea(),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        disabledBackgroundColor: accentColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : Text(
                              widget.isUpdating ? "Update Review" : "Submit Review",
                              style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Custom UI block displaying selected file previews
  Widget _buildImagePickerArea() {
    final bool hasImage = _pickedImageFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: hasImage ? null : _pickImage,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: hasImage
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _pickedImageFile != null
                          ? (kIsWeb
                              ? Image.network(_pickedImageFile!.path, fit: BoxFit.cover)
                              : Image.file(File(_pickedImageFile!.path), fit: BoxFit.cover))
                          : Image.network(_existingImageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _pickedImageFile = null;
                          _existingImageUrl = null;
                        });
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withOpacity(0.7),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: accentColor, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    "Tap to upload a product photo",
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProductHero(Map<String, dynamic> product) {
    final String? url = product['product_photo'];
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 110,
            width: 110,
            color: cardColor,
            child: (url != null && url.isNotEmpty)
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, color: Colors.white12, size: 40),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: Colors.white12, size: 40),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          product['product_name'] ?? 'Product Name',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Price: ₹${product['product_price']}",
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
        ),
      ],
    );
  }
}