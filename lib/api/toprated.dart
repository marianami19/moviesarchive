import 'package:moviearchive/constants.dart';
import 'package:moviearchive/models/movie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import the dart:convert library for JSON decoding

class TopRated {
  static const _topRatedUrl =
      'https://api.themoviedb.org/3/movie/top_rated?api_key=${Constants.apiKey}';
  // Define the URL for fetching the top-rated movies.

  Future<List<Movies>> getTopRatedMovies() async {
    // This function asynchronously retrieves a list of top-rated movies.

    final response = await http.get(Uri.parse(_topRatedUrl));
    // Send a GET request to the top-rated movies API using the http package.
    // Uri.parse(_topRatedUrl) converts the URL string to a Uri object.

    if (response.statusCode == 200) {
      // If the response status code is 200 (OK), the request was successful.

      final decodedData = json.decode(response.body)['results'] as List;
      // Decode the JSON response body using the `json` library.
      // The response body is a JSON object with a 'results' key containing a list of movie data.

      return decodedData.map((movie) => Movies.fromJson(movie)).toList();
      // Use the `map` function to convert each movie JSON object into a Movies object.
      // The `Movies.fromJson(movie)` call constructs a Movies object from the decoded JSON.
      // `toList()` converts the resulting Iterable into a List.
    } else {
      throw Exception('Oops');
      // If the response status code is not 200, throw an exception with the message 'Oops'.
    }
  }
}
