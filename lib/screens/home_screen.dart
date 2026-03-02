import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/music_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    final searchController = TextEditingController(text: ref.read(searchQueryProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Discovery'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search YouTube Music...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).state = searchController.text;
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: searchResults.when(
        data: (songs) => songs.isEmpty
            ? const Center(child: Text('Search for your favorite tracks'))
            : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongTile(song: song);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class SongTile extends ConsumerWidget {
  final Song song;
  const SongTile({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadProgress = ref.watch(downloadProgressProvider(song.id));

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          song.thumbnailUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (downloadProgress > 0 && downloadProgress < 1)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(value: downloadProgress, strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              onPressed: () async {
                final downloadService = ref.read(downloadServiceProvider);
                await downloadService.downloadSong(
                  song,
                  onProgress: (progress) {
                    ref.read(downloadProgressProvider(song.id).notifier).state = progress;
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              ref.read(currentSongProvider.notifier).state = song;
              ref.read(playerServiceProvider).playSong(song);
            },
          ),
        ],
      ),
    );
  }
}
