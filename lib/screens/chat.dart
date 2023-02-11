import 'package:customer/interfaces/chat.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatList});

  final List<Chat> chatList;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.chatList.length,
        itemBuilder: ((context, index) {
          Chat chat = widget.chatList[index];
          Widget messageWidget = Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text(chat.message),
          );
          if (chat.sender != null) {
            return Container();
          } else {
            return Container();
          }
        }));
  }
}
