import 'package:flutter/material.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/registration.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset('assets/clouds.jpg', fit: BoxFit.cover),
            ),
          ),
          Center(
            child: Column(
              children: [
                SizedBox(height: 70),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome ',
                      style: TextStyle(foreground: Paint()..shader=LinearGradient(colors: [
                            Colors.purple,
                            Colors.blue,
                            Colors.pink,
                          ],
                          ).createShader(Rect.fromLTWH(0.0, 0.0, 200, 70)
                          ),
      
                    
                        fontSize: 38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text('=)', style: TextStyle(foreground: Paint()..shader=LinearGradient(colors: [
                            Colors.purple,
                            Colors.blue,
                            Colors.pink,
                          ],
                          ).createShader(Rect.fromLTWH(0.0, 0.0, 200, 70)),
      
                      fontSize: 30)),
                  ],
                ),
                SizedBox(height: 50),
                Text(
                  'Hi there!',
                  style: TextStyle(foreground: Paint()..shader=LinearGradient(colors: [
                            Colors.purple,
                            Colors.blue,
                            Colors.pink,
                          ],
                          ).createShader(Rect.fromLTWH(0.0, 0.0, 200, 70)),
                            fontSize: 16),
                ),
                Text(
                  "We're here to help you",
                  style: TextStyle(foreground: Paint()..shader=LinearGradient(colors: [
                            Colors.purple,
                            Colors.blue,
                            Colors.pink,
                          ],
                          ).createShader(Rect.fromLTWH(0.0, 0.0, 200, 70))
                           , fontSize: 16),
                ),
                Text(
                  'Login or create an account.',
                  style: TextStyle(foreground: Paint()..shader=LinearGradient(colors: [
                            Colors.purple,
                            Colors.blue,
                            Colors.pink,
                          ],
                          ).createShader(Rect.fromLTWH(0.0, 0.0, 200, 70)),
                             fontSize: 16),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      gradient: LinearGradient(
                        begin: AlignmentGeometry.topCenter,
                        end: AlignmentGeometry.bottomCenter,
                        colors: [
                          const Color.fromARGB(255, 252, 252, 252),
                          const Color.fromARGB(255, 211, 116, 227),
                        ],
                      ),
                    ),
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Registration()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      gradient: LinearGradient(
                        begin: AlignmentGeometry.topCenter,
                        end: AlignmentGeometry.bottomCenter,
                        colors: [
                          const Color.fromARGB(255, 252, 252, 252),
                          const Color.fromARGB(255, 211, 116, 227),
                        ],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}