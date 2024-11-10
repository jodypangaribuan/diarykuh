import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database_helper.dart';
import '../../models/note_model.dart';
import '../voice/voice_page.dart';
import 'dart:io';
import 'package:diarykuh/utils/color_utils.dart';

class NotePage extends StatefulWidget {
  final Note? note;
  final String selectedMood;
  final String userId;

  const NotePage({
    Key? key,
    this.note,
    required this.selectedMood,
    required this.userId,
  }) : super(key: key);

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
    try {
      if (!_isEdited) {
        Navigator.of(context).pop(widget.note);
        return;
      }

      final note = Note(
        id: widget.note?.id,
        userId: widget.userId,
        title: _titleController.text.isEmpty
            ? 'Tidak Berjudul'
            : _titleController.text,
        content: _contentController.text,
        mood: _currentMood,
        timestamp: DateTime.now().toString(),
        voicePath: widget.note?.voicePath,
        imagePaths: _selectedImages,
      );

      if (widget.note == null) {
        final id = await _dbHelper.insertNote(note);

        final savedNote = note.copyWith(id: id);
        print('New note inserted with id: $id');
        if (mounted) Navigator.of(context).pop(savedNote);
      } else {
        if (note.id == null) {
          throw Exception('Cannot update note: ID is null');
        }
        final result = await _dbHelper.updateNote(note);
        print('Note updated with result: $result');
        if (mounted) Navigator.of(context).pop(note);
      }
    } catch (e) {
      print('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _buildEditingArea(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _titleController,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
              decoration: InputDecoration(
                hintText: 'Judul Curhatanmu',
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  color: kTextColor.withOpacity(0.6),
                ),
              ),
              onChanged: (value) => setState(() => _isEdited = true),
            ),
          ),
          _buildMoodIndicator(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(Icons.arrow_back, color: kTextColor, size: 20),
      ),
    );
  }

  Widget _buildMoodIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedEmoji(_getMoodAnimatedEmoji(_currentMood), size: 18),
          SizedBox(width: 4),
          Text(
            _currentMood,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: kTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingArea() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: TextField(
              controller: _contentController,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                height: 1.8,
                color: Colors.black87,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Mulai curhat disini...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.quicksand(
                  color: Colors.black38,
                ),
              ),
              onChanged: (value) => setState(() => _isEdited = true),
            ),
          ),
          if (_selectedImages.isNotEmpty) _buildImagePreview(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 76, 186, 255).withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image_outlined),
            onPressed: _pickImage,
            color: Color.fromARGB(255, 0, 157, 255),
          ),
          const Spacer(),
          Text(
            '$_characterCount characters',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            label: Text('Batalkan'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isEdited ? _saveNote : null,
            icon: Icon(Icons.check),
            label: Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 76, 186, 255),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
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
            userId: widget.userId,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotePage(
              note: note, selectedMood: selectedMood, userId: widget.userId),
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 10),
            child: Image.file(
              File(_selectedImages[index]),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
