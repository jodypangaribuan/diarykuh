import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database_helper.dart';
import '../../models/note_model.dart';
import '../voice/voice_page.dart';
import 'dart:io';

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
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentMood = widget.note?.mood ?? widget.selectedMood;
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      if (widget.note!.imagePaths != null) {
        _selectedImages.addAll(widget.note!.imagePaths!);
      }
    }
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
      imagePath: widget.note?.imagePath,
      imagePaths: _selectedImages,
    );

    if (widget.note == null) {
      await _dbHelper.insertNote(note);
    } else {
      await _dbHelper.updateNote(note);
    }

    Navigator.pop(context, true);
  }

  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return _buildAddImageButton();
          }
          return _buildImageThumbnail(index);
        },
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

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add_photo_alternate, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildImagePreview(),
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Implement more options
                    },
                  ),
                ],
              ),
            ],
          ),
          TextField(
            controller: _titleController,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              counterText: '', // Hide character counter
            ),
            maxLines: 1,
            maxLength: 100, // Limit title length
            onChanged: (value) => setState(() => _isEdited = true),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                DateTime.now().toString().substring(0, 16),
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    AnimatedEmoji(
                      _getMoodAnimatedEmoji(_currentMood),
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentMood,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6C63FF),
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
      child: TextField(
        controller: _contentController,
        style: GoogleFonts.poppins(
          fontSize: 16,
          height: 1.5,
        ),
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Write your thoughts...',
          border: InputBorder.none,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        onChanged: (value) => setState(() => _isEdited = true),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedOpacity(
      opacity: _isEdited ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        onPressed: _saveNote,
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.save),
        label: Text(
          'Save',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
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
