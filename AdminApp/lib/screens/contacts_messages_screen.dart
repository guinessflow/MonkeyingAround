import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';

class ContactsMessagesScreen extends StatefulWidget {
  final VoidCallback backButton;

  const ContactsMessagesScreen({super.key, required this.backButton});

  @override
  _ContactsMessagesScreenState createState() => _ContactsMessagesScreenState();
}

class _ContactsMessagesScreenState extends State<ContactsMessagesScreen> {
  // Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();
  final int rowsPerPage = 5;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.backButton,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!.docs;
            final totalRows = messages.length;
            final totalPages = (totalRows / rowsPerPage).ceil();

            if (totalRows == 0) {
              return const Center(
                child: Text('No messages found.'),
              );
            }

            final startIndex = currentPage * rowsPerPage;
            final endIndex = (startIndex + rowsPerPage).clamp(0, totalRows);

            final visibleMessages = messages.sublist(startIndex, endIndex);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: visibleMessages.length,
                    itemBuilder: (context, index) {
                      final message = visibleMessages[index].data() as Map<String, dynamic>;
                      final id = visibleMessages[index].id;

                      final email = message['email'];
                      final messageText = message['message'];
                      final name = message['name'];
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
                      final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

                      return Card(
                        child: ListTile(
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: $name'),
                              Text('Email: $email'),
                              Text('Message: $messageText'),
                              Text('Sent On: $formattedTimestamp'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.reply),
                                onPressed: () {
                                  _showReplyDialog(email);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteMessage(id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: currentPage > 0 ? () => _changePage(-1) : null,
                    ),
                    Text('${currentPage + 1} / $totalPages'),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: currentPage < totalPages - 1 ? () =>
                          _changePage(1) : null,
                    ),
                  ],
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  void _changePage(int increment) {
    setState(() {
      currentPage += increment;
    });
  }

  void _deleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('contacts_messages')
                    .doc(messageId)
                    .delete()
                    .then((_) {
                  print('Message deleted successfully.');
                }).catchError((error) {
                  print('Error deleting message: $error');
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReplyDialog(String recipientEmail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String replyMessage = '';
        final formKey = GlobalKey<FormState>(); // Declare the form key

        return AlertDialog(
          title: const Text('Reply'),
          content: Form(
            key: formKey, // Assign the form key
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recipient Email: $recipientEmail'),
                TextFormField(
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your reply';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    replyMessage = value;
                  },
                  maxLines: null, // Allow multiple lines
                  keyboardType: TextInputType.multiline, // Enable multiline input
                  decoration: const InputDecoration(
                    hintText: 'Enter your reply',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  _sendMessage(recipientEmail, replyMessage);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }


  // Method to show a loading dialog with a progress indicator
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20.0),
                Text('Sending...'),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to close the loading dialog
  void _closeLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

// Send the email and handle success/failure dialogs
  void _sendMessage(String recipientEmail, String message) async {
    if (message.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please enter a message.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    String username = 'example@com';
    String password = 'N\$';

    final smtpServer = gmail(username, password);

    final messageToSend = Message()
      ..from = Address(username, 'Your Name')
      ..recipients.add(recipientEmail)
      ..subject = 'Reply'
      ..text = message;

    try {
      final sendReport = await send(messageToSend, smtpServer);
      print('Message sent: ${sendReport.toString()}');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Message sent successfully.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Message not sent. Error: $e');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to send message. Please try again.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }




}
