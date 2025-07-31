import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/image_viewer_widget.dart';
import '../services/download_service.dart';
import 'download_test_screen.dart';

class MediaTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media Features Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DownloadTestScreen()),
              );
            },
            icon: Icon(Icons.download),
            tooltip: 'Download Tests',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Player Test
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎥 Video Player Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        VideoPlayerDialog.show(
                          context,
                          'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
                          title: 'Sample Video',
                        );
                      },
                      child: Text('Play Sample Video'),
                    ),
                    SizedBox(height: 8),
                    VideoPlayerWidget(
                      videoUrl:
                          'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
                      autoPlay: false,
                      aspectRatio: 16 / 9,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Audio Player Test
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎵 Audio Player Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        AudioPlayerDialog.show(
                          context,
                          'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                          title: 'Sample Audio',
                          duration: Duration(seconds: 30),
                        );
                      },
                      child: Text('Play in Dialog'),
                    ),
                    SizedBox(height: 12),
                    AudioPlayerWidget(
                      audioUrl:
                          'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                      title: 'Sample Bell Sound',
                      duration: Duration(seconds: 5),
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
                      '🖼️ Image Viewer Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ImageViewerDialog.show(
                                context,
                                'https://picsum.photos/800/600?random=1',
                                heroTag: 'test_image_1',
                                title: 'Random Image 1',
                              );
                            },
                            child: Hero(
                              tag: 'test_image_1',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  'https://picsum.photos/400/300?random=1',
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Test gallery viewer
                              ImageGalleryViewer.show(
                                context,
                                [
                                  'https://picsum.photos/800/600?random=2',
                                  'https://picsum.photos/800/600?random=3',
                                  'https://picsum.photos/800/600?random=4',
                                ],
                                initialIndex: 0,
                                title: 'Image Gallery',
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'https://picsum.photos/400/300?random=2',
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Download Test
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📥 Download Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              DownloadService.downloadImage(
                                context: context,
                                imageUrl:
                                    'https://picsum.photos/1920/1080?random=5',
                                fileName: 'test_image.jpg',
                              );
                            },
                            icon: Icon(Icons.image),
                            label: Text('Download Image'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              DownloadService.downloadVideo(
                                context: context,
                                videoUrl:
                                    'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
                                fileName: 'sample_video.mp4',
                              );
                            },
                            icon: Icon(Icons.video_file),
                            label: Text('Download Video'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              DownloadService.downloadAudio(
                                context: context,
                                audioUrl:
                                    'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                                fileName: 'bell_sound.wav',
                              );
                            },
                            icon: Icon(Icons.audio_file),
                            label: Text('Download Audio'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              DownloadService.downloadGenericFile(
                                context: context,
                                fileUrl:
                                    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                                fileName: 'sample.pdf',
                              );
                            },
                            icon: Icon(Icons.description),
                            label: Text('Download PDF'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Tap video to play in fullscreen\n'
                      '• Tap audio to control playback\n'
                      '• Tap images to view with zoom\n'
                      '• Tap gallery image to browse multiple images\n'
                      '• Use download buttons to test file downloads\n'
                      '• Check Downloads folder for saved files',
                      style: TextStyle(color: Colors.blue[700]),
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
}
