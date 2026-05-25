import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/main.dart';
import 'package:user_app/payment.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int cartQuantity = 0;
  int stockQuantity = 0;
  bool isOutOfStock = false;

  int _currentImageIndex = 0;

  Map<String, dynamic>? detailedProduct;
  List<dynamic> _productReviews = [];
  double _averageRating = 0.0;
  bool _isButtonLoading = false;

  // Standard Theme Palette matching the other pages
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  @override
  void initState() {
    super.initState();
    detailedProduct = widget.product;
    _loadAllProductData();
  }

  Future<void> _loadAllProductData() async {
    final productId = widget.product['product_id'];
    if (productId == null) return;

    await Future.wait([
      fetchProductStatus(productId),
      _fetchMissingRelations(productId),
      _fetchProductReviews(productId),
    ]);
  }

  String getFullImageUrl(String path) {
    if (path.isEmpty || path == "NULL") return "";
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return supabase.storage.from('rating').getPublicUrl(path);
  }

  Future<void> _fetchMissingRelations(dynamic productId) async {
    try {
      final cleanProductId = int.tryParse(productId.toString()) ?? productId;

      final basicData = await supabase
          .from('tbl_product')
          .select('*, tbl_category(category_name), tbl_gallery(gallery_file)')
          .eq('product_id', cleanProductId)
          .maybeSingle();

      if (basicData != null) {
        if (mounted) {
          setState(() {
            detailedProduct = Map<String, dynamic>.from(basicData);
          });
        }

        final updatedProduct = Map<String, dynamic>.from(detailedProduct!);

        try {
          if (updatedProduct['type_id'] != null) {
            final typeData = await supabase
                .from('tbl_type')
                .select('type_name')
                .eq('type_id', updatedProduct['type_id'])
                .maybeSingle();
            if (typeData != null) {
              updatedProduct['tbl_type'] = typeData;
            }
          }
        } catch (e) {
          debugPrint("Safe fetch tbl_type relational fallback: $e");
        }

        try {
          if (updatedProduct['level_id'] != null) {
            final levelData = await supabase
                .from('tbl_level')
                .select('level_name')
                .eq('level_id', updatedProduct['level_id'])
                .maybeSingle();
            if (levelData != null) {
              updatedProduct['tbl_level'] = levelData;
            }
          }
        } catch (e) {
          debugPrint("Safe fetch tbl_level relational fallback: $e");
        }

        try {
          final heatId = updatedProduct['heatabsorption_id'] ?? updatedProduct['heatabsourption_id'];
          if (heatId != null) {
            final String tableName = updatedProduct['heatabsourption_id'] != null ? 'tbl_heatabsourption' : 'tbl_heatabsorption';
            final String colId = updatedProduct['heatabsourption_id'] != null ? 'heatabsourption_id' : 'heatabsorption_id';
            final String colName = updatedProduct['heatabsourption_id'] != null ? 'heatabsourption_name' : 'heatabsorption_name';

            final heatData = await supabase
                .from(tableName)
                .select(colName)
                .eq(colId, heatId)
                .maybeSingle();
            if (heatData != null) {
              updatedProduct['tbl_heatabsorption'] = heatData;
              updatedProduct['tbl_heatabsourption'] = heatData;
            }
          }
        } catch (e) {
          debugPrint("Safe fetch tbl_heatabsorption relational fallback: $e");
        }

        if (mounted) {
          setState(() {
            detailedProduct = updatedProduct;
          });
        }
      }
    } catch (e) {
      debugPrint("General relational metadata loader failed: $e");
    }
  }

  Future<void> fetchProductStatus(dynamic productId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final cleanProductId = int.tryParse(productId.toString()) ?? productId;

      final cartResponse = await supabase
          .from('tbl_cart')
          .select('cart_quantity,cart_status')
          .eq('cart_status', 2)
          .eq('product_id', cleanProductId);

      final int cartsum = (cartResponse as List<dynamic>?)?.fold<int>(
            0,
            (total, item) => total + (int.tryParse(item['cart_quantity'].toString()) ?? 0),
          ) ?? 0;

      final stockResponse = await supabase
          .from('tbl_stock')
          .select('stock_count')
          .eq('product_id', cleanProductId);

      final int stockSum = (stockResponse as List<dynamic>?)?.fold<int>(
            0,
            (total, item) => total + (int.tryParse(item['stock_count'].toString()) ?? 0),
          ) ?? 0;

      if (mounted) {
        setState(() {
          final int availableStock = stockSum - cartsum;
          cartQuantity = cartsum;
          stockQuantity = availableStock;
          isOutOfStock = stockQuantity <= 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching product status: $e");
    }
  }

  Future<void> _fetchProductReviews(dynamic productId) async {
    try {
      final cleanProductId = int.tryParse(productId.toString()) ?? productId;

      final response = await supabase
          .from('tbl_rating')
          .select('*, tbl_user(user_name, user_photo)')
          .eq('product_id', cleanProductId)
          .order('rating_datetime', ascending: false); // Order reviews newest first

      if (response != null && mounted) {
        final List<dynamic> reviews = response as List<dynamic>;
        double totalStars = 0.0;

        for (var review in reviews) {
          final int ratingVal = int.tryParse((review['rating_value'] ?? review['rating'] ?? 0).toString()) ?? 0;
          totalStars += ratingVal;
        }

        setState(() {
          _productReviews = reviews;
          _averageRating = reviews.isNotEmpty ? totalStars / reviews.length : 0.0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching product reviews: $e");
    }
  }

  Future<void> _addToCart(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null || detailedProduct == null) return;

    try {
      setState(() => _isButtonLoading = true);

      final List<dynamic> bookingsResponse = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id);

      Map<String, dynamic>? activeBooking;
      for (var b in bookingsResponse) {
        final status = b['booking_status'];
        if (status == null || status == 0 || status == '0' || status.toString().toLowerCase() == 'pending') {
          activeBooking = Map<String, dynamic>.from(b);
          break;
        }
      }

      int bookingId;
      if (activeBooking != null) {
        bookingId = activeBooking['booking_id'];
        final existing = await supabase
            .from('tbl_cart')
            .select()
            .eq('booking_id', bookingId)
            .eq('product_id', detailedProduct!['product_id'])
            .maybeSingle();

        if (existing != null) {
          setState(() => _isButtonLoading = false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Already in cart"),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } else {
        final nb = await supabase
            .from('tbl_booking')
            .insert({
              'user_id': user.id,
              'booking_status': 0,
              'booking_amount': 0,
              'booking_date': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        bookingId = nb['booking_id'];
      }

      await supabase.from('tbl_cart').insert({
        'booking_id': bookingId,
        'product_id': detailedProduct!['product_id'],
        'cart_quantity': 1,
        'cart_status': 0,
      });

      setState(() => _isButtonLoading = false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to cart"),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      fetchProductStatus(detailedProduct!['product_id']);
    } catch (e) {
      debugPrint("Cart error: $e");
      if (mounted) setState(() => _isButtonLoading = false);
    }
  }

  Future<void> _buyNow(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null || detailedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This product is out of stock"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => _isButtonLoading = true);
      int? bookingId;
      int totalAmount = int.parse(detailedProduct!['product_price'].toString());

      final List<dynamic> bookingsResponse = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id);

      Map<String, dynamic>? activeBooking;
      for (var b in bookingsResponse) {
        final status = b['booking_status'];
        if (status == null || status == 0 || status == '0' || status.toString().toLowerCase() == 'pending') {
          activeBooking = Map<String, dynamic>.from(b);
          break;
        }
      }

      if (activeBooking != null) {
        bookingId = activeBooking['booking_id'];
        
        final existing = await supabase
            .from('tbl_cart')
            .select()
            .eq('booking_id', bookingId!)
            .eq('product_id', detailedProduct!['product_id'])
            .maybeSingle();

        if (existing == null) {
          await supabase.from('tbl_cart').insert({
            'booking_id': bookingId,
            'product_id': detailedProduct!['product_id'],
            'cart_quantity': 1, 
            'cart_status': 0,
          });
        }
      } else {
        final newBooking = await supabase
            .from('tbl_booking')
            .insert({
              'user_id': user.id,
              'booking_status': 0,
              'booking_date': DateTime.now().toIso8601String(),
              'booking_amount': 0,
            })
            .select()
            .single();

        bookingId = newBooking['booking_id'];

        await supabase.from('tbl_cart').insert({
          'booking_id': bookingId,
          'product_id': detailedProduct!['product_id'],
          'cart_quantity': 1, 
          'cart_status': 0,
        });
      }

      setState(() => _isButtonLoading = false);

      if (mounted && bookingId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentGatewayScreen(
              id: bookingId!,
              amt: totalAmount,
            ),
          ),
        );
        fetchProductStatus(detailedProduct!['product_id']);
      }
    } catch (e) {
      debugPrint("Buy Now error: $e");
      if (mounted) setState(() => _isButtonLoading = false);
    }
  }

  void _openImageLightbox(Map<String, dynamic> review) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        final rawUserDetail = review['tbl_user'];
        final Map<String, dynamic> userDetail = rawUserDetail is List 
            ? (rawUserDetail.isNotEmpty ? Map<String, dynamic>.from(rawUserDetail.first) : {})
            : (rawUserDetail is Map ? Map<String, dynamic>.from(rawUserDetail) : {});

        final userName = userDetail['user_name'] ?? 'Verified Customer';
        final userPhoto = userDetail['user_photo'] ?? '';
        final int ratingValue = int.tryParse((review['rating_value'] ?? review['rating'] ?? 5).toString()) ?? 5;
        final String content = review['rating_content'] ?? 'No written thoughts left.';

        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: Image.network(
                      getFullImageUrl(review['rating_image'].toString()),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: accentColor));
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(40),
                        color: cardColor,
                        child: const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white10,
                            backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                            child: userPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 18) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      Icons.star_rounded,
                                      color: index < ratingValue ? Colors.amber : Colors.white12,
                                      size: 14,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        content,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProduct = detailedProduct ?? widget.product;
    final String name = currentProduct['product_name'] ?? 'Product';
    final String price = "₹${currentProduct['product_price'] ?? '0'}";
    final String description = currentProduct['product_description'] ?? "No description available.";
    
    final String category = currentProduct['tbl_category']?['category_name'] ?? "General";
    final String skinType = currentProduct['tbl_type']?['type_name'] ?? "All Types";
    final String heatAbsorb = currentProduct['tbl_heatabsourption']?['heatabsourption_name'] ??
                              currentProduct['tbl_heatabsorption']?['heatabsorption_name'] ?? 
                              "Normal";
    final String heatLevel = currentProduct['tbl_level']?['level_name'] ?? "Unknown";

    List<String> allImages = [];
    if (currentProduct['product_photo'] != null &&
        currentProduct['product_photo'].toString().isNotEmpty) {
      allImages.add(currentProduct['product_photo'].toString());
    }

    if (currentProduct['tbl_gallery'] != null) {
      final List galleryItems = currentProduct['tbl_gallery'] is List
          ? currentProduct['tbl_gallery']
          : [currentProduct['tbl_gallery']];
      for (var item in galleryItems) {
        final String? url = item['gallery_file'];
        if (url != null && url.isNotEmpty && !allImages.contains(url)) {
          allImages.add(url);
        }
      }
    }

    if (_currentImageIndex >= allImages.length) {
      _currentImageIndex = 0;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: cardColor,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: accentColor,
                size: 18,
              ),
            ),
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: cardColor,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: cardColor,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 360,
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.05),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: allImages.isNotEmpty
                          ? Image.network(
                              allImages[_currentImageIndex],
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: cardColor,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white24,
                                size: 60,
                              ),
                            ),
                    ),
                  ),

                  if (allImages.length > 1)
                    Positioned(
                      left: 20,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _currentImageIndex =
                                  (_currentImageIndex - 1 + allImages.length) %
                                  allImages.length;
                            });
                          },
                        ),
                      ),
                    ),

                  if (allImages.length > 1)
                    Positioned(
                      right: 20,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _currentImageIndex =
                                  (_currentImageIndex + 1) % allImages.length;
                            });
                          },
                        ),
                      ),
                    ),

                  if (allImages.length > 1)
                    Positioned(
                      bottom: 35,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(allImages.length, (dotIndex) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == dotIndex ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == dotIndex
                                  ? accentColor
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildReviewSummaryHeader(),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOutOfStock
                                ? Colors.red.withOpacity(0.3)
                                : const Color(0xFF4CAF50).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          isOutOfStock ? "NO STOCK" : "$stockQuantity AVAILABLE",
                          style: TextStyle(
                            color: isOutOfStock
                                ? Colors.red
                                : const Color(0xFF4CAF50),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildRefinedChip(Icons.face, skinType),
                        _buildRefinedChip(Icons.wb_sunny_outlined, heatAbsorb),
                        _buildRefinedChip(Icons.local_fire_department, heatLevel),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "About this product",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 35),

                  _buildReviewsListSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgColor.withOpacity(0),
              bgColor.withOpacity(0.8),
              bgColor,
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            if (isOutOfStock) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Out of stock"),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              _addToCart(context);
            }
          },
          child: _isButtonLoading
              ? const Center(child: CircularProgressIndicator(color: accentColor))
              : Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: OutlinedButton(
                          onPressed: () => _addToCart(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: accentColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("ADD TO CART", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => _buyNow(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("BUY NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildReviewSummaryHeader() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          _averageRating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "(${_productReviews.length} Reviews)",
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
      ],
    );
  }

  // Refactored single review item into its own method for reuse
  Widget _buildSingleReviewItem(Map<String, dynamic> review) {
    final rawUserDetail = review['tbl_user'];
    final Map<String, dynamic> userDetail = rawUserDetail is List 
        ? (rawUserDetail.isNotEmpty ? Map<String, dynamic>.from(rawUserDetail.first) : {})
        : (rawUserDetail is Map ? Map<String, dynamic>.from(rawUserDetail) : {});

    final String username = userDetail['user_name'] ?? "Verified Customer";
    final int ratingVal = int.tryParse((review['rating_value'] ?? review['rating'] ?? 0).toString()) ?? 0;
    final String comment = review['rating_content'] ?? "";
    final String? reviewImg = review['rating_image']?.toString();
    
    String reviewDate = "";
    if (review['rating_datetime'] != null) {
      try {
        final parsedDate = DateTime.parse(review['rating_datetime'].toString());
        reviewDate = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reviewDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reviewDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (starIdx) {
                  return Icon(
                    starIdx < ratingVal
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: starIdx < ratingVal
                        ? Colors.amber
                        : Colors.white12,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (reviewImg != null && reviewImg.isNotEmpty && reviewImg != "NULL") ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openImageLightbox(review),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 100,
                  width: 100,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  child: Image.network(
                    getFullImageUrl(reviewImg),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.broken_image,
                      color: Colors.white12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Opens a DraggableScrollableSheet with all reviews
  void _openAllReviewsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "All Reviews",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: _productReviews.length,
                      itemBuilder: (context, index) {
                        return _buildSingleReviewItem(_productReviews[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsListSection() {
    // Only show up to 3 reviews inline to keep it from getting messy
    final int displayCount = _productReviews.length > 3 ? 3 : _productReviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Customer Reviews",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        if (_productReviews.isEmpty)
          Text(
            "No reviews written yet for this item.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          )
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              return _buildSingleReviewItem(_productReviews[index]);
            },
          ),
          
          // View All Button
          if (_productReviews.length > 3)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: _openAllReviewsSheet,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: accentColor.withOpacity(0.3)),
                    ),
                  ),
                  child: Text(
                    "View All ${_productReviews.length} Reviews",
                    style: const TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRefinedChip(IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}