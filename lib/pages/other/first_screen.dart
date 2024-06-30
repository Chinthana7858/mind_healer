import 'package:flutter/material.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/const/styles.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = ScreenSize().width(context);
    double screenHeight = ScreenSize().height(context);
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.15,
          ),
          Center(
            child: Image.asset(
              'assets/images/doctor.png',
              width: screenWidth * 0.6,
              height: screenWidth * 0.6,
            ),
          ),
          SizedBox(
            height: screenHeight * 0.05,
          ),
          const Center(
            child: Text(
              'Mind Healer',
              style: TextStyle(fontSize: 22),
            ),
          ),
          const Center(
            child: Text(
              'Application to diagnose patients’ mental disorders and give instructions to solve them with artificial intelligence techniques.',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
          ),
          SizedBox(
            height: screenHeight * 0.15,
          ),
          SizedBox(
            width: screenWidth * 0.7,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: primegreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                shadowColor: primegreen,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/signinpage');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: screenHeight * 0.02,
          ),
          SizedBox(
            width: screenWidth * 0.7,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    side: const BorderSide(color: primegreen, width: 2)),
                shadowColor: primegreen,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/signuppage');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign Up',
                      style: TextStyle(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }
}
