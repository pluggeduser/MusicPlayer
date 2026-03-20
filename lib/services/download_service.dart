import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import 'youtube_service.dart';

class DownloadService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
    // YouTube requires these headers for direct stream download
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': '*/*',
      'Accept-Encoding': 'identity',
      'Connection': 'keep-alive',
    },
  ));
  final YouTubeService _ytService;

  DownloadService(this._ytService);

  Future<String?> downloadSong(
    Song song, {
    Function(double)? onProgress,
    String? albumName,
  }) async {
    try {
      // Fetch a fresh stream URL every time
      final audioUrl = await _ytService.getAudioStreamUrl(song.id);

      // Use app-private documents directory — no storage permission needed
      final directory = await getApplicationDocumentsDirectory();

      String subPath = 'downloads';
      final effectiveAlbum = albumName ?? song.albumName;
      if (effectiveAlbum != null && effectiveAlbum.isNotEmpty) {
        // Sanitize folder name
        final safe = effectiveAlbum.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        subPath = p.join('downloads', safe);
      }

      final downloadsDir = Directory(p.join(directory.path, subPath));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Use safe title for filename and save as M4A (compatible with just_audio)
      final safeTitle = song.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = p.join(downloadsDir.path, '$safeTitle.m4a');

      // If already downloaded, return path immediately
      if (await File(filePath).exists()) {
        return filePath;
      }

      await _dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total);
          } else {
            // Unknown total — show indeterminate progress at 50%
            onProgress?.call(0.5);
          }
        },
        deleteOnError: true,
      );

      // Verify file was actually written and has content
      final file = File(filePath);
      if (!await file.exists() || await file.length() < 1024) {
        print('Download error: file empty or missing');
        return null;
      }

      return filePath;
    } on DioException catch (e) {
      print('Download Dio error: ${e.type} — ${e.message}');
      print('Response: ${e.response?.statusCode}');
      return null;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  Future<void> downloadAlbum(
    List<Song> songs, {
    Function(int, int)? onOverallProgress,
  }) async {
    for (int i = 0; i < songs.length; i++) {
      onOverallProgress?.call(i, songs.length);
      try {
        await downloadSong(songs[i]);
      } catch (e) {
        print('Error downloading ${songs[i].title}: $e');
      }
    }
    onOverallProgress?.call(songs.length, songs.length);
  }
}
