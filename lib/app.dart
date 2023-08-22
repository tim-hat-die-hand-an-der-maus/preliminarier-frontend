import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'api.dart';
import 'color_schemes.dart';
import 'queue.dart';

class TimApp extends StatelessWidget {
  final Uri apiBaseUrl;

  const TimApp({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finger That Mouse',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      home: HomePage(apiBaseUrl: apiBaseUrl),
    );
  }
}

class HomePage extends StatelessWidget {
  final Uri apiBaseUrl;

  const HomePage({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QueueBloc(apiBaseUrl: apiBaseUrl),
      child: const Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            HeaderText(),
            Expanded(child: MovieList()),
          ],
        ),
      ),
    );
  }
}

class HeaderText extends StatelessWidget {
  const HeaderText({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        String text = 'Tim hat die Hand an der Maus';
        if (state.loadingStage == LoadingStage.movies) {
          text += ' (${state.movies.length} Filme)';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        );
      },
    );
  }
}

class MovieList extends StatelessWidget {
  const MovieList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueBloc, QueueState>(builder: (bloc, state) {
      switch (state.loadingStage) {
        case LoadingStage.queue:
          return const Center(child: CircularProgressIndicator());
        case LoadingStage.movies:
          final movies = state.movies;
          if (movies.isEmpty) {
            return const Center(
              child: Text('No movies in the queue'),
            );
          } else {
            return Scrollbar(
              child: GridView.builder(
                primary: true,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: MovieTile.width,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 20,
                  childAspectRatio: MovieTile.width / MovieTile.height,
                  mainAxisExtent: MovieTile.height,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return MovieTileContainer(movie);
                },
              ),
            );
          }
        case LoadingStage.error:
          return Center(
            child: Text('An error occurred: ${state.queueLoadingError}'),
          );
      }
    });
  }
}

class MovieTileContainer extends StatelessWidget {
  final Future<Movie> movie;

  const MovieTileContainer(this.movie, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: movie,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final movie = snapshot.requireData;
          final meta = movie.imdb;
          return MovieTile(
            title: meta.title,
            year: meta.year,
            rating: meta.rating,
            cover: meta.cover,
            url: meta.url,
          );
        } else if (snapshot.hasError) {
          return const MovieTile(
            title: 'Could not load this movie',
          );
        } else {
          return const MovieTile(title: 'Loading...');
        }
      },
    );
  }
}

class MovieTile extends StatelessWidget {
  static const double width = 270;
  static const double height = 400;

  final String title;
  final int? year;
  final String? rating;
  final Cover? cover;
  final String? url;

  const MovieTile({
    required this.title,
    this.year,
    this.rating,
    this.cover,
    this.url,
    super.key,
  });

  Future<void> _openUrl(String url) async {
    await launchUrlString(url);
  }

  @override
  Widget build(BuildContext context) {
    final rating = this.rating;
    final url = this.url;
    final year = this.year;

    final theme = Theme.of(context);

    return Card(
      child: Tooltip(
        message: title,
        child: InkWell(
          onTap: url == null ? null : () => _openUrl(url),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: CoverImage(
                    cover,
                    title: title,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  year == null ? '' : '$year',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  rating == null ? '' : '$rating/10',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoverImage extends StatelessWidget {
  final Cover? cover;
  final String title;

  const CoverImage(
    this.cover, {
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cover = this.cover;

    if (cover == null) {
      return _CoverImagePlaceholder(title);
    }

    return Image.network(
      cover.url,
      filterQuality: FilterQuality.high,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }

        if (frame == null) {
          return _CoverImagePlaceholder(title, key: const Key('placeholder'));
        }

        return child;
      },
    );
  }
}

class _CoverImagePlaceholder extends StatelessWidget {
  final String title;

  const _CoverImagePlaceholder(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
