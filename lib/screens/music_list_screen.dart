import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/mini_player.dart';

class MusicListScreen extends StatelessWidget {
  const MusicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MusicController());
    final searchController = TextEditingController();
    FocusScope.of(context).unfocus();

    return Scaffold(
      appBar: AppBar(title: const Text('My Offline Music'), elevation: 2),
      body: Obx(() {
        if (!controller.isPermissionGranted.value) {
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
                  onPressed: controller.checkAndRequestPermission,
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );
        }

        if (controller.songs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => controller.searchQuery.value = value,
                    decoration: InputDecoration(
                      hintText: 'Search by song name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final filteredSongs = controller.filteredSongs;
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: controller.filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = controller.filteredSongs[index];

                        return Obx(() {
                          // Determine if this tile is for the currently playing song
                          final isCurrent =
                              controller.currentIndex.value == index;
                          final isPlaying = controller.isPlaying.value;

                          return SongListTile(
                            key: ValueKey(song.id),
                            song: song,
                            isPlaying: isCurrent && isPlaying,
                            onTap: () async {
                              // Close the keyboard if it's open
                              FocusScope.of(context).unfocus();

                              // Play the selected song
                              await controller.playSongAtIndex(index);
                            },
                          );
                        });
                      },
                    );
                  }),
                ),
              ],
            ),

            // Mini Player
            Align(
              alignment: Alignment.bottomCenter,
              child: Obx(
                () => controller.isMiniPlayerVisible.value
                    ? MiniPlayer(controller: controller)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      }),
    );
  }
}
