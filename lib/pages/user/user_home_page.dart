import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/pages/make_appointment.dart';
import 'package:newproject/service/FirestoreService.dart';

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
        title: Container(
          child: user != null
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
        ),
        actions: [
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
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Psychiatrists',
                  labelStyle: const TextStyle(
                    color: primegreen,
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: primegreen,
                    ),
                    onPressed: _search,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: const BorderSide(
                      color: primegreen,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: const BorderSide(
                      color: Colors.green,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              if (_searchResults.isEmpty)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getPsychiatrists(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
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
                              tileColor: Colors
                                  .grey[200], // Background color for the tile
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
                              subtitle: Text(userData['qualification'] ?? ''),
                              trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MakeAppointment(
                                              psychiatristId: userData['userId']
                                                  .toString())),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primegreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.double_arrow,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ],
                                  )),
                            ));
                      },
                    );
                  },
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final userData =
                        _searchResults[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            userData['profilePicture'] ??
                                'https://via.placeholder.com/150'),
                      ),
                      title: Text(userData['name'] ?? 'Name not available'),
                      subtitle:
                          Text(userData['email'] ?? 'Email not available'),
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
