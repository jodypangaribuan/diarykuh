import 'dart:io';

import 'package:diarykuh/presentation/auth/login_page.dart';
import 'package:diarykuh/presentation/photo/photo_detail_page.dart';
import 'package:diarykuh/presentation/photo/photo_page.dart';
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
import 'package:intl/date_symbol_data_local.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:diarykuh/utils/color_utils.dart';
import '../../models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool isDarkMode = false;
  bool isLoggedIn = false;
  late SharedPreferences prefs;
  String selectedMood = 'Happy';
  final List<String> moods = ['Happy', 'Sad', 'Excited', 'Tired', 'Calm'];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Note> _notes = [];
  var _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  final Map<String, Color> categoryColors = {
    'Note': const Color.fromARGB(255, 76, 186, 255),
    'Album': Color(0xFFFFB7B7),
    'Voice': kSecondaryColor,
  };
  UserModel? currentUser;

  String get currentUserId =>
      prefs.getString('currentUserId') ?? 'default_user';

  AnimationController? _recordingAnimationController;
  Animation<double>? _recordingAnimation;
  bool _isPressing = false;
  bool _isProcessing = false;
  DateTime? _lastRecordingTime;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _recordingAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
    _recordingAnimationController!.repeat(reverse: true);
  }

  Future<void> _initializeApp() async {
    await initializeDateFormatting('id_ID', null);

    prefs = await SharedPreferences.getInstance();
    await _loadCurrentUser();
    await _loadPreferences();
    await _loadNotes();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = prefs.getString('currentUserId');
      if (userId != null) {
        final user = await _dbHelper.getUser(userId);
        setState(() {
          currentUser = user;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  Future<void> _loadNotes() async {
    final notes = await _dbHelper.getNotes(currentUserId);
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
    if (_isProcessing || _isRecording || _isStopping) return;

    try {
      setState(() => _isProcessing = true);

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

        setState(() {
          _isRecording = true;
          _lastRecordingTime = DateTime.now();
        });
      }
    } catch (e) {
      print('Error recording: $e');
      _showErrorSnackbar('Failed to start recording');
      setState(() {
        _isRecording = false;
        _recordingPath = null;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _stopVoiceNote() async {
    if (!_isRecording || _isProcessing || _isStopping) return;

    try {
      setState(() {
        _isStopping = true;
        _isProcessing = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (_isStopping) {
          _forceStopRecording();
        }
      });

      await _audioRecorder.stop();

      if (_recordingPath != null) {
        final note = Note(
          userId: currentUserId,
          title: 'Suaramu',
          content: 'Suaramu',
          mood: selectedMood,
          timestamp: DateTime.now().toString(),
          voicePath: _recordingPath,
          imagePath: null,
        );

        await _dbHelper.insertNote(note);
        await _loadNotes();
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _showErrorSnackbar('Failed to save recording');
      _forceStopRecording();
    } finally {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _isStopping = false;
      });
    }
  }

  void _forceStopRecording() {
    _audioRecorder.dispose();
    _audioRecorder = AudioRecorder();
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _isStopping = false;
      _recordingPath = null;
    });
    _showErrorSnackbar('Recording was force stopped');
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onRefresh() async {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: SpinKitPulsingGrid(
          color: kPrimaryColor,
          size: 50.0,
        ),
      ),
    );

    await _loadPreferences();
    await _loadNotes();

    Navigator.pop(context);
  }

  Future<void> _deleteNote(int noteId) async {
    await _dbHelper.deleteNote(noteId, currentUserId);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : kBackgroundColor,
      body: SafeArea(
        child: LiquidPullToRefresh(
          onRefresh: _onRefresh,
          color: kPrimaryColor,
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          height: 100,
          animSpeedFactor: 2,
          showChildOpacityTransition: false,
          springAnimationDurationInMilliseconds: 1000,
          borderWidth: 2,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                'DiaryKuh ;v',
                style: GoogleFonts.yellowtail(
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : kTextColor,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now()),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildLogoutButton(),
              const SizedBox(width: 8),
              _buildThemeToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
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
          Icons.logout,
          color: kAccentColor,
          size: 24,
        ),
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('currentUserId');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
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
        color: kSecondaryColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child: currentUser?.imagePath != null &&
                    currentUser!.imagePath!.isNotEmpty
                ? ClipOval(
                    child: Image.file(
                      File(currentUser!.imagePath!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.grey);
                      },
                    ),
                  )
                : const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.name != null
                      ? 'Heyyyyooo, ${currentUser!.name}!'
                      : 'Heyyyyooo',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pengen curhat apa hari ini? Spill aja semuanya~ 📝',
                  style: GoogleFonts.montserrat(
                    color: Colors.black.withOpacity(0.9),
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
            'Lagi Gimana Nih?',
            style: GoogleFonts.montserrat(
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
              style: GoogleFonts.montserrat(
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
            'Mau Ngapain Nih?',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton('Mulai Curhat!', Icons.menu_book,
                  const Color.fromARGB(255, 76, 186, 255), () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotePage(
                      selectedMood: selectedMood,
                      userId: currentUserId,
                    ),
                  ),
                );

                if (result is Note) {
                  await _loadNotes();
                  setState(() {});
                }
              }),
              _buildActionButton(
                'Ngomong Aja!',
                _isRecording ? Icons.stop : Icons.mic,
                kSecondaryColor,
                () => _isRecording ? _stopVoiceNote() : _startVoiceNote(),
              ),
              _buildActionButton(
                  'Nambahin Foto', Icons.photo_camera, kAccentColor, () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoPage(
                      selectedMood: selectedMood,
                      userId: currentUserId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadNotes();
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    if (label == 'Ngomong Aja!') {
      return GestureDetector(
        onTapDown: (_) async {
          setState(() => _isPressing = true);
          _recordingAnimationController!.forward();
          await _startVoiceNote();
        },
        onTapUp: (_) async {
          setState(() => _isPressing = false);
          _recordingAnimationController!.reset();
          await _stopVoiceNote();
        },
        onTapCancel: () async {
          setState(() => _isPressing = false);
          _recordingAnimationController!.reset();
          await _stopVoiceNote();
        },
        child: AnimatedBuilder(
          animation: _recordingAnimation!,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRecording ? _recordingAnimation!.value : 1.0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.27,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border:
                      _isRecording ? Border.all(color: color, width: 2) : null,
                  boxShadow: _isRecording
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: color,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecording ? 'Lgi ngerekam...' : label,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
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
            'Curhatan Terbaru Lu!',
            style: GoogleFonts.montserrat(
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
                hasPhoto: note.imagePath != null,
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
                          userId: currentUserId,
                        ),
                      ),
                    );
                  } else if (note.imagePath != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoDetailPage(
                          image: File(note.imagePath!),
                          mood: note.mood,
                          content: note.content,
                        ),
                      ),
                    );
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteDetailPage(
                          note: note,
                          userId: currentUserId,
                        ),
                      ),
                    );
                    _loadNotes();
                  }
                },
                onDelete: () async {
                  await _deleteNote(note.id!);
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
      {VoidCallback? onTap,
      VoidCallback? onDelete,
      bool hasVoice = false,
      bool hasPhoto = false}) {
    String category;
    Color categoryColor;

    if (hasVoice) {
      category = 'Voice';
      categoryColor = kSecondaryColor;
    } else if (hasPhoto) {
      category = 'Album';
      categoryColor = Color(0xFFFFB7B7);
    } else {
      category = 'Note';
      categoryColor = const Color.fromARGB(255, 76, 186, 255);
    }

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
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 50,
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: AnimatedEmoji(
                      _getMoodAnimatedEmoji(mood),
                      size: 30,
                    ),
                  ),
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
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (hasVoice ||
                            hasPhoto ||
                            (!hasVoice && !hasPhoto)) ...[
                          const SizedBox(width: 8),
                          if (hasVoice)
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.mic,
                                size: 14,
                                color: kPrimaryColor,
                              ),
                            ),
                          if (hasPhoto) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kAccentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.photo,
                                size: 14,
                                color: kAccentColor,
                              ),
                            ),
                          ],
                          if (!hasVoice && !hasPhoto) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.menu_book,
                                size: 14,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: categoryColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRelativeTime(time),
                      style: GoogleFonts.montserrat(
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
    if (_isRecording || _isStopping) {
      _forceStopRecording();
    }
    _recordingAnimationController?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
