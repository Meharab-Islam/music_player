import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerControls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const PlayerControls({super.key, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 48),
          color: Colors.white,
          onPressed: audioPlayer.hasPrevious ? audioPlayer.seekToPrevious : null,
        ),
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
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
                onPressed: audioPlayer.play,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.pause_rounded, size: 64),
                color: Colors.white,
                onPressed: audioPlayer.pause,
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 48),
          color: Colors.white,
          onPressed: audioPlayer.hasNext ? audioPlayer.seekToNext : null,
        ),
      ],
    );
  }
}
