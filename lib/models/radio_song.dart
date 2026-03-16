class RadioSong {
  final String songId;
  final String songUrl;
  final String imageUrl;
  final String title;
  final String description;
  final String winningStyle;
  final List<String> styles;
  final double duration;

  RadioSong({
    required this.songId,
    required this.songUrl,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.winningStyle,
    required this.styles,
    required this.duration,
  });

  factory RadioSong.fromJson(Map<String, dynamic> json) {
    return RadioSong(
      songId: json['song_id'] ?? '',
      songUrl: json['song_url'] ?? '',
      imageUrl: json['image_url'] ?? '',
      title: json['title'] == "" ? "Suno AI Track" : json['title'],
      description: json['description'] ?? '',
      winningStyle: json['winning_style'] ?? 'Unknown',
      styles: List<String>.from(json['styles'] ?? []),
      duration: (json['duration'] as num).toDouble(),
    );
  }
}