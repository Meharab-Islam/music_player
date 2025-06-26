import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:core';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Music Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        // Use a modern, clean font
        fontFamily: 'Roboto', 
      ),
      debugShowCheckedModeBanner: false,
      home: const MusicListScreen(),
    );
  }
}

//-----------------------------------//
//         MUSIC LIST SCREEN         //
//-----------------------------------//
class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  // Method to check and request permissions
  Future<void> _checkAndRequestPermissions() async {
    var status = await Permission.audio.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      _loadSongs();
    } else {
      // Show a dialog or message if permission is denied
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  // Method to load audio files from storage
  Future<void> _loadSongs() async {
    // Query for songs, excluding notifications and ringtones
    List<SongModel> songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Filter out short audio files that are likely not music
    songs = songs.where((song) => song.duration != null && song.duration! > 60000).toList();

    setState(() {
      _songs = songs;
    });
  }

  // Navigate to the Now Playing screen
  void _navigateToNowPlaying(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlayingScreen(
          songs: _songs,
          audioPlayer: _audioPlayer,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offline Music'),
        elevation: 2,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Storage permission is required to play music.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkAndRequestPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.music_note, color: Colors.white),
              ),
              artworkBorder: BorderRadius.circular(8.0),
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              song.artist ?? "Unknown Artist",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _navigateToNowPlaying(index),
          ),
        );
      },
    );
  }
}

//-----------------------------------//
//        NOW PLAYING SCREEN         //
//-----------------------------------//
class NowPlayingScreen extends StatefulWidget {
  final List<SongModel> songs;
  final AudioPlayer audioPlayer;
  final int initialIndex;

  const NowPlayingScreen({
    super.key,
    required this.songs,
    required this.audioPlayer,
    required this.initialIndex,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late int _currentIndex;
  late ConcatenatingAudioSource _playlist;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupPlaylist();
  }

  // Setup the playlist for just_audio
  void _setupPlaylist() async {
    _playlist = ConcatenatingAudioSource(
      children: widget.songs
          .map((song) => AudioSource.uri(Uri.parse(song.uri!)))
          .toList(),
    );

    try {
      await widget.audioPlayer.setAudioSource(
        _playlist,
        initialIndex: _currentIndex,
      );
      widget.audioPlayer.play();
    } catch (e) {
      // Handle error, e.g., file not found
      print("Error setting up playlist: $e");
    }
  }

  // Format duration to mm:ss
  String _formatDuration(Duration? d) {
    if (d == null) return "00:00";
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade800,
              Colors.black,
            ],
          ),
        ),
        child: StreamBuilder<SequenceState?>(
          stream: widget.audioPlayer.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.sequence.isEmpty ?? true) {
              return const Center(child: Text("No song playing"));
            }
            _currentIndex = state?.currentIndex ?? 0;
            final currentSong = widget.songs[_currentIndex];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Album Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: QueryArtworkWidget(
                        id: currentSong.id,
                        type: ArtworkType.AUDIO,
                        artworkWidth: MediaQuery.of(context).size.width * 0.7,
                        artworkHeight: MediaQuery.of(context).size.width * 0.7,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: Container(
                           width: MediaQuery.of(context).size.width * 0.7,
                           height: MediaQuery.of(context).size.width * 0.7,
                           decoration: BoxDecoration(
                               color: Colors.grey.shade800,
                               borderRadius: BorderRadius.circular(16.0)),
                           child: const Icon(Icons.music_note, size: 100, color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Song Title and Artist
                    Text(
                      currentSong.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentSong.artist ?? "Unknown Artist",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Seek Bar and Duration
                    _buildSeekBar(),
                    
                    const Spacer(),
                    // Playback Controls
                    _buildControls(),
                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Widget for Seek Bar
  Widget _buildSeekBar() {
    return StreamBuilder<Duration?>(
      stream: widget.audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: widget.audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            var position = positionSnapshot.data ?? Duration.zero;
            if (position > duration) {
              position = duration;
            }
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                    trackHeight: 2.0,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    value: position.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      widget.audioPlayer.seek(Duration(milliseconds: value.round()));
                    },
                    activeColor: Colors.tealAccent,
                    inactiveColor: Colors.white24,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget for Playback Controls
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous Button
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 48),
          color: Colors.white,
          onPressed: widget.audioPlayer.hasPrevious
              ? widget.audioPlayer.seekToPrevious
              : null,
        ),
        // Play/Pause Button
        StreamBuilder<PlayerState>(
          stream: widget.audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(color: Colors.white),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow_rounded, size: 64),
                color: Colors.white,
                onPressed: widget.audioPlayer.play,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.pause_rounded, size: 64),
                color: Colors.white,
                onPressed: widget.audioPlayer.pause,
              );
            }
          },
        ),
        // Next Button
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 48),
          color: Colors.white,
          onPressed:
              widget.audioPlayer.hasNext ? widget.audioPlayer.seekToNext : null,
        ),
      ],
    );
  }
}
