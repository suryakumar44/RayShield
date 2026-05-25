import 'package:flutter/material.dart';
import 'package:user_app/indexpage.dart';
import 'package:user_app/main.dart';
import 'package:user_app/orderdetails.dart';
import 'package:user_app/prodata.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_booking')
          .select('*, tbl_cart(*, tbl_product(*))')
          .eq('user_id', user.id)
          .not('booking_status', 'is', null)
          .order('booking_date', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Orders Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("My Orders",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: "Current"), Tab(text: "History")],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(isHistory: false),
                _buildOrderList(isHistory: true),
              ],
            ),
    );
  }

  Widget _buildOrderList({required bool isHistory}) {
    // Current: Status < 4 | History: Status >= 4 (Delivered)
    final filteredOrders = _orders.where((o) {
      int status = int.tryParse(o['booking_status'].toString()) ?? 0;
      return isHistory ? status >= 4 : (status >= 1 && status < 4);
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
          child: Text(isHistory ? "No history" : "No active orders",
              style: const TextStyle(color: Colors.white24)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final List cartItems = order['tbl_cart'] ?? [];
        int currentStatus = int.tryParse(order['booking_status'].toString()) ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ID: #${order['booking_id']}",
                      style: const TextStyle(
                          color: accentColor, fontWeight: FontWeight.bold)),
                  Text(order['booking_date'].toString().split('T')[0],
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Order Tracker Visual
              _buildTracker(currentStatus),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(color: Colors.white10),
              ),

              // Product Items in the Order
              ...cartItems.map((item) {
                final product = item['tbl_product'];
                return GestureDetector(
                  onTap: () {
                    // TARGET FIX: Directs to Order Details if item is under History Tab, otherwise goes to Product Details
                    if (isHistory) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(booking: order),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    }
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product['product_photo'] ?? 'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.white10,
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 20),
                        ),
                      ),
                    ),
                    title: Text(product['product_name'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text("Qty: ${item['cart_quantity']}",
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    trailing: Text("₹${product['product_price']}",
                        style: const TextStyle(color: Colors.white70)),
                  ),
                );
              }),
              
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount", style: TextStyle(color: Colors.white54)),
                  Text("₹${order['booking_amount']}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTracker(int status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _trackerStep("Order", Icons.receipt_long, status >= 1),
        _trackerLine(status >= 2),
        _trackerStep("Payment", Icons.account_balance_wallet, status >= 2),
        _trackerLine(status >= 3),
        _trackerStep("Shipped", Icons.local_shipping, status >= 3),
        _trackerLine(status >= 4),
        _trackerStep("Delivered", Icons.done_all, status >= 4),
      ],
    );
  }

  Widget _trackerStep(String label, IconData icon, bool isActive) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isActive ? accentColor : Colors.white10),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.white10)),
      ],
    );
  }

  Widget _trackerLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 15),
        color: isActive ? accentColor.withOpacity(0.5) : Colors.white10,
      ),
    );
  }
}