class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;
  final String? audioUrl;
  final String? localPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.audioUrl,
    this.localPath,
  });

  Song copyWith({
    String? audioUrl,
    String? localPath,
  }) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
    );
  }

  factory Song.fromVideo(dynamic video) {
    return Song(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
      duration: video.duration ?? Duration.zero,
    );
  }
}
