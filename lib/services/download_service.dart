import 'dart:io';
import 'package:dio/dio.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import 'youtube_service.dart';

class DownloadService {
  final Dio _dio = Dio();
  final YouTubeService _ytService;

  DownloadService(this._ytService);

  Future<String?> downloadSong(Song song, {Function(double)? onProgress, String? albumName}) async {
    try {
      final audioUrl = await _ytService.getAudioStreamUrl(song.id);
      final directory = await getApplicationDocumentsAlignment();
      
      String subPath = 'downloads';
      if (albumName != null || song.albumName != null) {
        subPath = p.join('downloads', albumName ?? song.albumName!);
      }
      
      final downloadsDir = Directory(p.join(directory.path, subPath));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = '${song.id}.mp3';
      final filePath = p.join(downloadsDir.path, fileName);

      await _dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received / total);
          }
        },
      );

      // Tag the file with metadata
      await _tagFile(filePath, song);

      return filePath;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  Future<void> downloadAlbum(List<Song> songs, {Function(int, int)? onOverallProgress}) async {
    for (int i = 0; i < songs.length; i++) {
      onOverallProgress?.call(i, songs.length);
      try {
        await downloadSong(songs[i]);
      } catch (e) {
        print('Error downloading song ${songs[i].title}: $e');
      }
    }
    onOverallProgress?.call(songs.length, songs.length);
  }

  Future<void> _tagFile(String filePath, Song song) async {
    try {
      final tag = Tag(
        title: song.title,
        trackArtist: song.artist,
        album: song.albumName ?? 'YouTube Download',
        genre: 'Music',
        year: DateTime.now().year,
        pictures: [],
      );
      await AudioTags.write(filePath, tag);
    } catch (e) {
      print('Tagging error: $e');
    }
  }

  Future<Directory> getApplicationDocumentsAlignment() async {
    return await getApplicationDocumentsDirectory();
  }
}
