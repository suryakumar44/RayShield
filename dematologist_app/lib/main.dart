import 'package:dematologist/homepage.dart';
import 'package:dematologist/login.dart';
import 'package:dematologist/registration.dart';
import 'package:dematologist/welcome.dart';
import 'package:flutter/material.dart';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://iipesqqmdhrtvhgfuxqp.supabase.co',
    anonKey: 'sb_publishable_abanNAY0dZJ3GwsoqaNT9w_Cusz6B6-',
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(MainApp());
}
final supabase = Supabase.instance.client;
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
            return const Homepage();
          }

          // No session found, show Login/Welcome
          return const Welcome();
        },
      ),
    );
  }
}
