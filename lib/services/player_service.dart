import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class PlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> playSong(Song song) async {
    try {
      if (song.localPath != null) {
        await _player.setFilePath(song.localPath!);
      } else if (song.audioUrl != null) {
        await _player.setUrl(song.audioUrl!);
      }
      await _player.play();
    } catch (e) {
      print('Playback error: $e');
    }
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}
