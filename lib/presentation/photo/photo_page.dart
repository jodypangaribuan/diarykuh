import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/database_helper.dart';
import '../../models/note_model.dart';
import 'photo_detail_page.dart';

const Color kPrimaryColor = Color.fromARGB(255, 119, 112, 248);
const Color kSecondaryColor = Color.fromARGB(255, 154, 151, 255);
const Color kAccentColor = Color(0xFFFF9E9E);
const Color kBackgroundColor = Color.fromARGB(255, 233, 233, 239);

class PhotoPage extends StatefulWidget {
  final String selectedMood;
  const PhotoPage({Key? key, required this.selectedMood}) : super(key: key);

  @override
  _PhotoPageState createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];

  Future<void> _getImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final List<XFile> selectedImages = await _picker.pickMultiImage();
      if (selectedImages.isNotEmpty) {
        setState(() {
          _images.addAll(selectedImages.map((image) => File(image.path)));
        });
      }
    } else {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo != null) {
        setState(() {
          _images.add(File(photo.path));
        });
      }
    }
  }

  Future<void> _savePhotos() async {
    if (_images.isEmpty) return;

    // Create a directory for storing multiple photos
    final directory = await getApplicationDocumentsDirectory();
    final albumPath =
        '${directory.path}/album_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(albumPath).create(recursive: true);

    // Copy all images to the album directory and get their paths
    List<String> imagePaths = [];
    for (var i = 0; i < _images.length; i++) {
      final newPath = '$albumPath/photo_$i.jpg';
      await _images[i].copy(newPath);
      imagePaths.add(newPath);
    }

    // Save as a single note with all image paths
    final note = Note(
      title: 'Photo Album',
      content: imagePaths.join('|'), // Store multiple paths separated by '|'
      mood: widget.selectedMood,
      timestamp: DateTime.now().toString(),
      imagePath: imagePaths.first, // Store first image as thumbnail
      voicePath: null,
    );

    await DatabaseHelper().insertNote(note);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(),
        actions: [
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildSaveButton(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildPhotoGrid(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Expanded(
      child: _images.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return _buildPhotoItem(_images[index], index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: kPrimaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Photos Added Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the buttons below to add photos',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(File image, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoDetailPage(
              image: image,
              mood: widget.selectedMood,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _images.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Camera',
            Icons.camera_alt,
            () => _getImage(ImageSource.camera),
          ),
          _buildActionButton(
            'Gallery',
            Icons.photo_library,
            () => _getImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: kPrimaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: kPrimaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: kPrimaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _savePhotos,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.save, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}