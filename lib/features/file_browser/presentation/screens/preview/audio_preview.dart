import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class AudioPreview extends StatefulWidget {
  final Uint8List fileData;
  final String fileName;

  const AudioPreview({
    super.key,
    required this.fileData,
    required this.fileName,
  });

  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _volume = 1.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Pause audio when app goes to background
      _audioPlayer.pause();
    }
  }

  Future<void> _initializeAudio() async {
    try {
      // Write audio data to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.fileName}');
      await tempFile.writeAsBytes(widget.fileData);

      // Load audio file
      await _audioPlayer.setFilePath(tempFile.path);
      
      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  Stream<PositionData> get _positionDataStream => 
    Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _audioPlayer.positionStream,
      _audioPlayer.bufferedPositionStream,
      _audioPlayer.durationStream,
      (position, bufferedPosition, duration) => PositionData(
        position: position,
        bufferedPosition: bufferedPosition,
        duration: duration ?? Duration.zero,
      ),
    );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load audio: $_errorMessage'),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Audio visualization or album art could be shown here
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.music_note,
            size: 120,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            widget.fileName,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data ?? 
                PositionData(
                  position: Duration.zero,
                  bufferedPosition: Duration.zero,
                  duration: Duration.zero,
                );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(_formatDuration(positionData.position)),
                      Expanded(
                        child: Slider(
                          value: positionData.position.inMilliseconds.toDouble(),
                          min: 0,
                          max: positionData.duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(milliseconds: value.round()));
                          },
                        ),
                      ),
                      Text(_formatDuration(positionData.duration)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off),
                        onPressed: () {
                          setState(() {
                            _volume = _volume > 0 ? 0.0 : 1.0;
                            _audioPlayer.setVolume(_volume);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () => _audioPlayer.seek(Duration.zero),
                      ),
                      FloatingActionButton(
                        onPressed: _togglePlayback,
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: () => _audioPlayer.seek(positionData.duration),
                      ),
                      IconButton(
                        icon: const Icon(Icons.loop),
                        onPressed: () {
                          // Toggle loop mode
                          final mode = _audioPlayer.loopMode == LoopMode.one 
                              ? LoopMode.off 
                              : LoopMode.one;
                          _audioPlayer.setLoopMode(mode);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down, size: 20),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                              _audioPlayer.setVolume(_volume);
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, size: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}
