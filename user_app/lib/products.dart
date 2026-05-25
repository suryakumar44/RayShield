import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/main.dart';
import 'package:user_app/payment.dart'; // Ensure you have this import for PaymentGatewayScreen
import 'package:user_app/prodata.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFullProductList();
  }

  Future<void> fetchFullProductList() async {
    try {
      final response = await supabase.from('tbl_product').select();
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- Add to Cart Logic ---
Future<void> _addToCart(int productid) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {

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
            .eq('product_id', productid)
            .maybeSingle();

        if (existing != null) {
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
        'product_id': productid,
        'cart_quantity': 1,
        'cart_status': 0,
      });


      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to cart"),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      debugPrint("Cart error: $e");
    }
  }
  // --- Buy Now Logic ---
  Future<void> _buyNow(Map<String, dynamic> product) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _statusMessage("Please login first");
      return;
    }

    try {
      int? bookingId;
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id)
          .isFilter('booking_status', null)
          .maybeSingle();

      if (booking != null) {
        bookingId = booking['booking_id'];
      } else {
        final newBooking = await supabase.from('tbl_booking').insert({
          'user_id': user.id,
          'booking_status': null,
          'booking_date': DateTime.now().toIso8601String(),
          'booking_amount': 0,
        }).select().single();
        bookingId = newBooking['booking_id'];
      }

      await supabase.from('tbl_cart').insert({
        'booking_id': bookingId,
        'product_id': product['product_id'],
        'cart_quantity': '1',
        'cart_status': '0',
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentGatewayScreen(
              id: bookingId!,
              amt: int.parse(product['product_price'].toString()),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Buy Now error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Shop Products",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    child: _buildProductCard(product),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                product['product_photo'] ?? 'https://via.placeholder.com/150',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['product_name'] ?? 'Item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${product['product_price']}",
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        height: 35,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: () => _addToCart(product['product_id']),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 35,
                          child: ElevatedButton(
                            onPressed: () => _buyNow(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "BUY NOW",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _statusMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }
}