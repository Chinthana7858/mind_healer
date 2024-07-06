import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/const/keys.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;

class ChatPage extends StatefulWidget {
  static const routeName = '/chat';
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatHistory = [];

  late final GenerativeModel _model;
  late final ChatSession _chat;
  late Database _database;
  bool _initialMessageProcessed = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: api_key);

    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Get the path to the database
    var databasesPath = await getDatabasesPath();
    String dbPath = path_helper.join(databasesPath, 'messages.db');

    // Open the database
    _database = await openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute(
          'CREATE TABLE messages (id INTEGER PRIMARY KEY AUTOINCREMENT, message TEXT, isSender INTEGER)');
    });

    List<Map> list =
        await _database.rawQuery('SELECT * FROM messages ORDER BY id DESC');
    setState(() {
      _chatHistory.addAll(list.map((item) => {
            "message": item['message'],
            "isSender": item['isSender'] == 1,
            "isImage": false,
          }));
    });

    // Initialize chat
    _chat = _model.startChat();

    // Send an initial message to set the context or instructions for the chat model
    String initialCommand =
        "You are a helpful assistant who diagnoses mental health issues by chatting with users. Always assist as a supportive adviser.";
    try {
      final response = await _chat.sendMessage(Content.text(initialCommand));
      // Print the response to console
      print(response.text);
      setState(() {
        _initialMessageProcessed = true;
      });
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  Future<void> getAnswer(String text) async {
    if (_initialMessageProcessed) {
      try {
        late final dynamic response;
        response = await _chat.sendMessage(Content.text(text));
        // Print the response to console
        print(response.text);
        final messageData = {
          "time": DateTime.now().toIso8601String(),
          "message": response.text,
          "isSender": false,
          "isImage": false,
        };

        // Save the received message to the database
        await _database.insert('messages', {
          "message": response.text,
          "isSender": 0,
        });

        setState(() {
          _chatHistory.insert(0, messageData);
        });

        _scrollController.jumpTo(
          0.0,
        );
      } catch (e) {
        print('Error: $e');
      } finally {}
    }
  }

  void _sendMessage() async {
    if (_chatController.text.isNotEmpty) {
      final messageData = {
        "time": DateTime.now().toIso8601String(),
        "message": _chatController.text,
        "isSender": true,
        "isImage": false,
      };
      // Save the sent message to the database
      await _database.insert('messages', {
        "message": _chatController.text,
        "isSender": 1,
      });

      setState(() {
        _chatHistory.insert(0, messageData);
      });

      getAnswer(_chatController.text);
      _chatController.clear();

      _scrollController.jumpTo(
        0.0,
      );
    }
  }

  void _deleteAllMessages() async {
    // Delete all messages from the database
    await _database.delete('messages');

    // Clear the chat history in the UI
    setState(() {
      _chatHistory.clear();
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete All Messages"),
          content: const Text("Are you sure you want to delete all messages?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteAllMessages();
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ai assistant",
          style: TextStyle(fontWeight: FontWeight.w400, color: primegreen),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
            ),
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 160,
            child: ListView.builder(
              reverse: true,
              itemCount: _chatHistory.length,
              shrinkWrap: false,
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.only(
                      left: 14, right: 14, top: 10, bottom: 10),
                  child: Align(
                    alignment: (_chatHistory[index]["isSender"]
                        ? Alignment.topRight
                        : Alignment.topLeft),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        color: (_chatHistory[index]["isSender"]
                            ? primegreen
                            : Colors.white),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _chatHistory[index]["isImage"]
                          ? Image.file(File(_chatHistory[index]["message"]),
                              width: 200)
                          : Text(_chatHistory[index]["message"],
                              style: TextStyle(
                                  fontSize: 15,
                                  color: _chatHistory[index]["isSender"]
                                      ? Colors.white
                                      : Colors.black)),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(
                              0xFF7D96E6), // Use your gradient color
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Type a message",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(8.0),
                          ),
                          controller: _chatController,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  MaterialButton(
                    onPressed: _sendMessage,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0)),
                    padding: const EdgeInsets.all(0.0),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.teal,
                              primegreen,
                            ]),
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Container(
                          constraints: const BoxConstraints(
                              minWidth: 88.0, minHeight: 36.0),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                          )),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
