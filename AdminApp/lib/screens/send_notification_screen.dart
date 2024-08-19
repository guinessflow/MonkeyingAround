import 'package:flutter/material.dart';
import '/services/firebase_service.dart';
import '/services/fcm_notification_manager.dart';


class SendNotificationScreen extends StatefulWidget {
  final VoidCallback backButton;

  const SendNotificationScreen({super.key, required this.backButton});

  @override
  _SendNotificationScreenState createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  //final TextEditingController _urlController = TextEditingController(); // Add URL controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Promo Notification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.backButton,
        ),
      ),
      body: SingleChildScrollView( // Wrap the Column with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Notification Body',
                  border: OutlineInputBorder(),
                ),
                maxLines: null, // Allow multiple lines for the body text
              ),
              const SizedBox(height: 16),
             // TextField(
            //    controller: _urlController,
             //   decoration: InputDecoration(
            //      labelText: 'Button URL',
            //      border: OutlineInputBorder(),
            //    ),
           //   ),
            //  SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
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

                  await FCMNotificationManager.sendPromoNotification(
                    firebaseService: FirebaseService(),
                    title: _titleController.text,
                    body: _bodyController.text,
                    // buttonUrl: _urlController.text, // Pass the URL to the sendPromoNotification method
                  );

                  Navigator.of(context).pop(); // Close the dialog

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: const Text('The notification has been successfully sent!'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Send Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

