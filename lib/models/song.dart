class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;
  final String? audioUrl;
  final String? localPath;
  final String? albumName;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
    this.audioUrl,
    this.localPath,
    this.albumName,
  });

  bool get isDownloaded => localPath != null;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    Duration? duration,
    String? audioUrl,
    String? localPath,
    String? albumName,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
      albumName: albumName ?? this.albumName,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration.inSeconds,
      'audioUrl': audioUrl,
      'localPath': localPath,
      'albumName': albumName,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: Duration(seconds: json['duration'] ?? 0),
      audioUrl: json['audioUrl'],
      localPath: json['localPath'],
      albumName: json['albumName'],
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final List<String> songIds; // IDs referencing downloaded songs

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  Playlist copyWith({
    String? name,
    List<String>? songIds,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'],
    name: json['name'],
    songIds: List<String>.from(json['songIds'] ?? []),
  );
}
