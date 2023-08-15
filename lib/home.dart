import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moviearchive/api/toprated.dart';
import 'package:moviearchive/models/movie.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  late Future<List<Movies>> topRatedMovies;
  List<Movies> favoriteMovies = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    topRatedMovies = TopRated().getTopRatedMovies();
    loadFavoriteMoviesFromPrefs(); // Load favorite movies from SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Archive'),
      ),
      body: PageView(
        children: [
          buildTopRatedMoviesPage(),
          buildFavoriteMoviesPage(),
        ],
        controller: _pageController,
        onPageChanged: _onPageChanged,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        onTap: _onTabTapped,
      ),
    );
  }

  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Method to build the top-rated movies page
  Widget buildTopRatedMoviesPage() {
    return FutureBuilder<List<Movies>>(
      future: topRatedMovies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading movies'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No movies available'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Movies movie = snapshot.data![index];
              return ListTile(
                title: Text(movie.title),
                subtitle: Text(movie.releaseDate),
                leading: Image.network(
                  'https://image.tmdb.org/t/p/w200${movie.posterPath}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.favorite),
                  color:
                      favoriteMovies.contains(movie) ? Colors.red : Colors.grey,
                  onPressed: () {
                    toggleFavorite(movie);
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  // Method to toggle the favorite status of a movie
  void toggleFavorite(Movies movie) {
    setState(() {
      if (favoriteMovies.contains(movie)) {
        favoriteMovies.remove(movie);
      } else {
        favoriteMovies.add(movie);
      }
      saveFavoriteMoviesToPrefs(); // Save favorite movies to SharedPreferences
    });
  }

  // Method to load favorite movies from SharedPreferences
// Method to load favorite movies from SharedPreferences
  void loadFavoriteMoviesFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteMovieIds = prefs.getStringList('favoriteMovies');

    // Print the favorite movie IDs using debugPrint
    debugPrint('Favorite Movie IDs: $favoriteMovieIds');

    if (favoriteMovieIds != null && favoriteMovieIds.isNotEmpty) {
      try {
        favoriteMovies = favoriteMovieIds
            .map((movieId) => favoriteMovies
                .firstWhere((movie) => movie.id.toString() == movieId))
            .toList();
      } catch (e) {
        debugPrint('$e');
      }
    }
  }

  // Method to save favorite movies to SharedPreferences
  void saveFavoriteMoviesToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteMovieIds =
        favoriteMovies.map((movie) => movie.id.toString()).toList();
    prefs.setStringList('favoriteMovies', favoriteMovieIds);
  }

  // Method to build the favorite movies page
  Widget buildFavoriteMoviesPage() {
    if (favoriteMovies.isEmpty) {
      return Center(child: Text('No favorite movies yet'));
    }

    return ListView.builder(
      itemCount: favoriteMovies.length,
      itemBuilder: (context, index) {
        Movies movie = favoriteMovies[index];
        return ListTile(
          title: Text(movie.title),
          subtitle: Text(movie.releaseDate),
          leading: Image.network(
            'https://image.tmdb.org/t/p/w200${movie.posterPath}',
          ),
          trailing: IconButton(
            icon: Icon(Icons.favorite),
            color: Colors.red,
            onPressed: () {
              toggleFavorite(movie);
            },
          ),
        );
      },
    );
  }
}
