import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/screens/now_playing_screen.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final AudioPlayer audioPlayer = AudioPlayer();

  // Observable states
  var songs = <SongModel>[].obs;

  var currentIndex = (-1).obs;
  var isPlaying = false.obs;
  var isPaused = false.obs;
  var isMiniPlayerVisible = false.obs;

  var isPermissionGranted = false.obs;
  var isRequestingPermission = false.obs;

  var searchQuery = ''.obs;

  // Subscriptions to audio player state streams
  late final StreamSubscription<int?> _currentIndexSub;
  late final StreamSubscription<bool> _playingSub;
  late final StreamSubscription<ProcessingState> _processingSub;

  // Computed filtered list based on search
  List<SongModel> get filteredSongs {
    if (searchQuery.value.trim().isEmpty) return songs;
    final query = searchQuery.value.toLowerCase();
    return songs.where((s) => s.title.toLowerCase().contains(query)).toList();
  }

  @override
  void onInit() {
    super.onInit();

    _currentIndexSub = audioPlayer.currentIndexStream.listen((index) {
      currentIndex.value = index ?? -1;
    });

    _playingSub = audioPlayer.playingStream.listen((playing) {
      isPlaying.value = playing;
      if (playing) {
        isPaused.value = false;
        isMiniPlayerVisible.value = true;
      }
    });

    _processingSub = audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.ready && !audioPlayer.playing) {
        isPaused.value = true;
        isPlaying.value = false;
        isMiniPlayerVisible.value = true;
      } else if (state == ProcessingState.completed) {
        _resetPlayerState();
      }
    });

    Future.delayed(
      const Duration(milliseconds: 300),
      checkAndRequestPermission,
    );
  }

  @override
  void onClose() {
    _currentIndexSub.cancel();
    _playingSub.cancel();
    _processingSub.cancel();
    audioPlayer.dispose();
    super.onClose();
  }

  void _resetPlayerState() {
    isPlaying.value = false;
    isPaused.value = false;
    currentIndex.value = -1;
    isMiniPlayerVisible.value = false;
  }

  // Build playlist from songs
  ConcatenatingAudioSource createPlaylist() {
    return ConcatenatingAudioSource(
      children: songs
          .map((song) => AudioSource.uri(Uri.parse(song.uri!)))
          .toList(),
    );
  }

  // Load songs from device
  Future<void> loadSongs() async {
    try {
      final allSongs = await audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      songs.value = allSongs
          .where((song) => song.duration != null && song.duration! > 60000)
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load songs');
      print("Load songs error: $e");
    }
  }

  Future<void> checkAndRequestPermission() async {
    if (isRequestingPermission.value) {
      // Already requesting, just return early
      return;
    }

    isRequestingPermission.value = true;

    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        if (Platform.version.compareTo('33') >= 0) {
          status = await Permission.audio.status;
          if (!status.isGranted) {
            status = await Permission.audio.request();
          }
        } else {
          status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }

        isPermissionGranted.value = status.isGranted;
        if (status.isGranted) await loadSongs();
      }
    } catch (e) {
      print('Permission request error: $e');
    } finally {
      isRequestingPermission.value = false;
    }
  }

  /// Plays song at given index in full playlist
  Future<void> playSongAtIndex(int index) async {
    try {
      await audioPlayer.setAudioSource(createPlaylist(), initialIndex: index);
      // Get.to(NowPlayingScreen());
      await audioPlayer.play();
    } catch (e) {
      Get.snackbar('Error', 'Failed to play song');
      print("Playback error: $e");
    }
  }

  Future<void> play() => audioPlayer.play();
  Future<void> pause() => audioPlayer.pause();

  Future<void> stop() async {
    await audioPlayer.stop();
    _resetPlayerState();
  }

  Future<void> next() async {
    if (audioPlayer.hasNext) {
      await audioPlayer.seekToNext();
    }
  }

  Future<void> previous() async {
    if (audioPlayer.hasPrevious) {
      await audioPlayer.seekToPrevious();
    }
  }

  Future<void> closeMiniPlayer() async {
    await stop();
  }
}
