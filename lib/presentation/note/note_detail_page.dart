import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import 'note_page.dart';

const Color kPrimaryColor = Color.fromARGB(255, 119, 112, 248);
const Color kSecondaryColor = Color.fromARGB(255, 154, 151, 255);
const Color kAccentColor = Color(0xFFFF9E9E);
const Color kBackgroundColor = Color.fromARGB(255, 233, 233, 239);
const Color kTextColor = Color(0xFF2D3142);

class NoteDetailPage extends StatelessWidget {
  final Note note;

  const NoteDetailPage({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            _buildContentSection(),
            if (note.imagePaths?.isNotEmpty ?? false) _buildImageGrid(),
          ],
        ),
      ),
      floatingActionButton: _buildEditButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: kPrimaryColor),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor,
            kPrimaryColor.withOpacity(0.8),
            kSecondaryColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative wave pattern
          Positioned.fill(
            child: CustomPaint(
              painter: WavePatternPainter(),
            ),
          ),
          // Glass effect circle
          Positioned(
            right: -30,
            top: 30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  note.title,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMoodChip(),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.calendar_today,
                      DateFormat('EEE, MMM d').format(
                        DateTime.parse(note.timestamp),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${note.content.split(' ').length ~/ 200 + 1} min',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedEmoji(_getMoodAnimatedEmoji(note.mood), size: 20),
          const SizedBox(width: 6),
          Text(
            note.mood,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    if (note.content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(24),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: note.content.isNotEmpty ? note.content.substring(0, 1) : '',
              style: GoogleFonts.poppins(
                fontSize: 56,
                height: 1.2,
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: note.content.length > 1 ? note.content.substring(1) : '',
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.8,
                color: kTextColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final int imageCount = note.imagePaths?.length ?? 0;
    final int displayCount = imageCount > 3 ? 3 : imageCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attached Images',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(displayCount, (index) {
              bool isLastItem = index == 2 && imageCount > 3;
              return Expanded(
                child: Container(
                  height: 100,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: Builder(
                    builder: (BuildContext context) => GestureDetector(
                      onTap: () => _showFullScreenImage(context, index),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'image_$index',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image:
                                      FileImage(File(note.imagePaths![index])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          if (isLastItem)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: Center(
                                child: Text(
                                  '+${imageCount - 2}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton.small(
            heroTag: 'share',
            onPressed: () {
              // Implement share functionality
            },
            backgroundColor: kSecondaryColor,
            child: const Icon(Icons.share_outlined, color: Colors.white),
          ),
          FloatingActionButton.extended(
            heroTag: 'edit',
            onPressed: () => _editNote(context),
            backgroundColor: kPrimaryColor,
            icon: const Icon(Icons.edit_outlined),
            elevation: 4,
            label: Text(
              'Edit Note',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: note.imagePaths?.length ?? 0,
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'image_$index',
                  child: Image.file(
                    File(note.imagePaths![index]),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _editNote(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotePage(note: note, selectedMood: note.mood),
      ),
    );
    if (result == true) {
      Navigator.pop(context); // Return to HomePage after saving
    }
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
}

class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double spacing = size.width / 8;

    for (int i = 0; i < 8; i++) {
      path.moveTo(spacing * i, 0);
      path.quadraticBezierTo(
        spacing * i + spacing / 2,
        size.height / 2,
        spacing * i,
        size.height,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SmoothPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const waves = 3;
    final waveHeight = size.height / 8;

    for (var i = 0; i < waves; i++) {
      path.moveTo(0, size.height * (0.2 + 0.3 * i));

      var controlPoint1 =
          Offset(size.width * 0.25, size.height * (0.2 + 0.3 * i) + waveHeight);
      var controlPoint2 =
          Offset(size.width * 0.75, size.height * (0.2 + 0.3 * i) - waveHeight);
      var endPoint = Offset(size.width, size.height * (0.2 + 0.3 * i));

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final waveCount = 3;
    final waveHeight = size.height / 6;
    final waveWidth = size.width / waveCount;

    path.moveTo(0, size.height * 0.5);

    for (var i = 0; i <= waveCount; i++) {
      path.quadraticBezierTo(
        waveWidth * (i + 0.5),
        size.height * 0.5 + (i.isEven ? waveHeight : -waveHeight),
        waveWidth * (i + 1),
        size.height * 0.5,
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
