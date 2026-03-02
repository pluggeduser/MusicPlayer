import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/music_providers.dart';
import '../screens/player_screen.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(playerStateProvider).value;
    final isPlaying = playerState?.playing ?? false;

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ListTile(
          leading: Hero(
            tag: 'album_art',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                currentSong.thumbnailUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(currentSong.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(currentSong.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              final playerService = ref.read(playerServiceProvider);
              if (isPlaying) {
                playerService.pause();
              } else {
                playerService.resume();
              }
            },
          ),
        ),
      ),
    );
  }
}
