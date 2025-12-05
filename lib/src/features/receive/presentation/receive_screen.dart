import 'package:flutter/material.dart';

/// The Receive screen - displays content for receiving files from peers.
///
/// This is a placeholder screen that will be expanded in future features
/// to show incoming file transfer requests and received files.
class ReceiveScreen extends StatelessWidget {
  /// Creates a [ReceiveScreen] widget.
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download,
              size: 64,
              color: Colors.blueGrey,
            ),
            SizedBox(height: 16),
            Text(
              'Receive Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Waiting for incoming files...',
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
