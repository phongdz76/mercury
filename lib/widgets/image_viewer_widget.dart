import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../services/download_service.dart';

class ImageViewerWidget extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const ImageViewerWidget({
    Key? key,
    required this.imageUrl,
    this.heroTag,
    this.fit,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.network(
      imageUrl,
      fit: fit ?? BoxFit.cover,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height ?? 200,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height ?? 200,
          color: Colors.grey[200],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );

    // Wrap with Hero animation if heroTag is provided
    if (heroTag != null) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    return GestureDetector(
      onTap: () {
        ImageViewerDialog.show(context, imageUrl, heroTag: heroTag);
      },
      child: imageWidget,
    );
  }
}

class ImageViewerDialog extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? title;

  const ImageViewerDialog({
    Key? key,
    required this.imageUrl,
    this.heroTag,
    this.title,
  }) : super(key: key);

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();

  static void show(
    BuildContext context,
    String imageUrl, {
    String? heroTag,
    String? title,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageViewerDialog(
            imageUrl: imageUrl,
            heroTag: heroTag,
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  bool _showAppBar = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: widget.title != null
                  ? Text(
                      widget.title!,
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _downloadImage(),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showAppBar = !_showAppBar;
          });
        },
        child: Container(
          color: Colors.black,
          child: PhotoView(
            imageProvider: NetworkImage(widget.imageUrl),
            heroAttributes: widget.heroTag != null
                ? PhotoViewHeroAttributes(tag: widget.heroTag!)
                : null,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            loadingBuilder: (context, event) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? null
                        : event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes ?? 1),
                    color: Colors.white,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _downloadImage() {
    // Import DownloadService to implement actual download
    final imageUrl = widget.imageUrl;
    final fileName =
        widget.title ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Show download confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Download Image'),
          ],
        ),
        content: Text('Download "$fileName" to your device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Start download
              _startImageDownload(imageUrl, fileName);
            },
            child: Text('Download'),
          ),
        ],
      ),
    );
  }

  void _startImageDownload(String imageUrl, String fileName) {
    // Use DownloadService for actual download
    DownloadService.downloadImage(
      context: context,
      imageUrl: imageUrl,
      fileName: fileName,
    );
  }
}

class ImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final List<String>? heroTags;
  final String? title;

  const ImageGalleryViewer({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTags,
    this.title,
  }) : super(key: key);

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();

  static void show(
    BuildContext context,
    List<String> imageUrls, {
    int initialIndex = 0,
    List<String>? heroTags,
    String? title,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageGalleryViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            heroTags: heroTags,
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.title ??
                    '${_currentIndex + 1} of ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _downloadCurrentImage(),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showAppBar = !_showAppBar;
          });
        },
        child: Container(
          color: Colors.black,
          child: PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            builder: (context, index) {
              final imageUrl = widget.imageUrls[index];
              final heroTag =
                  widget.heroTags != null && index < widget.heroTags!.length
                  ? widget.heroTags![index]
                  : null;

              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrl),
                heroAttributes: heroTag != null
                    ? PhotoViewHeroAttributes(tag: heroTag)
                    : null,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
              );
            },
            scrollPhysics: const ClampingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            loadingBuilder: (context, event) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? null
                        : event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes ?? 1),
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _downloadCurrentImage() {
    final currentImageUrl = widget.imageUrls[_currentIndex];
    final fileName =
        'image_${_currentIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Show download confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Download Image'),
          ],
        ),
        content: Text(
          'Download image ${_currentIndex + 1} of ${widget.imageUrls.length}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Start download
              DownloadService.downloadImage(
                context: context,
                imageUrl: currentImageUrl,
                fileName: fileName,
              );
            },
            child: Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
