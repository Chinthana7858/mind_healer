// import 'package:flutter/material.dart';
// import 'package:newproject/video_call/videocall.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final TextEditingController _channelNameController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home Page'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: TextField(
//                 controller: _channelNameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Enter Channel Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // Navigate to the VideoStreaming page with the entered channel name
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => VideoCall(
//                       channelName: _channelNameController.text,
//                     ),
//                   ),
//                 );
//               },
//               child: const Text('Start Video Call'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
