import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final downloadedSongsProvider = StateProvider<List<Song>>((ref) => []);

// Player State
final currentSongProvider = StateProvider<Song?>((ref) => null);
final playerProgressProvider = StreamProvider((ref) {
  final playerService = ref.watch(playerServiceProvider);
  return playerService.positionStream;
});
final playerStateProvider = StreamProvider((ref) {
  final playerService = ref.watch(playerServiceProvider);
  return playerService.playerStateStream;
});
