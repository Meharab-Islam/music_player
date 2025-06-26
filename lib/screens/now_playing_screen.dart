import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import '../controllers/music_controller.dart';
import '../widgets/player_controls.dart';
import '../widgets/seek_bar.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicController>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Obx(() {
        final currentIndex = controller.currentIndex.value;
        if (currentIndex < 0 || currentIndex >= controller.songs.length) {
          return const Center(child: Text("No song playing"));
        }
        final currentSong = controller.songs[currentIndex];

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 0, 86, 105), Colors.black],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(),

                  // High-res artwork
                  FutureBuilder<Uint8List?>(
                    future: controller.audioQuery.queryArtwork(
                      currentSong.id,
                      ArtworkType.AUDIO,
                      format: ArtworkFormat.JPEG,
                      size: 1000,
                    ),
                    builder: (context, snap) {
                      final bytes = snap.data;
                      Widget artwork;
                      if (bytes != null && bytes.isNotEmpty) {
                        artwork = Image.memory(
                          bytes,
                          width: size.width * 0.7,
                          height: size.width * 0.7,
                          fit: BoxFit.cover,
                        );
                      } else {
                        artwork = Container(
                          width: size.width * 0.7,
                          height: size.width * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            size: 100,
                            color: Colors.white70,
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: artwork,
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Title & artist
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
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // SeekBar and controls
                  SeekBar(audioPlayer: controller.audioPlayer),
                  const Spacer(),
                  PlayerControls(audioPlayer: controller.audioPlayer),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
