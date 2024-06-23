import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newproject/psychiatrist_bottom_nav_bar.dart';
import 'package:newproject/pages/first_screen.dart';
import 'package:newproject/user_bottom_nav_bar.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          String uid = snapshot.data!.uid;

          return FutureBuilder<String?>(
            future: _getUserType(uid),
            builder: (context, userTypeSnapshot) {
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (userTypeSnapshot.hasData) {
                if (userTypeSnapshot.data == 'psychiatrist') {
                  return const PsyBottomBar(selectedIndex: 0);
                } else {
                  return const UserBottomBar(selectedIndex: 0);
                }
              } else {
                return const FirstScreen();
              }
            },
          );
        } else {
          return const FirstScreen();
        }
      },
    );
  }
}
