import 'package:admin_app/addstock.dart';
import 'package:admin_app/gallery.dart';
import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Myproducts extends StatefulWidget {
  const Myproducts({super.key});

  @override
  State<Myproducts> createState() => _MyproductsState();
}

class _MyproductsState extends State<Myproducts> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);
  static const Color fieldColor = Color(0xFF0D0D0D);

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      // 1. Fetching all columns including product_id
      final response = await supabase.from('tbl_product').select();
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Product Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void showDeleteDialog(int index) {
    // 2. Capturing the specific product_id for the delete query
    final productId = _products[index]['product_id'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text("Delete Product", style: TextStyle(color: Colors.white)),
          content: const Text("Are you sure you want to delete this product?", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                try {
                  // 3. Using the fetched product_id to delete from Supabase
                  await supabase.from('tbl_product').delete().eq('product_id', productId);
                  
                  setState(() {
                    _products.removeAt(index);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Product Deleted")),
                  );
                } catch (e) {
                  debugPrint("Delete Error: $e");
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Product Inventory", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: fetchProducts, icon: const Icon(Icons.refresh, color: Colors.white))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: accentColor))
        : _products.isEmpty 
          ? const Center(child: Text("No products found", style: TextStyle(color: Colors.white)))
          : Padding(
              padding: const EdgeInsets.all(25.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.70, 
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  // 4. Storing local reference to ID for action buttons
                  final currentId = product['product_id'].toString();

                  return Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: product['product_photo'] != null
                            ? Image.network(
                                product['product_photo'],
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 50)),
                              )
                            : Container(height: 140, color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['product_name'] ?? 'No Name',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${product['product_price']}",
                                style: const TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "ID: $currentId", // Displaying ID as requested
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton("Stock", Icons.add_box, () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) =>  AddStock(productId: currentId)));
                                    }),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _buildActionButton("Gallery", Icons.image, () {
                                      // 5. Passing the fetched product_id to Gallery
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductGallery(productId: currentId)));
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent, width: 0.5),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () => showDeleteDialog(index),
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  label: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: fieldColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: accentColor),
      label: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }
}