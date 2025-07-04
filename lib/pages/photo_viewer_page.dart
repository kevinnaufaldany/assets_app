import 'package:flutter/material.dart';

class PhotoViewerPage extends StatelessWidget {
  final String imageUrl;
  final String? tag; // Untuk animasi hero

  const PhotoViewerPage({
    super.key,
    required this.imageUrl,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Hero(
          tag: tag ?? imageUrl, // Gunakan tag yang unik
          child: InteractiveViewer( // Widget ini memberikan fitur zoom & pan
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}