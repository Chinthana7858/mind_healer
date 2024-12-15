import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p; // Use alias for path context if needed
import 'package:sqflite/sqflite.dart';

class DfChat extends StatefulWidget {
  const DfChat({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<DfChat> {
  DialogFlowtter? dialogFlowtter;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  Database? _database;

  @override
  void initState() {
    super.initState();
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      p.join(await getDatabasesPath(), 'messages.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, isUserMessage INTEGER)',
        );
      },
      version: 1,
    );
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final List<Map<String, dynamic>> maps = await _database!.query('messages');
    setState(() {
      messages = maps
          .map<Map<String, Object?>>((map) => {
                'message':
                    Message(text: DialogText(text: [map['text'] as String])),
                'isUserMessage': map['isUserMessage'] == 1,
              })
          .toList();
    });
  }

  Future<void> _saveMessage(String text, bool isUserMessage) async {
    await _database!.insert(
      'messages',
      {
        'text': text,
        'isUserMessage': isUserMessage ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _confirmDeleteAllMessages() async {
    bool? confirm = await showDialog<bool>(
      context: context, // Ensure this is the BuildContext from Flutter
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete all messages?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false); // User cancels the deletion
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true); // User confirms the deletion
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteAllMessages();
    }
  }

  Future<void> _deleteAllMessages() async {
    await _database!
        .delete('messages'); // Delete all records from the 'messages' table
    setState(() {
      messages.clear(); // Clear the in-memory list of messages
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteAllMessages, // Trigger confirmation dialog
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
                child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: messages[index]['isUserMessage']
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 14),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomRight: Radius.circular(
                                          messages[index]['isUserMessage']
                                              ? 0
                                              : 20),
                                      topLeft: Radius.circular(messages[index]
                                              ['isUserMessage']
                                          ? 20
                                          : 0),
                                    ),
                                    color: messages[index]['isUserMessage']
                                        ? Colors.green.shade700
                                        : Colors.green.shade700
                                            .withOpacity(0.8)),
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            2 /
                                            3),
                                child: Text(
                                  messages[index]['message'].text.text[0],
                                  style: TextStyle(color: Colors.white),
                                )),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, i) =>
                        const Padding(padding: EdgeInsets.only(top: 10)),
                    itemCount: messages.length)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
                color: Colors.black12.withOpacity(0.2),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your message here...',
                    ),
                    style: const TextStyle(color: Colors.white),
                  )),
                  IconButton(
                      onPressed: () {
                        sendMessage(_controller.text.trim());
                        _controller.clear();
                      },
                      icon: const Icon(Icons.send))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  sendMessage(String text) async {
    if (text.isEmpty) {
      debugPrint('Message is empty');
    } else {
      setState(() {
        addMessage(Message(text: DialogText(text: [text])), true);
      });

      DetectIntentResponse response = await dialogFlowtter!
          .detectIntent(queryInput: QueryInput(text: TextInput(text: text)));
      if (response.message == null) return;
      setState(() {
        addMessage(response.message!);
      });
    }
  }

  addMessage(Message message, [bool isUserMessage = false]) async {
    messages.add({
      'message': message,
      'isUserMessage': isUserMessage,
    });
    await _saveMessage(message.text?.text?.first ?? '', isUserMessage);
    _controller.clear();
  }
}
