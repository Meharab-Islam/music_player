import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    // Listen to playback events from just_audio and update audio_service state
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: [0, 1, 2],
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        processingState: _mapProcessingState(_player.processingState),
      ));
    });

    // When the current track changes, update mediaItem (for notification display)
    _player.currentIndexStream.listen((index) {
      if (index == null || _playlist.isEmpty) {
        mediaItem.add(null);
      } else {
        mediaItem.add(_playlist[index]);
      }
    });
  }

  List<MediaItem> _playlist = [];

  // Helper to map just_audio ProcessingState to audio_service AudioProcessingState
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // Set playlist from SongModel list
  Future<void> setPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    _playlist = songs.map((song) {
      return MediaItem(
        id: song.id.toString(),
        album: song.album ?? '',
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        duration: Duration(milliseconds: song.duration ?? 0),
        artUri: song.albumId != null
            ? Uri.parse(song.album!)
            : null,
      );
    }).toList();

    final sources = songs
        .map((song) => AudioSource.uri(Uri.parse(song.uri!),
            tag: MediaItem(
              id: song.id.toString(),
              album: song.album ?? '',
              title: song.title,
              artist: song.artist ?? 'Unknown Artist',
              duration: Duration(milliseconds: song.duration ?? 0),
            )))
        .toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex,
    );
  }

  // AudioHandler overrides to control playback:

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
}
