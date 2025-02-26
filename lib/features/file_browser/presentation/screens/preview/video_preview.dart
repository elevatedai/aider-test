import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VideoPreview extends StatefulWidget {
  final Uint8List fileData;
  final String fileName;

  const VideoPreview({
    super.key,
    required this.fileData,
    required this.fileName,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late Future<void> _initializeVideoPlayerFuture;
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _videoVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Write video data to temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${widget.fileName}');
    await tempFile.writeAsBytes(widget.fileData);
    
    _controller = VideoPlayerController.file(tempFile);
    
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _totalDuration = _controller.value.duration;
        });
        
        // Add listener for position updates
        _controller.addListener(() {
          if (mounted && _controller.value.isPlaying && _isInitialized) {
            setState(() {
              _currentPosition = _controller.value.position;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _seekTo(double value) {
    final newPosition = Duration(milliseconds: (value * _totalDuration.inMilliseconds).round());
    _controller.seekTo(newPosition);
  }

  void _setVolume(double volume) {
    setState(() {
      _videoVolume = volume;
      _controller.setVolume(volume);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _togglePlayback();
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      if (!_isPlaying)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        if (_isInitialized)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Slider(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                            : 0.0,
                        onChanged: _seekTo,
                      ),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_videoVolume > 0 ? Icons.volume_up : Icons.volume_off),
                          onPressed: () {
                            _setVolume(_videoVolume > 0 ? 0.0 : 1.0);
                          },
                        ),
                        SizedBox(
                          width: 100,
                          child: Slider(
                            value: _videoVolume,
                            onChanged: _setVolume,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: () => _controller.seekTo(Duration.zero),
                        ),
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: _togglePlayback,
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          onPressed: () {
                            // Toggle fullscreen mode
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
