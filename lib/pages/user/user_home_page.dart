// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/const/styles.dart';
import 'package:mind_healer/pages/chatbot/chat.dart';
import 'package:mind_healer/pages/user/psychiatrist_profile.dart';
import 'package:mind_healer/pages/user/user_profile_edit.dart';
import 'package:mind_healer/service/FirestoreService.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];

  Future<void> _signout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final results = await _firestoreService.searchPsychiatrists(query);
      setState(() {
        _searchResults = results;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: user != null
            ? FutureBuilder<Map<String, dynamic>?>(
                future: _firestoreService.getUserData(user.uid),
                builder:
                    (context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return const Text('Error fetching user data');
                  }

                  final userData = snapshot.data;

                  if (userData == null || !userData.containsKey('name')) {
                    return const Text(
                        'User data not found or name not available',
                        style: TextStyle(fontSize: 18));
                  }

                  final userName = userData['name'] as String;

                  return Text('Hi, $userName',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primegreen));
                },
              )
            : const Text('No user is currently signed in',
                style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        UserProfileEditPage(userId: user!.uid)),
              );
            },
            icon: const Icon(
              Icons.person,
              color: primegreen,
            ),
          ),
          IconButton(
            onPressed: () => _signout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SearchTextField(
                controller: _searchController,
                labelText: 'Search Psychiatrists',
                onPressed: _search,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primegreen,
                        Colors.teal,
                      ]),
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0, left: 16.0),
                            child: Text("Hi! You Can Ask Me",
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Text("Anything",
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8.0, left: 16.0, bottom: 16.0),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ChatPage()),
                                );
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    Colors.white),
                                foregroundColor: WidgetStateProperty.all<Color>(
                                    Colors.black),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: GradientText(
                                  "Ask Now",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  gradient: LinearGradient(colors: [
                                    Colors.teal,
                                    primegreen,
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.35,
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/chatbot.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_searchResults.isEmpty)
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Specialists",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primegreen,
                          ),
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService.getSpecialistPsychiatrists(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final users = snapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final userData =
                                  users[index].data() as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  tileColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.network(
                                        userData['profilePicture'] ??
                                            'https://via.placeholder.com/150',
                                        width: screenWidth,
                                        height: screenWidth,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    userData['name'] != null
                                        ? 'DR. ${userData['name']}'
                                        : 'Name not available',
                                  ),
                                  subtitle:
                                      Text(userData['qualification'] ?? ''),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PsychiatristProfile(
                                                    psychiatristId:
                                                        userData['userId']
                                                            .toString())),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primegreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.double_arrow,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Psychiatrists",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primegreen,
                          ),
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            _firestoreService.getNonSpecialistPsychiatrists(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final users = snapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final userData =
                                  users[index].data() as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  tileColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.network(
                                        userData['profilePicture'] ??
                                            'https://via.placeholder.com/150',
                                        width: screenWidth,
                                        height: screenWidth,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    userData['name'] != null
                                        ? 'DR. ${userData['name']}'
                                        : 'Name not available',
                                  ),
                                  subtitle:
                                      Text(userData['qualification'] ?? ''),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PsychiatristProfile(
                                                    psychiatristId:
                                                        userData['userId']
                                                            .toString())),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primegreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.double_arrow,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final userData =
                        _searchResults[index].data() as Map<String, dynamic>;
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PsychiatristProfile(
                                  psychiatristId: userData['userId'])),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            userData['profilePicture'] ??
                                'https://via.placeholder.com/150'),
                      ),
                      title: Text(userData['name'] ?? 'Name not available'),
                      subtitle: Text(userData['qualification'] ??
                          'Qualification not available'),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
