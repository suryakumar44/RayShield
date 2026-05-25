import 'package:flutter/material.dart';
import 'package:user_app/indexpage.dart';
import 'package:user_app/main.dart';
import 'package:user_app/payment.dart';


class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _totalAmount = 0;
  int? _activeBookingId;

  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  Future<void> fetchCartData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id)
          .eq('booking_status', 0)
          .maybeSingle();

      if (booking == null) {
        setState(() {
          _cartItems = [];
          _isLoading = false;
          _totalAmount = 0;
        });
        return;
      }

      _activeBookingId = booking['booking_id'];

      final response = await supabase
          .from('tbl_cart')
          .select('*, tbl_product(*)')
          .eq('booking_id', _activeBookingId!);

      setState(() {
        _cartItems = List<Map<String, dynamic>>.from(response);
        _calculateTotal();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Cart Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      double price = double.parse(item['tbl_product']['product_price'].toString());
      int qty = int.parse(item['cart_quantity'].toString());
      total += (price * qty);
    }
    setState(() {
      _totalAmount = total;
    });
  }

  // --- Logic to Change Quantity ---
  Future<void> _updateQuantity(int cartId, int currentQty, bool isIncrement) async {
    int newQty = isIncrement ? currentQty + 1 : currentQty - 1;
    
    if (newQty < 1) return; // Prevent quantity less than 1

    try {
      await supabase
          .from('tbl_cart')
          .update({'cart_quantity': newQty.toString()})
          .eq('cart_id', cartId);
      
      fetchCartData(); // Refresh and recalculate
    } catch (e) {
      debugPrint("Update Qty Error: $e");
    }
  }

  Future<void> _removeItem(int cartId) async {
    try {
      await supabase.from('tbl_cart').delete().eq('cart_id', cartId);
      fetchCartData();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading:  IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Instead of destroying the stack, cleanly replace it or push standardly
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => IndexPage()),
              );
            }
          }
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final product = item['tbl_product'];
                          return _buildCartItem(item, product);
                        },
                      ),
                    ),
                    _buildCheckoutSection(),
                  ],
                ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, Map<String, dynamic> product) {
    int currentQty = int.parse(item['cart_quantity'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              product['product_photo'] ?? 'https://via.placeholder.com/100',
              width: 80, height: 80, fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['product_name'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text("₹${product['product_price']}",
                    style: const TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                // --- Quantity Controls ---
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () => _updateQuantity(item['cart_id'], currentQty, false)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("$currentQty", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    _qtyBtn(Icons.add, () => _updateQuantity(item['cart_id'], currentQty, true)),
                  ],
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            onPressed: () => _removeItem(item['cart_id']),
          )
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Amount", style: TextStyle(color: Colors.white70, fontSize: 16)),
                Text("₹$_totalAmount", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_cartItems.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentGatewayScreen(
                          id: _cartItems[0]['booking_id'],
                          amt: _totalAmount.toInt(),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("BUY NOW", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text("Your cart is empty", style: TextStyle(color: Colors.white38, fontSize: 18)),
        ],
      ),
    );
  }
}