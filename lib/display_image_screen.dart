import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_base64_service.dart';

class DisplayImageScreen extends StatefulWidget {
  final String userId;
  const DisplayImageScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DisplayImageScreenState createState() => _DisplayImageScreenState();
}

class _DisplayImageScreenState extends State<DisplayImageScreen> {
  String? base64Image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    String? image = await FirestoreBase64Service().fetchBase64Image(widget.userId);
    setState(() {
      base64Image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display Image')),
      body: Center(
        child: base64Image == null
            ? const Text('No image found')
            : Image.memory(base64Decode(base64Image!)),
      ),
    );
  }
}
