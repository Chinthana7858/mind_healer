// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class UserList extends StatelessWidget {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   UserList({super.key});

//   Future<void> _signout(BuildContext context) async {
//     await _auth.signOut();
//     Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final User? user = FirebaseAuth.instance.currentUser;
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home Page'),
//         actions: [
//           IconButton(
//             onPressed: () => _signout(context),
//             icon: const Icon(Icons.logout),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Center(
//             child: user != null
//                 ? Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('Welcome, ${user.email}',
//                           style: TextStyle(fontSize: 24)),
//                       const SizedBox(height: 20),
//                       ElevatedButton(
//                         onPressed: () async {
//                           await FirebaseAuth.instance.signOut();
//                           Navigator.pushReplacementNamed(context, '/signin');
//                         },
//                         child: const Text('Sign Out'),
//                       ),
//                     ],
//                   )
//                 : const Text('No user is currently signed in',
//                     style: TextStyle(fontSize: 24)),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('users').snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final users = snapshot.data!.docs;
//                 return ListView.builder(
//                   itemCount: users.length,
//                   itemBuilder: (context, index) {
//                     final userData =
//                         users[index].data() as Map<String, dynamic>;
//                     return ListTile(
//                       title: Text(userData['name'] ?? 'Name not available'),
//                       subtitle:
//                           Text(userData['email'] ?? 'Email not available'),
//                       // Add more user data fields as needed
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('psychiatrists').snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final users = snapshot.data!.docs;
//                 return ListView.builder(
//                   itemCount: users.length,
//                   itemBuilder: (context, index) {
//                     final userData =
//                         users[index].data() as Map<String, dynamic>;
//                     return ListTile(
//                       title: Text(userData['name'] ?? 'Name not available'),
//                       subtitle:
//                           Text(userData['email'] ?? 'Email not available'),
//                       // Add more user data fields as needed
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
