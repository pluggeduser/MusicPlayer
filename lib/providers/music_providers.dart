import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/youtube_service.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';

// Services
final ytServiceProvider = Provider((ref) => YouTubeService());
final downloadServiceProvider = Provider((ref) {
  final ytService = ref.watch(ytServiceProvider);
  return DownloadService(ytService);
});
final playerServiceProvider = Provider((ref) => PlayerService());

// Search State
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final ytService = ref.watch(ytServiceProvider);
  return await ytService.search(query);
});

// Download State
final downloadProgressProvider = StateProvider.family<double, String>((ref, id) => 0.0);
final downloadedSongsProvider =
    StateNotifierProvider<DownloadedSongsNotifier, List<Song>>((ref) {
  return DownloadedSongsNotifier();
});

class DownloadedSongsNotifier extends StateNotifier<List<Song>> {
  DownloadedSongsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('downloaded_songs') ?? [];
    state = raw.map((e) => Song.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'downloaded_songs', state.map((s) => jsonEncode(s.toJson())).toList());
  }

  void addSong(Song song) {
    if (state.any((s) => s.id == song.id)) return;
    state = [...state, song];
    _save();
  }

  void removeSong(String id) {
    state = state.where((s) => s.id != id).toList();
    _save();
  }
}

// Playlist State
final playlistsProvider =
    StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  return PlaylistNotifier();
});

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  PlaylistNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('playlists') ?? [];
    state = raw.map((e) => Playlist.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'playlists', state.map((p) => jsonEncode(p.toJson())).toList());
  }

  void createPlaylist(String name) {
    final uuid = DateTime.now().millisecondsSinceEpoch.toString();
    final newPlaylist = Playlist(id: uuid, name: name, songIds: []);
    state = [...state, newPlaylist];
    _save();
  }

  void deletePlaylist(String id) {
    state = state.where((p) => p.id != id).toList();
    _save();
  }

  void addSongToPlaylist(String playlistId, String songId) {
    state = state.map((p) {
      if (p.id == playlistId && !p.songIds.contains(songId)) {
        return p.copyWith(songIds: [...p.songIds, songId]);
      }
      return p;
    }).toList();
    _save();
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    state = state.map((p) {
      if (p.id == playlistId) {
        return p.copyWith(songIds: p.songIds.where((id) => id != songId).toList());
      }
      return p;
    }).toList();
    _save();
  }
}

// Player State
final currentSongProvider = StateProvider<Song?>((ref) => null);
final shuffleModeProvider = StateProvider<bool>((ref) => false);
final queueProvider = StateProvider<List<Song>>((ref) => []);
final queueIndexProvider = StateProvider<int>((ref) => 0);

final playerProgressProvider = StreamProvider((ref) {
  final playerService = ref.watch(playerServiceProvider);
  return playerService.positionStream;
});
final playerStateProvider = StreamProvider((ref) {
  final playerService = ref.watch(playerServiceProvider);
  return playerService.playerStateStream;
});
final playerDurationProvider = StreamProvider<Duration?>((ref) {
  final playerService = ref.watch(playerServiceProvider);
  return playerService.durationStream;
});

// Navigation State
final navIndexProvider = StateProvider<int>((ref) => 0);

// Helper: play a queue of songs
void playQueue(WidgetRef ref, List<Song> songs, {int startIndex = 0, bool shuffle = false}) {
  final List<Song> orderedSongs = List.from(songs);
  if (shuffle) orderedSongs.shuffle();
  
  ref.read(queueProvider.notifier).state = orderedSongs;
  ref.read(queueIndexProvider.notifier).state = startIndex;
  ref.read(shuffleModeProvider.notifier).state = shuffle;

  final playerService = ref.read(playerServiceProvider);
  playerService.setQueue(orderedSongs, startIndex: startIndex);

  // play first song
  _playSongFromQueue(ref, orderedSongs[startIndex]);
}

void _playSongFromQueue(WidgetRef ref, Song song) {
  ref.read(currentSongProvider.notifier).state = song;
  final playerService = ref.read(playerServiceProvider);

  if (song.localPath != null) {
    playerService.playSong(song);
  } else {
    // fetch audio URL then play
    final ytService = ref.read(ytServiceProvider);
    ytService.getAudioStreamUrl(song.id).then((url) {
      final songWithUrl = song.copyWith(audioUrl: url);
      ref.read(currentSongProvider.notifier).state = songWithUrl;
      playerService.playSong(songWithUrl);
    }).catchError((e) {
      print('Failed to get audio URL: $e');
    });
  }
}
