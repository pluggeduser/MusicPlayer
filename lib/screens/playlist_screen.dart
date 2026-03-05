import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/music_providers.dart';

/// Screen showing the songs inside a specific playlist
class PlaylistScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedSongs = ref.watch(downloadedSongsProvider);
    // Get the actual song objects for this playlist
    final playlistSongs = playlist.songIds
        .map((id) {
          try {
            return downloadedSongs.firstWhere((s) => s.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Song>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (playlistSongs.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: 'Play All',
              onPressed: () {
                playQueue(ref, playlistSongs, startIndex: 0, shuffle: false);
                Navigator.of(context).pop();
              },
            ),
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: 'Shuffle All',
              onPressed: () {
                playQueue(ref, playlistSongs, startIndex: 0, shuffle: true);
                Navigator.of(context).pop();
              },
            ),
          ]
        ],
      ),
      body: playlistSongs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No songs in this playlist',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: playlistSongs.length,
              itemBuilder: (context, index) {
                final song = playlistSongs[index];
                return ListTile(
                  onTap: () {
                    playQueue(ref, playlistSongs,
                        startIndex: index, shuffle: false);
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note),
                      ),
                    ),
                  ),
                  title: Text(song.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    tooltip: 'Remove from playlist',
                    onPressed: () {
                      ref
                          .read(playlistsProvider.notifier)
                          .removeSongFromPlaylist(playlist.id, song.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}
