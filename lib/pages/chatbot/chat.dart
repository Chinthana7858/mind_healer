// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/const/keys.dart';

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

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: api_key);

    _chat = _model.startChat();
  }

  Future<void> getAnswer(String text) async {
    try {
      late final dynamic response;

      response = await _chat.sendMessage(Content.text(text));

      setState(() {
        _chatHistory.add({
          "time": DateTime.now(),
          "message": response.text,
          "isSender": false,
          "isImage": false
        });
      });

      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    } catch (e) {
      print('Error: $e');
    } finally {}
  }

  void _sendMessage() {
    if (_chatController.text.isNotEmpty) {
      setState(() {
        if (_chatController.text.isNotEmpty) {
          _chatHistory.add({
            "time": DateTime.now(),
            "message": _chatController.text,
            "isSender": true,
            "isImage": false
          });
        }
      });

      getAnswer(_chatController.text);
      _chatController.clear();

      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 160,
            child: ListView.builder(
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
