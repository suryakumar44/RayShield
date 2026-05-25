import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/homepage.dart';
import 'package:user_app/indexpage.dart';
import 'package:user_app/user_homepage.dart';
import 'package:user_app/welcome.dart';


import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://iipesqqmdhrtvhgfuxqp.supabase.co',
    anonKey: 'sb_publishable_abanNAY0dZJ3GwsoqaNT9w_Cusz6B6-',
    
    
  );
  
  runApp(MainApp());
}
final supabase =   Supabase.instance.client;  

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use a StreamBuilder to listen to Auth State Changes
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // While waiting for Supabase to initialize/load session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;

          // If session exists, user is logged in
          if (session != null) {
            return const IndexPage();
          }

          // No session found, show Login/Welcome
          return const Welcome();
        },
      ),
    );
  }
}
