import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

class YouTubeService {
  final _yt = YoutubeExplode();

  Future<List<Song>> search(String query) async {
    if (query.contains('youtube.com/playlist?list=') || query.contains('youtu.be/playlist?list=')) {
      final playlistId = query.split('list=').last.split('&').first;
      return await getPlaylistSongs(playlistId);
    }
    final searchList = await _yt.search.search(query);
    return searchList.map((video) => Song.fromVideo(video)).toList();
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final playlist = await _yt.playlists.get(playlistId);
    final videos = await _yt.playlists.getVideos(playlistId).toList();
    return videos
        .map((video) => Song.fromVideo(video).copyWith(albumName: playlist.title))
        .toList();
  }

  Future<String> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      final url = audioStream.url.toString();
      
      if (url.isEmpty) {
        throw Exception('No audio stream available for video: $videoId');
      }
      
      return url;
    } on VideoUnavailableException {
      throw Exception('Video $videoId is not available');
    } catch (e) {
      throw Exception('Failed to get audio stream for video $videoId: $e');
    }
  }

  void close() {
    _yt.close();
  }
}
