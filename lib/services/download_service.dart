import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
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

      // Use safe title for filename
      final safeTitle = song.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final tempWebmPath = p.join(downloadsDir.path, '${safeTitle}_temp.webm');
      final finalMp3Path = p.join(downloadsDir.path, '$safeTitle.mp3');

      // If MP3 already exists, return path immediately
      if (await File(finalMp3Path).exists()) {
        return finalMp3Path;
      }

      // Download as webm first
      onProgress?.call(0.1); // Start progress
      await _dio.download(
        audioUrl,
        tempWebmPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            // Download is 70% of total process
            onProgress?.call((received / total) * 0.7);
          } else {
            onProgress?.call(0.35);
          }
        },
        deleteOnError: true,
      );

      // Verify webm file was downloaded
      final webmFile = File(tempWebmPath);
      if (!await webmFile.exists() || await webmFile.length() < 1024) {
        print('Download error: webm file empty or missing');
        return null;
      }

      // Convert webm to mp3 using FFmpeg
      onProgress?.call(0.8); // Start conversion
      final session = await FFmpegKit.execute(
        '-i "$tempWebmPath" -q:a 0 -map a "$finalMp3Path"'
      );

      final returnCode = await session.getReturnCode();
      if (returnCode!.isValueSuccess()) {
        // Conversion successful, clean up temp file
        await webmFile.delete();
        
        // Verify MP3 file was created
        final mp3File = File(finalMp3Path);
        if (await mp3File.exists() && await mp3File.length() > 1024) {
          onProgress?.call(1.0); // Complete
          return finalMp3Path;
        } else {
          print('Conversion error: MP3 file empty or missing');
          await mp3File.delete();
          return null;
        }
      } else {
        print('FFmpeg conversion failed with return code: $returnCode');
        // Clean up files on failure
        await webmFile.delete();
        await File(finalMp3Path).delete();
        return null;
      }
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
