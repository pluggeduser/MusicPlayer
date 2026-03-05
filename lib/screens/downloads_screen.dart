import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/music_providers.dart';
import '../screens/playlist_screen.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedSongs = ref.watch(downloadedSongsProvider);
    final playlists = ref.watch(playlistsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          actions: [
            // Create playlist button
            IconButton(
              icon: const Icon(Icons.playlist_add),
              tooltip: 'New Playlist',
              onPressed: () => _showCreatePlaylistDialog(context, ref),
            ),
            // Play all downloaded songs
            if (downloadedSongs.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                tooltip: 'Play All',
                onPressed: () {
                  playQueue(ref, downloadedSongs, startIndex: 0, shuffle: false);
                },
              ),
            if (downloadedSongs.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.shuffle_rounded),
                tooltip: 'Shuffle All',
                onPressed: () {
                  playQueue(ref, downloadedSongs, startIndex: 0, shuffle: true);
                },
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.download_done), text: 'Songs'),
              Tab(icon: Icon(Icons.queue_music), text: 'Playlists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Songs tab
            downloadedSongs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_music_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No downloaded songs yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: downloadedSongs.length,
                    itemBuilder: (context, index) {
                      final song = downloadedSongs[index];
                      return DownloadedSongTile(
                        song: song,
                        queue: downloadedSongs,
                        queueIndex: index,
                      );
                    },
                  ),
            // Playlists tab
            playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.queue_music_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No playlists yet',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create Playlist'),
                          onPressed: () =>
                              _showCreatePlaylistDialog(context, ref),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final songCount = playlist.songIds.length;
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              const Icon(Icons.queue_music, size: 28),
                        ),
                        title: Text(playlist.name),
                        subtitle: Text('$songCount song${songCount != 1 ? 's' : ''}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              ref
                                  .read(playlistsProvider.notifier)
                                  .deletePlaylist(playlist.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style:
                                          TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaylistScreen(
                                playlist: playlist,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlistsProvider.notifier).createPlaylist(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class DownloadedSongTile extends ConsumerWidget {
  final Song song;
  final List<Song> queue;
  final int queueIndex;

  const DownloadedSongTile({
    super.key,
    required this.song,
    required this.queue,
    required this.queueIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);

    return ListTile(
      onTap: () {
        playQueue(ref, queue, startIndex: queueIndex, shuffle: false);
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
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${song.artist}${song.albumName != null ? " • ${song.albumName}" : ""}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value == 'play') {
            playQueue(ref, queue, startIndex: queueIndex, shuffle: false);
          } else if (value == 'remove') {
            ref.read(downloadedSongsProvider.notifier).removeSong(song.id);
          } else if (value.startsWith('playlist_')) {
            final playlistId = value.replaceFirst('playlist_', '');
            ref
                .read(playlistsProvider.notifier)
                .addSongToPlaylist(playlistId, song.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to playlist')),
            );
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'play',
            child: Row(children: [
              Icon(Icons.play_arrow),
              SizedBox(width: 8),
              Text('Play'),
            ]),
          ),
          const PopupMenuDivider(),
          // Add to playlist submenu items
          if (playlists.isEmpty)
            const PopupMenuItem(
              enabled: false,
              child: Text('No playlists — create one first',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            ...playlists.map(
              (pl) => PopupMenuItem(
                value: 'playlist_${pl.id}',
                child: Row(children: [
                  const Icon(Icons.playlist_add, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text('Add to "${pl.name}"',
                          overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'remove',
            child: Row(children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Remove', style: TextStyle(color: Colors.red)),
            ]),
          ),
        ],
      ),
    );
  }
}
