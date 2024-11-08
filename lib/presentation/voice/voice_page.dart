import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';

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
      playerController = PlayerController();
      await playerController.preparePlayer(
        path: widget.voicePath!,
        noOfSamples: 100,
      );

      await player.setFilePath(widget.voicePath!);
      duration = await player.duration;

      player.positionStream.listen((pos) {
        setState(() {
          position = pos;
        });
      });

      player.playerStateStream.listen((state) {
        setState(() {
          isPlaying = state.playing;
        });
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Voice Note',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
              playerWaveStyle: const PlayerWaveStyle(
                fixedWaveColor: Colors.grey,
                liveWaveColor: Color(0xFF6C63FF),
                spacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDuration(position),
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              Expanded(
                child: Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0,
                  max: duration?.inSeconds.toDouble() ?? 0,
                  activeColor: const Color(0xFF6C63FF),
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await player.seek(position);
                    await playerController.seekTo(position.inMilliseconds);
                  },
                ),
              ),
              Text(
                _formatDuration(duration ?? Duration.zero),
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                iconSize: 40,
                color: const Color(0xFF6C63FF),
                onPressed: () async {
                  final newPosition = position - const Duration(seconds: 10);
                  await player.seek(newPosition);
                  await playerController.seekTo(newPosition.inMilliseconds);
                },
              ),
              const SizedBox(width: 24),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 48,
                  color: Colors.white,
                  onPressed: () async {
                    if (isPlaying) {
                      await player.pause();
                      await playerController.pausePlayer();
                    } else {
                      await player.play();
                      await playerController.startPlayer();
                    }
                  },
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.forward_10),
                iconSize: 40,
                color: const Color(0xFF6C63FF),
                onPressed: () async {
                  final newPosition = position + const Duration(seconds: 10);
                  await player.seek(newPosition);
                  await playerController.seekTo(newPosition.inMilliseconds);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    playerController.dispose();
    player.dispose();
    super.dispose();
  }
}
