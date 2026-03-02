import 'dart:io';
import 'package:dio/dio.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import 'youtube_service.dart';

class DownloadService {
  final Dio _dio = Dio();
  final YouTubeService _ytService;

  DownloadService(this._ytService);

  Future<String?> downloadSong(Song song, {Function(double)? onProgress}) async {
    try {
      final audioUrl = await _ytService.getAudioStreamUrl(song.id);
      final directory = await getApplicationDocumentsAlignment();
      final downloadsDir = Directory(p.join(directory.path, 'downloads'));
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

  Future<void> _tagFile(String filePath, Song song) async {
    try {
      await MetadataGod.writeMetadata(
        file: filePath,
        metadata: Metadata(
          title: song.title,
          artist: song.artist,
          album: 'YouTube Download',
          genre: 'Music',
          year: DateTime.now().year,
        ),
      );
    } catch (e) {
      print('Tagging error: $e');
    }
  }

  Future<Directory> getApplicationDocumentsAlignment() async {
    return await getApplicationDocumentsDirectory();
  }
}
