import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/views/psychiatrist/psychiatrist_profile.dart';
import 'package:mind_healer/service/FirestoreService.dart';

class FavoriteDoctors extends StatefulWidget {
  const FavoriteDoctors({super.key});

  @override
  State<FavoriteDoctors> createState() => _FavoriteDoctorsState();
}

class _FavoriteDoctorsState extends State<FavoriteDoctors> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  List<String> _favoritePsychiatrists = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = _auth.currentUser;
    if (user != null) {
      List<String> favorites =
          await _firestoreService.getFavoritePsychiatrists(user.uid);
      setState(() {
        _favoritePsychiatrists = favorites;
      });
    }
  }

  void _toggleFavorite(String psychiatristId) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (_favoritePsychiatrists.contains(psychiatristId)) {
        await _firestoreService.removeFavoritePsychiatrist(
            user.uid, psychiatristId);
      } else {
        await _firestoreService.addFavoritePsychiatrist(
            user.uid, psychiatristId);
      }
      await _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favourite Psychiatrists',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primegreen,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _favoritePsychiatrists.isEmpty
              ? Center(
                  child: Text(
                    'No favorite psychiatrists found.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _favoritePsychiatrists.length,
                  itemBuilder: (context, index) {
                    String psychiatristId = _favoritePsychiatrists[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('psychiatrists')
                          .doc(psychiatristId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text('Psychiatrist not found.');
                        }

                        // Retrieve psychiatrist data safely
                        Map<String, dynamic>? psychiatristData =
                            snapshot.data!.data() as Map<String,
                                dynamic>?; // Cast to Map<String, dynamic>?

                        if (psychiatristData == null) {
                          return Text('Data not available.');
                        }

                        // Extract properties with proper type handling
                        String psychiatristName =
                            psychiatristData['name'] ?? 'Unknown';
                        String psychiatristQualification =
                            psychiatristData['qualification'] ?? '';
                        String psychiatristProfileUrl =
                            psychiatristData['profilePicture'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: psychiatristProfileUrl.isNotEmpty
                                ? NetworkImage(psychiatristProfileUrl)
                                : AssetImage(
                                    'assets/images/default_profile.png'),
                          ),
                          title: Text(psychiatristName),
                          subtitle: Text(psychiatristQualification),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: primegreen,
                            ),
                            onPressed: () {
                              _toggleFavorite(psychiatristId);
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PsychiatristProfilePage(
                                      psychiatristId:
                                          psychiatristId.toString())),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
