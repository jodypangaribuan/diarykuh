import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database_helper.dart';
import '../../models/note_model.dart';
import '../voice/voice_page.dart';
import 'dart:io';

const Color kPrimaryColor = Color.fromARGB(255, 119, 112, 248);
const Color kSecondaryColor = Color.fromARGB(255, 154, 151, 255);
const Color kAccentColor = Color(0xFFFF9E9E);
const Color kBackgroundColor = Color.fromARGB(255, 233, 233, 239);
const Color kTextColor = Color(0xFF2D3142);

class NotePage extends StatefulWidget {
  final Note? note;
  final String selectedMood;

  const NotePage({Key? key, this.note, required this.selectedMood})
      : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _dbHelper = DatabaseHelper();
  bool _isEdited = false;
  late String _currentMood;
  int _characterCount = 0;
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentMood = widget.note?.mood ?? widget.selectedMood;
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _characterCount = _contentController.text.length;
      if (widget.note?.imagePaths != null) {
        _selectedImages.addAll(widget.note!.imagePaths!);
      }
    }

    _contentController.addListener(() {
      setState(() {
        _characterCount = _contentController.text.length;
      });
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(image.path);
        _isEdited = true;
      });
    }
  }

  Future<void> _saveNote() async {
    final note = Note(
      id: widget.note?.id,
      title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
      content: _contentController.text,
      mood: _currentMood,
      timestamp: DateTime.now().toString(),
      voicePath: widget.note?.voicePath,
      imagePaths: _selectedImages,
    );

    if (widget.note == null) {
      await _dbHelper.insertNote(note);
    } else {
      await _dbHelper.updateNote(note);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildNoteContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSaveButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kSecondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                '$_characterCount characters',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          TextField(
            controller: _titleController,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              counterText: '', // This hides the character counter
            ),
            maxLines: 1,
            maxLength: 100,
            onChanged: (value) => setState(() => _isEdited = true),
          ),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 16, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                DateTime.now().toString().substring(0, 16),
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    AnimatedEmoji(_getMoodAnimatedEmoji(_currentMood),
                        size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _currentMood,
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
    );
  }

  Widget _buildNoteContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImages.isNotEmpty) _buildImagePreview(),
          Expanded(
            child: TextField(
              controller: _contentController,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.5,
                color: kTextColor,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Write your thoughts...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.withOpacity(0.7),
                  fontSize: 16,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickImage,
                  color: kPrimaryColor.withOpacity(0.5),
                ),
              ),
              onChanged: (value) => setState(() => _isEdited = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) => _buildImageThumbnail(index),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(File(_selectedImages[index])),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedImages.removeAt(index);
              _isEdited = true;
            }),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AnimatedOpacity(
      opacity: _isEdited ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.small(
              heroTag: 'discard',
              onPressed: () => Navigator.pop(context),
              backgroundColor: kAccentColor,
              child: const Icon(Icons.close, color: Colors.white),
            ),
            FloatingActionButton.extended(
              heroTag: 'save',
              onPressed: _saveNote,
              backgroundColor: kPrimaryColor,
              elevation: 4,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                'Save Note',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
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

  void _handleNoteTap(Note note, String selectedMood) {
    if (note.voicePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoicePage(
            title: note.title,
            timestamp: note.timestamp,
            voicePath: note.voicePath,
            mood: note.mood,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NotePage(note: note, selectedMood: selectedMood),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
