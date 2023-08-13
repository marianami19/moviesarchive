class Movies {
  String title;
  String backdropPath;
  int id;
  String originalLanguage;
  String originalTitle;
  String overview;
  String popularity;
  String posterPath;
  String releaseDate;
  double voteAverage;

  Movies({
    required this.title,
    required this.backdropPath,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  factory Movies.fromJson(Map<String, dynamic> json) {
    return Movies(
      title: json['title'],
      backdropPath: json['backdrop_path'],
      id: json['id'],
      originalLanguage: json['original_language'],
      originalTitle: json['original_title'],
      overview: json['overview'],
      popularity: json['popularity'].toString(), // Convert popularity to String
      posterPath: json['poster_path'],
      releaseDate: json['release_date'],
      voteAverage:
          json['vote_average'].toDouble(), // Convert vote_average to Double
    );
  }
}
