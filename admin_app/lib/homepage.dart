import 'package:admin_app/addproduct.dart';
import 'package:admin_app/category.dart';
import 'package:admin_app/dermatologist_list.dart';
import 'package:admin_app/district.dart';
import 'package:admin_app/heatabsourption.dart';
import 'package:admin_app/level.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/myproducts.dart';
import 'package:admin_app/ordermanage.dart';
import 'package:admin_app/place.dart';
import 'package:admin_app/registration.dart';
import 'package:admin_app/subcategory.dart';
import 'package:admin_app/type.dart';
import 'package:admin_app/view_complaints.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/userlist.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // JosKart Dashboard Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color sidebarColor = Color(0xFF131313);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color.fromARGB(255, 40, 255, 223);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // --- REFINED SIDEBAR ---
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: sidebarColor,
              border: const Border(right: BorderSide(color: Colors.white10, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Center Icon only (Removed JosKart text as requested)
                const Center(
                  child: Icon(Icons.auto_awesome, color: accentColor, size: 35),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sideBtn(Icons.add_box_outlined, 'Add Product', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProduct()))),
                        _sideBtn(Icons.category_outlined, 'Categories', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Category()))),
                        _sideBtn(Icons.account_tree_outlined, 'Sub Category', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Subcategory()))),
                        _sideBtn(Icons.map_outlined, 'District', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const District()))),
                        _sideBtn(Icons.place_outlined, 'Place', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Place()))),
                        _sideBtn(Icons.inventory_2_outlined, 'My Products', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Myproducts()))),
                        _sideBtn(Icons.trending_up_outlined, 'Product Levels', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Level()))),
                        _sideBtn(Icons.thermostat_outlined, 'Heat Absorption', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Heatabsourption()))),
                        _sideBtn(Icons.shopping_cart_outlined, 'Bookings', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderStatusPage()))),
                         _sideBtn(Icons.person, 'Skin type', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Types()))),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                          child: Divider(color: Colors.white10),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 15),
                          child: Text('ACCOUNTS', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        
                        _sideBtn(Icons.how_to_reg_outlined, 'Registration', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Registration()))),
                        _sideBtn(Icons.login_outlined, 'Log In', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()))),
                        _sideBtn(Icons.people_alt_outlined, 'Users List', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Userlist()))),
                        _sideBtn(Icons.medical_services_outlined, 'Dermatologists', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DermaList()))),
                        _sideBtn(Icons.feedback_outlined, 'Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewComplaints()))),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- MAIN CONTENT AREA ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildStatCards(),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildImageCard('assets/graph.png', 'Market Performance Analytics')),
                      const SizedBox(width: 25),
                      Expanded(flex: 2, child: _buildWelcomeCard()),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildImageCard('assets/datasales.png', 'Revenue Streams')),
                      const SizedBox(width: 25),
                      // Fixed Overflow Inventory Summary
                      Expanded(flex: 2, child: _buildInventorySummary()),
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

  Widget _sideBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                const SizedBox(width: 16),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard Overview', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Manage products, orders, and professional staff', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
        const Spacer(),
        Container(
          width: 300, height: 45,
          decoration: BoxDecoration(color: sidebarColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
          child: const TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search dashboard...',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.white24, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 20),
        const Text('Admin User', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard('TODAYS REVENUE', '\$ 2,342,342', '+55%', Icons.payments_outlined),
        const SizedBox(width: 20),
        _statCard('ACTIVE USERS', '2,202', '+5%', Icons.people_outline),
        const SizedBox(width: 20),
        _statCard('NEW CLIENTS', '342', '+8%', Icons.person_add_outlined),
        const SizedBox(width: 20),
        _statCard('TOTAL SALES', '\$ 200,300', '+18%', Icons.trending_up),
      ],
    );
  }

  Widget _statCard(String label, String value, String growth, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Icon(icon, color: accentColor, size: 20),
            ]),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$growth since yesterday', style: const TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String asset, String title) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(asset, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
            Padding(padding: const EdgeInsets.all(24), child: Align(alignment: Alignment.bottomLeft, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      height: 350,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset('assets/docimage1.png', width: double.infinity, height: double.infinity, fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.4)),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.security, color: accentColor, size: 40),
                  const SizedBox(height: 15),
                  const Text('System Panel', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Control all backend operations and user data securely.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary() {
    return Container(
      constraints: const BoxConstraints(minHeight: 350), // Flex height to prevent overflow
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: sidebarColor, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inventory Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _summaryRow(Icons.devices, 'Devices', '259 in stock', '300 sold'),
          _summaryRow(Icons.confirmation_number_outlined, 'Tickets', '125 closed', '15 active'),
          _summaryRow(Icons.bug_report_outlined, 'Error Logs', '1 active', '30 closed'),
          _summaryRow(Icons.face_retouching_natural_outlined, 'Happy Users', '+140 today', ''),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String title, String sub, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white70, size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          Text(trailing, style: const TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
        ],
      ),
    );
  }
}