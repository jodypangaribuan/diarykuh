import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:diarykuh/utils/color_utils.dart';

class VoicePage extends StatefulWidget {
  final String title;
  final String timestamp;
  final String? voicePath;
  final String mood;
  final String userId;

  const VoicePage({
    Key? key,
    required this.title,
    required this.timestamp,
    required this.voicePath,
    required this.mood,
    required this.userId,
  }) : super(key: key);

  @override
  _VoicePageState createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> with TickerProviderStateMixin {
  late PlayerController playerController;
  final player = AudioPlayer();
  bool isPlaying = false;
  double volume = 1.0;
  Duration? duration;
  Duration position = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveformController;
  double playbackSpeed = 1.0;
  bool isLooping = false;
  Duration? loopStart;
  Duration? loopEnd;
  late AnimationController _emojiController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initializeAnimations();
    player.setLoopMode(LoopMode.off);

    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _initializePlayer() async {
    if (widget.voicePath != null) {
      try {
        playerController = PlayerController();

        await playerController.preparePlayer(
          path: widget.voicePath!,
          noOfSamples: 100,
        );

        try {
          await player.setAudioSource(
            AudioSource.file(widget.voicePath!),
            initialPosition: Duration.zero,
          );

          duration = await player.duration;

          await player.setVolume(volume);

          player.positionStream.listen((pos) {
            if (mounted) {
              setState(() => position = pos);
            }
          });

          player.playerStateStream.listen((state) {
            if (mounted) {
              setState(() => isPlaying = state.playing);
            }
          });
        } catch (audioError) {
          print('Error setting audio source: $audioError');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error loading audio file: ${audioError.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error initializing player: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing player: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
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
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          CustomPaint(
            painter: BackgroundPatternPainter(),
            size: Size.infinite,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: _buildModernAudioPlayer(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElement(int index) {
    final size = 20.0 + Random().nextDouble() * 30;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_pulseAnimation.value - 1) * (index % 3) * 0.2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: index % 3 == 0
                  ? BoxShape.circle
                  : index % 3 == 1
                      ? BoxShape.rectangle
                      : BoxShape.rectangle,
              borderRadius: index % 3 == 2 ? BorderRadius.circular(8) : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kSecondaryColor],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildBackButton(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Note',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () async {
        await _stopPlayback();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 8),
        Text(
          DateTime.parse(widget.timestamp).toString().substring(0, 16),
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              AnimatedEmoji(_getMoodAnimatedEmoji(widget.mood), size: 20),
              const SizedBox(width: 8),
              Text(
                widget.mood,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  AnimatedEmojiData _getMoodAnimatedEmoji(String mood) {
    switch (mood) {
      case 'Happy':
        return AnimatedEmojis.smile;
      case 'Sad':
        return AnimatedEmojis.loudlyCrying;
      case 'Excited':
        return AnimatedEmojis.starStruck;
      case 'Tired':
        return AnimatedEmojis.sleep;
      case 'Calm':
        return AnimatedEmojis.relieved;
      default:
        return AnimatedEmojis.smile;
    }
  }

  Widget _buildModernAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWaveformCard(),
          const SizedBox(height: 24),
          _buildSpeedControl(),
          const SizedBox(height: 16),
          _buildTimeControls(),
          const SizedBox(height: 24),
          _buildPlaybackControls(),
          const SizedBox(height: 16),
          _buildExtraControls(),
        ],
      ),
    );
  }

  Widget _buildWaveformCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isPlaying)
                Container(
                  width: 150 * _pulseAnimation.value,
                  height: 150 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: AudioFileWaveforms(
                  size: Size(MediaQuery.of(context).size.width - 88, 100),
                  playerController: playerController,
                  waveformType: WaveformType.fitWidth,
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: Colors.grey[300]!,
                    liveWaveColor: kPrimaryColor,
                    spacing: 6,
                    waveCap: StrokeCap.round,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [0.5, 1.0, 1.5, 2.0].map((speed) {
        final isSelected = playbackSpeed == speed;
        return GestureDetector(
          onTap: () async {
            await player.setSpeed(speed);
            setState(() => playbackSpeed = speed);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? kPrimaryColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Text(
              '${speed}x',
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: GoogleFonts.poppins(
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _formatDuration(duration ?? Duration.zero),
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbColor: kPrimaryColor,
            activeTrackColor: kPrimaryColor,
            inactiveTrackColor: Colors.grey[200],
            overlayColor: kPrimaryColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
          ),
          child: Slider(
            value: position.inSeconds.toDouble().clamp(
                  0,
                  duration?.inSeconds.toDouble() ?? 0,
                ),
            min: 0,
            max: duration?.inSeconds.toDouble() ?? 1,
            onChanged: (value) async {
              if (duration != null) {
                final position = Duration(seconds: value.toInt());
                await player.seek(position);
                await playerController.seekTo(position.inMilliseconds);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _togglePlayPause() async {
    try {
      if (isPlaying) {
        await player.pause();
        await playerController.pausePlayer();
      } else {
        if (duration != null) {
          await player.play();
          await playerController.startPlayer();
        }
      }
    } catch (e) {
      print('Error toggling playback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          Icons.replay_10,
          () async {
            try {
              final newPosition = position - const Duration(seconds: 10);
              await player.seek(newPosition);
              await playerController.seekTo(newPosition.inMilliseconds);
            } catch (e) {
              print('Error seeking: $e');
            }
          },
          small: true,
        ),
        const SizedBox(width: 32),
        _buildControlButton(
          isPlaying ? Icons.pause : Icons.play_arrow,
          _togglePlayPause,
        ),
        const SizedBox(width: 32),
        _buildControlButton(
          Icons.forward_10,
          () async {
            try {
              final newPosition = position + const Duration(seconds: 10);
              await player.seek(newPosition);
              await playerController.seekTo(newPosition.inMilliseconds);
            } catch (e) {
              print('Error seeking: $e');
            }
          },
          small: true,
        ),
      ],
    );
  }

  Widget _buildExtraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          isLooping ? Icons.repeat_one : Icons.repeat,
          _toggleLoopMode,
          small: true,
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          Icons.share,
          _shareVoiceNote,
          small: true,
        ),
      ],
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

  void _toggleLoopMode() {
    setState(() {
      isLooping = !isLooping;
      if (isLooping) {
        loopStart = position;
        loopEnd = position + const Duration(seconds: 10);
        _startLoopSection();
      } else {
        player.setLoopMode(LoopMode.off);
        loopStart = loopEnd = null;
      }
    });
  }

  void _startLoopSection() async {
    if (loopStart != null && loopEnd != null) {
      await player.setLoopMode(LoopMode.off);
      await player.seek(loopStart!);
      await player.setClip(start: loopStart, end: loopEnd);
      await player.setLoopMode(LoopMode.one);
      if (!isPlaying) {
        await player.play();
      }
    }
  }

  void _shareVoiceNote() {}

  @override
  void dispose() {
    _emojiController.dispose();
    _pulseController.dispose();
    _waveformController.dispose();
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

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPrimaryColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final gradientRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        kBackgroundColor,
        Color(0xFFEDE9FF),
      ],
    );

    final gradientPaint = Paint()..shader = gradient.createShader(gradientRect);
    canvas.drawRect(gradientRect, gradientPaint);

    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 5; j++) {
        final xOffset = size.width * 0.2 * i;
        final yOffset = size.height * 0.2 * j;

        canvas.drawCircle(
          Offset(xOffset, yOffset),
          30,
          paint,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(xOffset + 100, yOffset + 100),
              width: 60,
              height: 60,
            ),
            const Radius.circular(15),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
