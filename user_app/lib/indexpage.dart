import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)

import 'package:user_app/cart.dart';
import 'package:user_app/doctors.dart';
import 'package:user_app/main.dart';
import 'package:user_app/mybooking.dart';
import 'package:user_app/myprofile.dart';
import 'package:user_app/user_homepage.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int _selectedIndex = 0;
  String? photo;

  // The app's signature cyan accent color
  static const Color cyanAccent = Color.fromARGB(255, 38, 248, 255);
  static const Color bgBlack = Color(0xFF0A0A0F);

  Future<void> loadUser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response = await supabase
            .from('tbl_user')
            .select()
            .eq('user_id', user.id)
            .single();

        if (mounted) {
          setState(() {
            photo = response['user_photo'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile photo: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // Pages
  static final List<Widget> _pages = <Widget>[
    const UserHomePage(),
    const MyAppointments(),
    const Doctors(),
    const CartPage(),
    const Myprofile(),
  ];

  @override
  Widget build(BuildContext context) {
    // Get bottom padding to safely float above the Android/iOS home indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bgBlack,
      
      // CRITICAL: extendBody allows the pages to flow underneath the floating nav bar
      extendBody: true, 

      // Selected Page
      body: _pages[_selectedIndex],

      // Floating Glassmorphism Bottom Navigation
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141420).withOpacity(0.8), // Translucent dark card
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cyanAccent.withOpacity(0.15), // Subtle cyan border
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: GNav(
                  // Animation
                  curve: Curves.easeOutExpo,
                  duration: const Duration(milliseconds: 300),

                  // Premium Hover & Ripple Effects (Cyan instead of Purple)
                  rippleColor: cyanAccent.withOpacity(0.2),
                  hoverColor: cyanAccent.withOpacity(0.1),
                  haptic: true,

                  // Spacing tweaked to prevent overflow with 5 tabs
                  gap: 6, 
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),

                  // Colors
                  color: Colors.white54, // Unselected icon color
                  activeColor: cyanAccent, // Selected icon/text color
                  tabBackgroundColor: cyanAccent.withOpacity(0.12), // Selected tab background

                  // Shape
                  tabBorderRadius: 16,
                  iconSize: 24,

                  // State
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },

                  // Tabs
                  tabs: [
                    const GButton(
                      icon: LineIcons.home,
                      text: 'Home',
                    ),
                    const GButton(
                      icon: LineIcons.calendar,
                      text: 'Schedule',
                    ),
                    const GButton(
                      icon: LineIcons.hospital,
                      text: 'Doctors',
                    ),
                    const GButton(
                      icon: LineIcons.shoppingCart,
                      text: 'Cart',
                    ),
                    GButton(
                      icon: LineIcons.user,
                      text: 'Profile',
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF1E1E2E),
                        backgroundImage: photo != null ? NetworkImage(photo!) : null,
                        // Add an elegant border to the profile picture
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedIndex == 4 ? cyanAccent : Colors.transparent, 
                              width: 1.5,
                            ),
                          ),
                          child: photo == null
                              ? Icon(
                                  LineIcons.user,
                                  size: 14,
                                  color: _selectedIndex == 4 ? cyanAccent : Colors.white54,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}