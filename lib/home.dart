import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moviearchive/api/toprated.dart';
import 'package:moviearchive/models/movie.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  List<Movies> topRatedMovies = [];
  List<Movies> favoriteMovies = [];
  late PageController _pageController;
  int _currentIndex = 0;
  int _currentPage = 1;
  int _pageSize = 5;

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
    return LazyLoadListView(
      items: topRatedMovies,
      itemBuilder: (context, index, movie) {
        return ListTile(
          title: Text(movie.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Year: ${extractYearFromDate(movie.releaseDate)}'),
              Text('IMDB Rating: ${movie.voteAverage}'),
              Text(movie.releaseDate),
            ],
          ),
          leading: Image.network(
            'https://image.tmdb.org/t/p/w200${movie.posterPath}',
          ),
          trailing: IconButton(
            icon: Icon(Icons.favorite),
            color: favoriteMovies.contains(movie) ? Colors.red : Colors.grey,
            onPressed: () {
              toggleFavorite(movie);
            },
          ),
        );
      },
      onLoadMore: _loadMoreTopRatedMovies,
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

class LazyLoadListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, int, T) itemBuilder;
  final VoidCallback onLoadMore;

  LazyLoadListView({
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
  });

  @override
  _LazyLoadListViewState<T> createState() => _LazyLoadListViewState<T>();
}

class _LazyLoadListViewState<T> extends State<LazyLoadListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
        });
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.items.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return SizedBox(
            height: 120, // Adjust the height as needed
            child: widget.itemBuilder(context, index, widget.items[index]),
          );
        } else {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
