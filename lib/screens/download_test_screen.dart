import 'package:flutter/material.dart';
import '../services/download_service.dart';
import '../widgets/image_viewer_widget.dart';
import '../widgets/permission_test_widget.dart';

class DownloadTestScreen extends StatefulWidget {
  @override
  State<DownloadTestScreen> createState() => _DownloadTestScreenState();
}

class _DownloadTestScreenState extends State<DownloadTestScreen> {
  List<String> downloadHistory = [];

  void _addToHistory(String item) {
    setState(() {
      downloadHistory.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)} - $item',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Tests'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission Status Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Storage Permission Info',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Android 13+: Files saved to app-specific directory (no permission required)\n'
                      'Android 12-: Files saved to Downloads folder (permission required)',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Download Tests
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📥 Download Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Small Image Test
                    _buildTestButton(
                      'Small Image (100KB)',
                      Icons.image,
                      Colors.blue,
                      () {
                        _addToHistory('Small Image download started');
                        DownloadService.downloadImage(
                          context: context,
                          imageUrl: 'https://picsum.photos/800/600?random=1',
                          fileName:
                              'small_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );
                      },
                    ),

                    SizedBox(height: 8),

                    // Large Image Test
                    _buildTestButton(
                      'Large Image (2MB+)',
                      Icons.photo,
                      Colors.purple,
                      () {
                        _addToHistory('Large Image download started');
                        DownloadService.downloadImage(
                          context: context,
                          imageUrl: 'https://picsum.photos/1920/1080?random=2',
                          fileName:
                              'large_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );
                      },
                    ),

                    SizedBox(height: 8),

                    // Video Test
                    _buildTestButton(
                      'Sample Video (1MB)',
                      Icons.video_file,
                      Colors.red,
                      () {
                        _addToHistory('Video download started');
                        DownloadService.downloadVideo(
                          context: context,
                          videoUrl:
                              'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
                          fileName:
                              'sample_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
                        );
                      },
                    ),

                    SizedBox(height: 8),

                    // Audio Test
                    _buildTestButton(
                      'Audio File (500KB)',
                      Icons.audio_file,
                      Colors.orange,
                      () {
                        _addToHistory('Audio download started');
                        DownloadService.downloadAudio(
                          context: context,
                          audioUrl:
                              'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                          fileName:
                              'audio_sample_${DateTime.now().millisecondsSinceEpoch}.wav',
                        );
                      },
                    ),

                    SizedBox(height: 8),

                    // PDF Test
                    _buildTestButton(
                      'PDF Document (200KB)',
                      Icons.description,
                      Colors.green,
                      () {
                        _addToHistory('PDF download started');
                        DownloadService.downloadGenericFile(
                          context: context,
                          fileUrl:
                              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                          fileName:
                              'sample_${DateTime.now().millisecondsSinceEpoch}.pdf',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Image Viewer Test
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🖼️ Image Viewer + Download Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tap image to open viewer, then tap download button',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _addToHistory('Image viewer opened');
                        ImageViewerDialog.show(
                          context,
                          'https://picsum.photos/1920/1080?random=3',
                          heroTag: 'download_test_image',
                          title: 'Download Test Image',
                        );
                      },
                      child: Hero(
                        tag: 'download_test_image',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://picsum.photos/400/300?random=3',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.grey),
                                    Text(
                                      'Failed to load',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Download History
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '📋 Download History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        if (downloadHistory.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                downloadHistory.clear();
                              });
                            },
                            child: Text('Clear'),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (downloadHistory.isEmpty)
                      Text(
                        'No downloads yet. Try the buttons above!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...downloadHistory.map(
                        (item) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Permission Test Widget
            PermissionTestWidget(),

            SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber[800]),
                        SizedBox(width: 8),
                        Text(
                          'Testing Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Check permissions first (green = OK)\n'
                      '2. Request missing permissions if any\n'
                      '3. Try downloading different file types\n'
                      '4. Check progress dialogs\n'
                      '5. Verify files are saved (check Downloads folder)\n'
                      '6. Test error handling with invalid URLs\n'
                      '7. Test on different Android versions if possible',
                      style: TextStyle(color: Colors.amber[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
