import 'package:diarykuh/presentation/voice/voice_page.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:animated_emoji/animated_emoji.dart';
import '../note/note_page.dart';
import '../../data/database_helper.dart';
import '../../models/note_model.dart';
import '../note/note_detail_page.dart';

const Color kPrimaryColor = Color.fromARGB(255, 119, 112, 248);
const Color kSecondaryColor = Color.fromARGB(255, 154, 151, 255);
const Color kAccentColor = Color(0xFFFF9E9E);
const Color kBackgroundColor = Color.fromARGB(255, 233, 233, 239);
const Color kTextColor = Color(0xFF2D3142);

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = false;
  bool isLoggedIn = false;
  late SharedPreferences prefs;
  String selectedMood = 'Happy';
  final List<String> moods = ['Happy', 'Sad', 'Excited', 'Tired', 'Calm'];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Note> _notes = [];
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadNotes();
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  Future<void> _loadNotes() async {
    final notes = await _dbHelper.getNotes();
    setState(() {
      _notes = notes;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> _toggleLogin() async {
    setState(() {
      isLoggedIn = !isLoggedIn;
    });
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  Future<void> _startVoiceNote() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        _recordingPath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        final config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: _recordingPath!);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print('Error recording: $e');
    }
  }

  Future<void> _stopVoiceNote() async {
    try {
      await _audioRecorder.stop();

      final note = Note(
        title: 'Voice Note',
        content: '',
        mood: selectedMood,
        timestamp: DateTime.now().toString(),
        voicePath: _recordingPath,
        imagePath: null,
      );

      await _dbHelper.insertNote(note);
      _loadNotes();
      setState(() => _isRecording = false);
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _onRefresh() async {
    // Reload data
    await _loadPreferences();
    await _loadNotes();
    setState(() {
      // Update current date/time if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : kBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: kPrimaryColor,
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Important for refresh to work
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildProfileSection(),
                _buildMoodTrackerNew(),
                _buildQuickActionsNew(),
                _buildRecentEntriesNew(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DiaryKuh',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : kTextColor,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildThemeToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: isDarkMode ? Colors.white : kTextColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kSecondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: kPrimaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'How are you feeling today?',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrackerNew() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Mood',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : kTextColor,
            ),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: moods.length,
            itemBuilder: (context, index) => _buildMoodItem(moods[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodItem(String mood) {
    bool isSelected = selectedMood == mood;
    return GestureDetector(
      onTap: () => setState(() => selectedMood = mood),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? kAccentColor
              : isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              child: AnimatedEmoji(
                _getMoodAnimatedEmoji(mood),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mood,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : isDarkMode
                        ? Colors.white70
                        : kTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildQuickActionsNew() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton('New Entry', Icons.edit_note, kPrimaryColor,
                  () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NotePage(selectedMood: selectedMood)),
                );
                if (result == true) {
                  _loadNotes();
                }
              }),
              _buildActionButton(
                'Voice Note',
                _isRecording ? Icons.stop : Icons.mic,
                kSecondaryColor,
                () => _isRecording ? _stopVoiceNote() : _startVoiceNote(),
              ),
              _buildActionButton(
                  'Add Photo', Icons.photo_camera, kAccentColor, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.27,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntriesNew() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Entries',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return _buildEntryCard(
                note.title,
                note.timestamp,
                note.mood,
                hasVoice: note.voicePath != null,
                onTap: () async {
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
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteDetailPage(note: note),
                      ),
                    );
                    _loadNotes();
                  }
                },
                onDelete: () async {
                  await _dbHelper.deleteNote(note.id!);
                  _loadNotes();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(String timestamp) {
    final now = DateTime.now();
    final date = DateTime.parse(timestamp);
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} detik yang lalu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun yang lalu';
    }
  }

  Widget _buildEntryCard(String title, String time, String mood,
      {VoidCallback? onTap, VoidCallback? onDelete, bool hasVoice = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              child: AnimatedEmoji(
                _getMoodAnimatedEmoji(mood),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (hasVoice) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.mic,
                          size: 16,
                          color: kPrimaryColor,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _getRelativeTime(time),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
                color: kAccentColor,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 8),
              ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
