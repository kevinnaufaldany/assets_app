import 'package:flutter/material.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? title;

  const PhotoViewerPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.title,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title ??
              'Foto ${_currentIndex + 1} dari ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showImageInfo();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
// PageView untuk navigasi antar foto
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: widget.imageUrls[index],
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

// Navigation arrows (jika ada lebih dari 1 foto)
          if (widget.imageUrls.length > 1) ...[
// Left arrow
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

// Right arrow
            if (_currentIndex < widget.imageUrls.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],

// Indicator dots di bagian bawah (jika ada lebih dari 1 foto)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                      (index) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto ${_currentIndex + 1} dari ${widget.imageUrls.length}'),
            const SizedBox(height: 8),
            const Text('Gestur yang tersedia:'),
            const Text('• Tap untuk menampilkan/menyembunyikan kontrol'),
            const Text('• Pinch untuk zoom in/out'),
            const Text('• Drag untuk menggeser foto'),
            const Text('• Swipe untuk navigasi antar foto'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
