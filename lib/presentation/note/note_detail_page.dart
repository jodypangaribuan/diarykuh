import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import 'note_page.dart';
import 'package:diarykuh/utils/color_utils.dart';

class NoteDetailPage extends StatefulWidget {
  final Note note;
  final String userId; // Add userId parameter

  const NoteDetailPage({
    Key? key,
    required this.note,
    required this.userId, // Make userId required
  }) : super(key: key);

  @override
  _NoteDetailPageState createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  @override
  Widget build(BuildContext context) {
    // Guard against null _currentNote
    if (_currentNote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: kBackgroundColor, // Update warna background
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            _buildContentSection(),
            if (_currentNote?.imagePaths?.isNotEmpty ?? false)
              _buildImageGrid(),
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
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
          ),
          child: Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _currentNote?.title ?? '',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kTextColor,
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
                    DateTime.parse(_currentNote?.timestamp ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                _buildTimeChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: kTextColor),
          const SizedBox(width: 4),
          Text(
            '${_currentNote!.content.split(' ').length ~/ 200 + 1} min',
            style: GoogleFonts.poppins(
              color: kTextColor,
              fontSize: 14,
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
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kTextColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: kTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip() {
    Color moodColor = Colors.white.withOpacity(0.4);
    Color textColor = Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moodColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedEmoji(_getMoodAnimatedEmoji(_currentNote?.mood ?? ''),
              size: 20),
          const SizedBox(width: 6),
          Text(
            _currentNote?.mood ?? '',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    if (_currentNote?.content.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.fromARGB(255, 76, 186, 255).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative top element
          Center(
            child: Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Note content
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _currentNote?.content.isNotEmpty ?? false
                      ? _currentNote?.content.substring(0, 1)
                      : '',
                  style: GoogleFonts.comicNeue(
                    fontSize: 72,
                    height: 0.8,
                    color: Color.fromARGB(255, 76, 186, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: (_currentNote?.content.length ?? 0) > 1
                      ? _currentNote?.content.substring(1)
                      : '',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    height: 1.8,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Decorative bottom elements
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.4),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final int imageCount = _currentNote?.imagePaths?.length ?? 0;
    final int displayCount = imageCount > 3 ? 3 : imageCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto-foto Lu',
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
                                  image: FileImage(File(
                                      _currentNote?.imagePaths![index] ?? '')),
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
          Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.7),
                width: 1.5,
              ),
            ),
            child: FloatingActionButton.small(
              heroTag: 'share',
              onPressed: () {
                // Implement share functionality
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(
                Icons.share_outlined,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: kPastelLavender.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: FloatingActionButton.extended(
              heroTag: 'edit',
              onPressed: () => _handleEdit(),
              backgroundColor:
                  Color.fromARGB(255, 76, 186, 255).withOpacity(0.2),
              elevation: 0,
              icon: Icon(
                Icons.edit_outlined,
                color: Colors.black,
              ),
              label: Text(
                'Ubah Curhatan!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
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
            itemCount: _currentNote?.imagePaths?.length ?? 0,
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'image_$index',
                  child: Image.file(
                    File(_currentNote?.imagePaths![index] ?? ''),
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

  void _handleEdit() async {
    final updatedNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (context) => NotePage(
          note: _currentNote,
          selectedMood: _currentNote?.mood ?? '',
          userId: widget.userId,
        ),
      ),
    );

    if (updatedNote != null) {
      setState(() {
        _currentNote = updatedNote;
      });
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
