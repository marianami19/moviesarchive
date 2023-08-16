import 'package:moviearchive/constants.dart';
import 'package:moviearchive/models/movie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import the dart:convert library for JSON decoding

class TopRated {
  static const _topRatedUrl =
      'https://api.themoviedb.org/3/movie/top_rated?api_key=${Constants.apiKey}';

  Future<List<Movies>> getTopRatedMovies({int page = 1}) async {
    final response = await http.get(Uri.parse('$_topRatedUrl&page=$page'));

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body)['results'] as List;
      return decodedData.map((movie) => Movies.fromJson(movie)).toList();
    } else {
      throw Exception('Oops');
    }
  }
}
