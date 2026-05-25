import 'package:admin_app/addproduct.dart';
import 'package:admin_app/category.dart';
import 'package:admin_app/dermatologist_list.dart';
import 'package:admin_app/district.dart';
import 'package:admin_app/homepage.dart';
import 'package:admin_app/place.dart';
import 'package:admin_app/registration.dart';
import 'package:admin_app/subcategory.dart';
import 'package:admin_app/type.dart';
import 'package:admin_app/userlist.dart';
import 'package:admin_app/welcome.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
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
      home:Homepage()
      );
  }
}
