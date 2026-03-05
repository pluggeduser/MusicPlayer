import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/music_providers.dart';
import '../services/permission_helper.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    final searchController =
        TextEditingController(text: ref.read(searchQueryProvider));

    return Column(
      children: [
        AppBar(
          title: const Text('Player'),
          actions: [
            searchResults.when(
              data: (songs) {
                if (songs.isNotEmpty) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow_rounded),
                        tooltip: 'Play All',
                        onPressed: () {
                          playQueue(ref, songs, startIndex: 0, shuffle: false);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded),
                        tooltip: 'Shuffle All',
                        onPressed: () {
                          playQueue(ref, songs, startIndex: 0, shuffle: true);
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search YouTube Music...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state =
                          searchController.text;
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: searchResults.when(
            data: (songs) => songs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Search for your favorite tracks',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return OnlineSongTile(
                        song: song,
                        queue: songs,
                        queueIndex: index,
                      );
                    },
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}

class OnlineSongTile extends ConsumerStatefulWidget {
  final Song song;
  final List<Song> queue;
  final int queueIndex;

  const OnlineSongTile({
    super.key,
    required this.song,
    required this.queue,
    required this.queueIndex,
  });

  @override
  ConsumerState<OnlineSongTile> createState() => _OnlineSongTileState();
}

class _OnlineSongTileState extends ConsumerState<OnlineSongTile> {
  bool _downloading = false;

  Future<void> _download() async {
    final granted = await PermissionHelper.requestStoragePermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission required to download.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _downloading = true);

    final downloadService = ref.read(downloadServiceProvider);
    final path = await downloadService.downloadSong(
      widget.song,
      onProgress: (progress) {
        ref
            .read(downloadProgressProvider(widget.song.id).notifier)
            .state = progress;
      },
    );

    setState(() => _downloading = false);

    if (path != null) {
      final downloadedSong = widget.song.copyWith(localPath: path);
      ref.read(downloadedSongsProvider.notifier).addSong(downloadedSong);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${widget.song.title}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadProgress =
        ref.watch(downloadProgressProvider(widget.song.id));
    final downloadedSongs = ref.watch(downloadedSongsProvider);
    final isDownloaded =
        downloadedSongs.any((s) => s.id == widget.song.id);

    return ListTile(
      onTap: () {
        playQueue(ref, widget.queue,
            startIndex: widget.queueIndex, shuffle: false);
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.song.thumbnailUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 56,
            height: 56,
            color: Colors.grey[800],
            child: const Icon(Icons.music_note),
          ),
        ),
      ),
      title: Text(widget.song.title,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(widget.song.artist,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download button/status
          if (isDownloaded)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.download_done,
                  color: Colors.greenAccent, size: 20),
            )
          else if (_downloading ||
              (downloadProgress > 0 && downloadProgress < 1))
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: downloadProgress > 0 ? downloadProgress : null,
                strokeWidth: 2,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: 'Download',
              onPressed: _download,
            ),
          // Play button
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Play',
            onPressed: () {
              playQueue(ref, widget.queue,
                  startIndex: widget.queueIndex, shuffle: false);
            },
          ),
        ],
      ),
    );
  }
}
