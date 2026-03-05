import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        child: Row(
          children: [
            // Album art
            Hero(
              tag: 'album_art',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  currentSong.thumbnailUrl,
                  width: 56,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 70,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Song info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currentSong.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Skip Previous
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: () async {
                await ref.read(playerServiceProvider).skipToPrevious();
                final svc = ref.read(playerServiceProvider);
                if (svc.currentSong != null) {
                  ref.read(currentSongProvider.notifier).state =
                      svc.currentSong;
                }
              },
            ),
            // Play / Pause
            IconButton(
              iconSize: 36,
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
            // Skip Next
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: () async {
                await ref.read(playerServiceProvider).skipToNext();
                final svc = ref.read(playerServiceProvider);
                if (svc.currentSong != null) {
                  ref.read(currentSongProvider.notifier).state =
                      svc.currentSong;
                }
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
