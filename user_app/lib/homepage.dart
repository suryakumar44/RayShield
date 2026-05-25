import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/cart.dart';
import 'package:user_app/docprofile.dart';
import 'package:user_app/doctors.dart';
import 'package:user_app/main.dart';
import 'package:user_app/mybooking.dart';
import 'package:user_app/myprofile.dart';
import 'package:user_app/prodata.dart';
import 'package:user_app/products.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class Homepages extends StatefulWidget {
  const Homepages({super.key});

  @override
  State<Homepages> createState() => _HomepagesState();
}

String name = "";
List<Map<String, dynamic>> dermatologistList = [];
List<Map<String, dynamic>> productList = [];

class _HomepagesState extends State<Homepages> {
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color accentPurple = Colors.purple;
  static const Color navAccent = Color.fromARGB(255, 38, 248, 255);

  int _selectedIndex = 0; // Tracks navigation index

  @override
  void initState() {
    super.initState();
    fetchDoctors();
    fetchproducts();
    fetchuser();
  }

  Future<void> fetchuser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        name = response['user_name'] ?? "User";
      });
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_status', 'approved');

      setState(() {
        dermatologistList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  Future<void> fetchproducts() async {
    try {
      final response = await supabase.from('tbl_product').select();
      setState(() {
        productList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        // --- BOTTOM NAVIGATION BAR ---
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cardBg,
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 8,
              ),
              child: GNav(
                rippleColor: Colors.grey[800]!,
                hoverColor: Colors.grey[700]!,
                gap: 8,
                activeColor: navAccent,
                iconSize: 24,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.black.withOpacity(0.3),
                color: Colors.white,
                tabs: const [
                  GButton(icon: Icons.home_outlined, text: 'Home'),
                  GButton(icon: Icons.calendar_month_sharp, text: 'Likes'),
                  GButton(icon: Icons.shopping_cart_outlined, text: 'Cart'),
                  GButton(icon: Icons.person_outline, text: 'Profile'),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  // Handle navigation logic here
                   if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyAppointments()),
                    );
                  }
                  if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  }

                  if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Myprofile(),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Welcome, $name',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader =
                                const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 38, 248, 255),
                                    Colors.blue,
                                    Color.fromARGB(255, 222, 35, 255),
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0.0, 0.0, 200, 70),
                                ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Color.fromARGB(255, 18, 249, 218),
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: cardBg,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search skin concerns...",
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(Icons.search, color: navAccent),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),

                // Promo Banner
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromARGB(255, 65, 245, 255),
                          Color(0xFF1710F6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Healthy Skin \nStarts Here",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Consult with experts today",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Products Section
                _buildSectionHeader("Top Products", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllProductsPage(),
                    ),
                  );
                }),

                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final pro = productList[index];

                      // Wrapping the Container with GestureDetector
                      return GestureDetector(
                        onTap: () {
                          print("Product clicked: ${pro['product_name']}");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: pro),
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: cardBg,
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                child: Image.network(
                                  pro['product_photo'] ??
                                      'https://via.placeholder.com/150',
                                  height: 100,
                                  width: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pro['product_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "₹${pro['product_price']}",
                                      style: const TextStyle(
                                        color: navAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                _buildSectionHeader("Expert Doctors", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Doctors()),
                  );
                }),

                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: dermatologistList.length,
                    itemBuilder: (context, index) {
                      final doc = dermatologistList[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: cardBg,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white10,
                              backgroundImage:
                                  doc['dermatologist_photo'] != null
                                  ? NetworkImage(doc['dermatologist_photo'])
                                  : null,
                              child: doc['dermatologist_photo'] == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white38,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              doc['dermatologist_name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Specialist',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DoctorProfile(doctor: doc),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text("View More", style: TextStyle(color: navAccent)),
          ),
        ],
      ),
    );
  }
}
