import 'package:flutter/material.dart';
import 'package:moviearchive/constants.dart';
import 'package:moviearchive/lazy_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moviearchive/api/toprated.dart';
import 'package:moviearchive/models/movie.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum MovieSortOption {
  Year,
  Popularity,
  IMDBRating,
}

class _HomePageState extends State<HomeScreen> {
  List<Movies> topRatedMovies = [];
  List<Movies> favoriteMovies = [];
  late PageController _pageController;
  int _currentIndex = 0;
  int _currentPage = 1;
  int _pageSize = 5;
  TextEditingController _searchController = TextEditingController();

  MovieSortOption _currentSortOption = MovieSortOption.Year;

  List<Movies> sortMovies(List<Movies> movies) {
    switch (_currentSortOption) {
      case MovieSortOption.Year:
        return [...movies]
          ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
      case MovieSortOption.Popularity:
        return [...movies]
          ..sort((a, b) => b.popularity.compareTo(a.popularity));
      case MovieSortOption.IMDBRating:
        return [...movies]
          ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      default:
        return movies;
    }
  }

  List<Movies> searchMovies(String query) {
    query = query.toLowerCase();
    return topRatedMovies
        .where((movie) => movie.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    loadTopRatedMovies();
    loadFavoriteMoviesFromPrefs();
  }

  Future<void> loadTopRatedMovies() async {
    List<Movies> newMovies =
        await TopRated().getTopRatedMovies(page: _currentPage);
    setState(() {
      topRatedMovies.addAll(newMovies);
    });
  }

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

  Widget buildTopRatedMoviesPage() {
    List<Movies> filteredMovies = _searchController.text.isNotEmpty
        ? searchMovies(_searchController.text)
        : topRatedMovies;

    // Apply sorting based on the selected sort option
    switch (_currentSortOption) {
      case MovieSortOption.Year:
        filteredMovies.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
        break;
      case MovieSortOption.Popularity:
        filteredMovies.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case MovieSortOption.IMDBRating:
        filteredMovies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        break;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (query) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search movies by name',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Sort by: '),
              DropdownButton<MovieSortOption>(
                value: _currentSortOption,
                onChanged: (option) {
                  setState(() {
                    _currentSortOption = option!;
                  });
                },
                items: MovieSortOption.values
                    .map<DropdownMenuItem<MovieSortOption>>(
                  (MovieSortOption option) {
                    return DropdownMenuItem<MovieSortOption>(
                      value: option,
                      child: Text(option.toString().split('.').last),
                    );
                  },
                ).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: LazyLoadListView(
            items: filteredMovies,
            itemBuilder: (context, index, movie) {
              return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 150,
                        child: Image.network(
                          '${Constants.imgPath}${movie.posterPath}',
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(movie.title,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                                'Year: ${extractYearFromDate(movie.releaseDate)}'),
                            Text('IMDB Rating: ${movie.voteAverage}'),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.favorite),
                        color: favoriteMovies.contains(movie)
                            ? Colors.red
                            : Colors.grey,
                        onPressed: () {
                          toggleFavorite(movie);
                        },
                      ),
                    ],
                  ));
            },
            onLoadMore: _loadMoreTopRatedMovies,
          ),
        ),
      ],
    );
  }

// Helper function to extract year from a date string (YYYY-MM-DD)
  String extractYearFromDate(String dateString) {
    if (dateString.length >= 4) {
      return dateString.substring(0, 4);
    } else {
      return '';
    }
  }

  Future<void> _loadMoreTopRatedMovies() async {
    List<Movies> moreMovies =
        await TopRated().getTopRatedMovies(page: _currentPage + 1);
    setState(() {
      topRatedMovies.addAll(moreMovies);
      _currentPage++;
    });
  }

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
  void loadFavoriteMoviesFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteMovieIds = prefs.getStringList('favoriteMovies');

    if (favoriteMovieIds != null && favoriteMovieIds.isNotEmpty) {
      try {
        favoriteMovies = favoriteMovieIds
            .map((movieId) => favoriteMovies
                .firstWhere((movie) => movie.id.toString() == movieId))
            .toList();
      } catch (e) {
        // debugPrint('$e');
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
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 120,
                child: Image.network(
                  '${Constants.imgPath}${movie.posterPath}',
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Year: ${extractYearFromDate(movie.releaseDate)}'),
                    Text('IMDB Rating: ${movie.voteAverage}'),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite),
                color:
                    favoriteMovies.contains(movie) ? Colors.red : Colors.grey,
                onPressed: () {
                  toggleFavorite(movie);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
