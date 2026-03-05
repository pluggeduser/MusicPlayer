import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class PlayerService {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _shuffleMode = false;
  List<int> _shuffledIndices = [];

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get shuffleMode => _shuffleMode;

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _queue = List.from(songs);
    _currentIndex = startIndex;
    if (_shuffleMode) {
      _buildShuffledIndices();
    }
  }

  void _buildShuffledIndices() {
    _shuffledIndices = List.generate(_queue.length, (i) => i)..shuffle();
    // Make current index first in shuffle
    _shuffledIndices.remove(_currentIndex);
    _shuffledIndices.insert(0, _currentIndex);
  }

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
    if (_shuffleMode) {
      _buildShuffledIndices();
    }
  }

  int get _effectiveIndex =>
      _shuffleMode && _shuffledIndices.isNotEmpty ? _shuffledIndices[_currentIndex] : _currentIndex;

  Song? get currentSong =>
      _queue.isEmpty ? null : _queue[_effectiveIndex];

  Future<void> playSong(Song song) async {
    try {
      if (song.localPath != null) {
        await _player.setFilePath(song.localPath!);
      } else if (song.audioUrl != null) {
        await _player.setUrl(song.audioUrl!);
      } else {
        // can't play without a URL — caller should fetch URL first
        return;
      }
      await _player.play();
    } catch (e) {
      print('Playback error: $e');
    }
  }

  Future<void> playFromQueue(int index) async {
    if (_queue.isEmpty) return;
    _currentIndex = index;
    await playSong(_queue[_effectiveIndex]);
  }

  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    int nextIndex;
    if (_shuffleMode && _shuffledIndices.isNotEmpty) {
      int pos = _shuffledIndices.indexOf(_effectiveIndex);
      nextIndex = (pos + 1) % _shuffledIndices.length;
      _currentIndex = _shuffledIndices[nextIndex];
    } else {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    }
    await playSong(_queue[_effectiveIndex]);
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    final pos = _player.position;
    // If more than 3s in, restart; else go to previous
    if (pos.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_shuffleMode && _shuffledIndices.isNotEmpty) {
      int curPos = _shuffledIndices.indexOf(_effectiveIndex);
      int prevPos = (curPos - 1 + _shuffledIndices.length) % _shuffledIndices.length;
      _currentIndex = _shuffledIndices[prevPos];
    } else {
      _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    }
    await playSong(_queue[_effectiveIndex]);
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}
