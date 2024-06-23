import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:newproject/pages/user/user_home_page.dart';
import 'package:newproject/pages/signin_page.dart';
import 'package:newproject/pages/signup_page.dart';
import 'package:newproject/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/signin': (context) => const SigninPage(),
        '/userhomepage': (context) => UserHomePage(),
        '/signuppage': (context) => const SignupPage(),
        '/signinpage': (context) => const SigninPage(),
      },
    );
  }
}
