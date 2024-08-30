import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mind_healer/auth/authwrapper.dart';
import 'package:mind_healer/pages/user/user_home_page.dart';
import 'package:mind_healer/pages/other/signin_page.dart';
import 'package:mind_healer/pages/other/signup_page.dart';

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
        '/': (context) => const AuthWrapper(),
        '/signin': (context) => const SigninPage(),
        '/userhomepage': (context) => UserHomePage(),
        '/signuppage': (context) => const SignupPage(),
        '/signinpage': (context) => const SigninPage(),
      },
    );
  }
}
