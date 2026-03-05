import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/music_providers.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(playerStateProvider).value;
    final position = ref.watch(playerProgressProvider).value ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).value;
    final isPlaying = playerState?.playing ?? false;
    final shuffleOn = ref.watch(shuffleModeProvider);
    final processingState = playerState?.processingState;

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No song playing')),
      );
    }

    // Safe max value — avoid NaN/zero division
    final maxSeconds = (duration != null && duration.inSeconds > 0)
        ? duration.inSeconds.toDouble()
        : (currentSong.duration.inSeconds > 0
            ? currentSong.duration.inSeconds.toDouble()
            : 1.0);

    final posSeconds =
        position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Album Art
                Expanded(
                  flex: 5,
                  child: Hero(
                    tag: 'album_art',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        currentSong.thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[850],
                          child: const Icon(Icons.music_note,
                              size: 80, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Song Info
                Text(
                  currentSong.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  currentSong.artist,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                // Seek Bar
                Slider(
                  value: posSeconds,
                  min: 0,
                  max: maxSeconds,
                  onChanged: (value) {
                    ref
                        .read(playerServiceProvider)
                        .seek(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall),
                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                      else
                        Text(
                          _formatDuration(duration ?? currentSong.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle toggle
                    IconButton(
                      iconSize: 28,
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: shuffleOn
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () {
                        final newShuffle = !shuffleOn;
                        ref.read(shuffleModeProvider.notifier).state =
                            newShuffle;
                        ref.read(playerServiceProvider).toggleShuffle();
                      },
                    ),
                    // Skip Previous
                    IconButton(
                      iconSize: 44,
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: () async {
                        await ref
                            .read(playerServiceProvider)
                            .skipToPrevious();
                        // Update current song state
                        final svc = ref.read(playerServiceProvider);
                        if (svc.currentSong != null) {
                          ref.read(currentSongProvider.notifier).state =
                              svc.currentSong;
                        }
                      },
                    ),
                    // Play / Pause
                    IconButton(
                      iconSize: 80,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      onPressed: () {
                        final playerService =
                            ref.read(playerServiceProvider);
                        if (isPlaying) {
                          playerService.pause();
                        } else {
                          playerService.resume();
                        }
                      },
                    ),
                    // Skip Next
                    IconButton(
                      iconSize: 44,
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: () async {
                        await ref
                            .read(playerServiceProvider)
                            .skipToNext();
                        final svc = ref.read(playerServiceProvider);
                        if (svc.currentSong != null) {
                          ref.read(currentSongProvider.notifier).state =
                              svc.currentSong;
                        }
                      },
                    ),
                    // Repeat placeholder (visual balance)
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.repeat_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
