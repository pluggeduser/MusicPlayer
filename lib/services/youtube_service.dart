import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

class YouTubeService {
  final _yt = YoutubeExplode();

  Future<List<Song>> search(String query) async {
    final searchList = await _yt.search.search(query);
    return searchList.map((video) => Song.fromVideo(video)).toList();
  }

  Future<String> getAudioStreamUrl(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream.url.toString();
  }

  void close() {
    _yt.close();
  }
}
