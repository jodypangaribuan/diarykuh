import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';

const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kSecondaryColor = Color(0xFF8C88FF);
const Color kBackgroundColor = Color(0xFFF8F9FF);

class VoicePage extends StatefulWidget {
  final String title;
  final String timestamp;
  final String? voicePath;
  final String mood;

  const VoicePage({
    Key? key,
    required this.title,
    required this.timestamp,
    required this.voicePath,
    required this.mood,
  }) : super(key: key);

  @override
  _VoicePageState createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late PlayerController playerController;
  final player = AudioPlayer();
  bool isPlaying = false;
  Duration? duration;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    if (widget.voicePath != null) {
      try {
        playerController = PlayerController();

        // Configure player with higher quality settings
        await playerController.preparePlayer(
          path: widget.voicePath!,
          noOfSamples: 100,
        );

        // Set up audio player with specific configuration
        await player.setAudioSource(
          AudioSource.uri(Uri.file(widget.voicePath!)),
          initialPosition: Duration.zero,
          preload: true,
        );

        duration = await player.duration;

        player.positionStream.listen((pos) {
          if (mounted) {
            setState(() {
              position = pos;
            });
          }
        });

        player.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              isPlaying = state.playing;
            });
          }
        });
      } catch (e) {
        print('Error initializing player: $e');
      }
    }
  }

  Future<void> _stopPlayback() async {
    try {
      if (isPlaying) {
        await player.pause();
        await playerController.pausePlayer();
        setState(() {
          isPlaying = false;
        });
      }
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _stopPlayback();
        return true;
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildAudioPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () async {
                  await _stopPlayback();
                  Navigator.pop(context);
                },
                color: kPrimaryColor,
              ),
              Expanded(
                child: Text(
                  'Voice Note',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40), // For balance
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                DateTime.parse(widget.timestamp).toString().substring(0, 16),
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: AudioFileWaveforms(
              size: Size(MediaQuery.of(context).size.width - 88, 100),
              playerController: playerController,
              waveformType: WaveformType.fitWidth,
              playerWaveStyle: PlayerWaveStyle(
                fixedWaveColor: Colors.grey[300]!,
                liveWaveColor: kPrimaryColor,
                spacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbColor: kPrimaryColor,
                    activeTrackColor: kPrimaryColor,
                    inactiveTrackColor: Colors.grey[200],
                  ),
                  child: Slider(
                    value: position.inSeconds.toDouble(),
                    min: 0,
                    max: duration?.inSeconds.toDouble() ?? 0,
                    onChanged: (value) async {
                      final position = Duration(seconds: value.toInt());
                      await player.seek(position);
                      await playerController.seekTo(position.inMilliseconds);
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(duration ?? Duration.zero),
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                Icons.replay_10,
                () async {
                  final newPosition = position - const Duration(seconds: 10);
                  await player.seek(newPosition);
                  await playerController.seekTo(newPosition.inMilliseconds);
                },
                small: true,
              ),
              const SizedBox(width: 32),
              _buildControlButton(
                isPlaying ? Icons.pause : Icons.play_arrow,
                () async {
                  if (isPlaying) {
                    await player.pause();
                    await playerController.pausePlayer();
                  } else {
                    await player.play();
                    await playerController.startPlayer();
                  }
                },
              ),
              const SizedBox(width: 32),
              _buildControlButton(
                Icons.forward_10,
                () async {
                  final newPosition = position + const Duration(seconds: 10);
                  await player.seek(newPosition);
                  await playerController.seekTo(newPosition.inMilliseconds);
                },
                small: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed,
      {bool small = false}) {
    final size = small ? 48.0 : 64.0;
    final iconSize = small ? 24.0 : 32.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: small ? Colors.white : kPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(small ? 0.1 : 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: iconSize,
        color: small ? kPrimaryColor : Colors.white,
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    try {
      _stopPlayback();
      playerController.dispose();
      player.dispose();
    } catch (e) {
      print('Error disposing player: $e');
    }
    super.dispose();
  }
}
