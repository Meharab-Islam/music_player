import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import '../controllers/music_controller.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  final MusicController controller;

  const MiniPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;

      if (index < 0 || index >= controller.songs.length) {
        return const SizedBox.shrink();
      }

      final currentSong = controller.songs[index];
      final isPaused = controller.isPaused.value;
      final isPlaying = controller.isPlaying.value;

      return Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: const Border(top: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.to(() => const NowPlayingScreen()),
              child: QueryArtworkWidget(
                id: currentSong.id,
                type: ArtworkType.AUDIO,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.circular(8),
                nullArtworkWidget: const Icon(Icons.music_note, size: 48),
              ),
            ),
            const SizedBox(width: 12),

            // Song title & artist
            Expanded(
              child: GestureDetector(
                onTap: () => Get.to(() => const NowPlayingScreen()),
                child: Container(
                  color: Colors.transparent, // Makes the whole area tappable
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentSong.artist ?? "Unknown Artist",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (isPlaying)
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () async {
                  if (controller.audioPlayer.hasNext) {
                    await controller.previous();
                  } else {
                    Get.snackbar("End of playlist", "No next song found");
                  }
                },
              ),

            // Play/Pause
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                isPlaying ? controller.pause() : controller.play();
              },
            ),

            // Show Next when playing, Close when paused
            if (!isPlaying)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close Mini Player',
                onPressed: controller.closeMiniPlayer,
              )
            else
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () async {
                  if (controller.audioPlayer.hasNext) {
                    await controller.next();
                  } else {
                    Get.snackbar("End of playlist", "No next song found");
                  }
                },
              ),
          ],
        ),
      );
    });
  }
}
