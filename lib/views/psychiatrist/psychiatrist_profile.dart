import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mind_healer/views/user/make_appointment.dart';
import '../../models/psychiatrist_model.dart';
import '../../const/colors.dart';

class PsychiatristProfilePage extends StatefulWidget {
  final String psychiatristId;

  const PsychiatristProfilePage({super.key, required this.psychiatristId});

  @override
  State<PsychiatristProfilePage> createState() =>
      _PsychiatristProfilePageState();
}

class _PsychiatristProfilePageState extends State<PsychiatristProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Psychiatrist? _psychiatrist;
  List<String> _favoritePsychiatrists = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPsychiatristDetails();
    _loadFavorites();
  }

  Future<void> _fetchPsychiatristDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('psychiatrists')
          .doc(widget.psychiatristId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _psychiatrist =
              Psychiatrist.fromMap(widget.psychiatristId, snapshot.data()!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Psychiatrist not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching psychiatrist details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final favoritesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userData = favoritesSnapshot.data();
        if (userData != null) {
          setState(() {
            _favoritePsychiatrists =
                List<String>.from(userData['favoritePsychiatrists'] ?? []);
          });
        }
      } catch (e) {
        print('Error loading favorites: $e');
      }
    }
  }

  void _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final isFavorite =
            _favoritePsychiatrists.contains(widget.psychiatristId);
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        if (isFavorite) {
          await userDoc.update({
            'favoritePsychiatrists':
                FieldValue.arrayRemove([widget.psychiatristId]),
          });
        } else {
          await userDoc.update({
            'favoritePsychiatrists':
                FieldValue.arrayUnion([widget.psychiatristId]),
          });
        }

        await _loadFavorites();
      } catch (e) {
        print('Error toggling favorite: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_psychiatrist == null) {
      return const Scaffold(
        body: Center(child: Text('No psychiatrist data available')),
      );
    }

    final psychiatrist = _psychiatrist!; // Use the loaded Psychiatrist model

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dr ${psychiatrist.name}',
          style: const TextStyle(fontSize: 18, color: primegreen),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: psychiatrist.profilePicture.isNotEmpty
                  ? Image.network(
                      psychiatrist.profilePicture,
                      width: screenWidth * 0.5,
                      height: screenWidth * 0.5,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/default_profile.png',
                      width: screenWidth * 0.5,
                      height: screenWidth * 0.5,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            // Details
            Text(
              'Dr ${psychiatrist.name}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: primegreen),
            ),
            Text(psychiatrist.qualification),
            if (psychiatrist.specialty != null) Text(psychiatrist.specialty!),
            Text(psychiatrist.email),
            const SizedBox(height: 16),
            // Availability
            Text(
              'Availability',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey),
              children: psychiatrist.availabilityStartTimes.keys.map((day) {
                final startTime =
                    psychiatrist.availabilityStartTimes[day] ?? 'Unavailable';
                final endTime =
                    psychiatrist.availabilityEndTimes[day] ?? 'Unavailable';
                return TableRow(
                  children: [
                    _buildTableCell(day),
                    _buildTableCell(startTime),
                    _buildTableCell(endTime),
                    TableCell(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MakeAppointment(
                                psychiatristId: psychiatrist.id,
                              ),
                            ),
                          );
                        },
                        child: const Icon(Icons.arrow_circle_right_rounded,
                            color: Colors.green),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(
              height: 100,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFavorite,
        backgroundColor: primegreen,
        child: Icon(
          _favoritePsychiatrists.contains(widget.psychiatristId)
              ? Icons.favorite
              : Icons.favorite_border,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTableCell(String content) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(content),
      ),
    );
  }
}
