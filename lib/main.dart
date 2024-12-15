import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:mind_healer/auth/authwrapper.dart';
import 'package:mind_healer/views/user/user_home_page.dart';
import 'package:mind_healer/views/auth/signin_page.dart';
import 'package:mind_healer/views/auth/signup_page.dart';
import 'package:mind_healer/viewmodels/user_profile_viewmodel.dart'; // Import your ViewModel

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
