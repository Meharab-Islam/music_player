import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_player/controllers/music_controller.dart';
import 'screens/music_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // try {
  //   await JustAudioBackground.init(
  //     androidNotificationChannelId: 'com.example.music_player.channel.audio',
  //     androidNotificationChannelName: 'Music Playback',
  //     androidNotificationOngoing: true,
  //   );
  // } catch (e) {
  //   print("JustAudioBackground init error: $e");
  // }

  Get.put(MusicController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Offline Music Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const MusicListScreen(),
    );
  }
}
