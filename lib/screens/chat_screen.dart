import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

final _fireBaseAuth = FirebaseAuth.instance;
final _fireStore = FirebaseFirestore.instance;
final _messageTextController = TextEditingController();

class ChatScreen extends StatefulWidget {
  static const id = 'ChatScreen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  User loggedInUser;
  String messageText;

  @override
  void initState() {
    super.initState();
    loggedInUser = _fireBaseAuth.currentUser;
  }

  Future<String> logoutDialogBox() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Do you want to logout?'),
        content: const Text('Hope to see you soon.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Ok');
              _fireBaseAuth.signOut().whenComplete(
                  () => Navigator.pushNamed(context, WelcomeScreen.id));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                logoutDialogBox();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      _messageTextController.clear();
                      _fireStore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'timeStamp': FieldValue.serverTimestamp()
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore
          .collection('messages')
          .orderBy('timeStamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        List<Widget> messageWidgets = [];
        if (snapshot.hasData) {
          final messages = snapshot.data.docs;
          for (var message in messages) {
            final messageText = message['text'];
            final messageSender = message['sender'];
            final messageBubble = MaterialBubble(
                messageText: messageText, messageSender: messageSender);
            messageWidgets.add(messageBubble);
          }
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ListView(
              reverse: true,
              children: messageWidgets,
            ),
          ),
        );
      },
    );
  }
}

class MaterialBubble extends StatelessWidget {
  MaterialBubble({
    @required this.messageText,
    @required this.messageSender,
  });

  final String messageText;
  final String messageSender;

  @override
  Widget build(BuildContext context) {
    if (messageSender != _fireBaseAuth.currentUser.email) {
      return ChatBubble(
        messageText: messageText,
        messageSender: messageSender,
        senderColor: Colors.black54,
        bubbleColor: Colors.white,
        crossAxisAlignment: CrossAxisAlignment.start,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      );
    } else {
      return ChatBubble(
        messageText: messageText,
        messageSender: messageSender,
        senderColor: Colors.white,
        bubbleColor: Colors.lightBlue,
        crossAxisAlignment: CrossAxisAlignment.end,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      );
    }
  }
}

class ChatBubble extends StatelessWidget {
  ChatBubble({
    @required this.messageText,
    @required this.messageSender,
    @required this.senderColor,
    @required this.bubbleColor,
    @required this.crossAxisAlignment,
    @required this.borderRadius,
  });

  final String messageText;
  final String messageSender;
  final BorderRadius borderRadius;
  final Color senderColor, bubbleColor;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Container(
              constraints: BoxConstraints(maxWidth: 200),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 1,
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  messageText,
                  style: TextStyle(fontSize: 15, color: senderColor),
                ),
              ),
            ),
          ),
          Text(
            messageSender,
            style: TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
