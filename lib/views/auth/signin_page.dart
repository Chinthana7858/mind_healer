// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mind_healer/views/widgets/psychiatrist_bottom_nav_bar.dart';
import 'package:mind_healer/const/colors.dart'; // Assuming you have defined primegreen color
import 'package:mind_healer/const/styles.dart';
import 'package:mind_healer/views/user/user_bottom_nav_bar.dart'; // Assuming you have ScreenSize class defined

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false; // Added _isLoading state

  Future<void> _signin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Signin successful!')));
      final userType = await _getUserType(userCredential.user!.uid);

      if (userType == 'psychiatrist') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PsyBottomBar(selectedIndex: 0)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const UserBottomBar(selectedIndex: 0)),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Signin failed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred. Please try again.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getUserType(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc['userType'];
    }

    final psychiatristDoc = await FirebaseFirestore.instance
        .collection('psychiatrists')
        .doc(uid)
        .get();
    if (psychiatristDoc.exists) {
      return psychiatristDoc['userType'];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = ScreenSize().width(context);
    double screenHeight = ScreenSize().height(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: primegreen,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
              color: Colors.white,
              iconSize: 25.0,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/deco-1.png'),
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: screenHeight * 0.05,
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: const Text('Sign In',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
              ),
              SizedBox(
                height: screenHeight * 0.05,
              ),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icons.email,
              ),

              const SizedBox(
                  height: 20), // Add some spacing between the text fields

              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock,
                obscureText: true,
              ),

              SizedBox(height: screenHeight * 0.05),
              SizedBox(
                width: screenWidth * 0.7,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primegreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    shadowColor: primegreen,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _signin();
                        },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      if (_isLoading)
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signuppage');
                },
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Create an account?'),
                      Text(
                        'Sign Up',
                        style: TextStyle(color: primegreen),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
