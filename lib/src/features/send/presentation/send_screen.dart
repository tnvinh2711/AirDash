import 'package:flutter/material.dart';

/// The Send screen - displays content for sending files to peers.
///
/// This is a placeholder screen that will be expanded in future features
/// to show file selection and peer discovery functionality.
class SendScreen extends StatelessWidget {
  /// Creates a [SendScreen] widget.
  const SendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload,
              size: 64,
              color: Colors.blueGrey,
            ),
            SizedBox(height: 16),
            Text(
              'Send Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select files to share...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
