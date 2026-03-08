class OverseerrSearchResult {
  final int id;
  final String mediaType; // movie, tv
  final String title;
  final String overview;
  final String posterPath;
  final String releaseDate;
  final double voteAverage;

  OverseerrSearchResult({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  factory OverseerrSearchResult.fromJson(Map<String, dynamic> json) {
    return OverseerrSearchResult(
      id: json['id'] ?? 0,
      mediaType: json['mediaType'] ?? '',
      title: json['title'] ?? json['name'] ?? 'Unknown',
      overview: json['overview'] ?? '',
      posterPath: json['posterPath'] ?? '',
      releaseDate: json['releaseDate'] ?? json['firstAirDate'] ?? '',
      voteAverage: (json['voteAverage'] ?? 0).toDouble(),
    );
  }
}
