import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final bool isPlaying; // show animation if true

  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          artworkBorder: BorderRadius.circular(8.0),
          nullArtworkWidget: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.music_note, color: Colors.white),
          ),
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
        trailing: isPlaying ? const _EqualizerAnimation() : null,
        onTap: onTap,
      ),
    );
  }
}

class _EqualizerAnimation extends StatefulWidget {
  const _EqualizerAnimation();

  @override
  State<_EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<_EqualizerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bar1;
  late Animation<double> _bar2;
  late Animation<double> _bar3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bar1 = Tween<double>(begin: 5, end: 15)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _bar2 = Tween<double>(begin: 8, end: 20)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _bar3 = Tween<double>(begin: 5, end: 10)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: Colors.tealAccent,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [_bar(_bar1.value), _bar(_bar2.value), _bar(_bar3.value)],
        ),
      ),
    );
  }
}
