import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/queue.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'api.dart';
import 'color_schemes.dart';

void main() {
  runApp(const TimApp());
}

class TimApp extends StatelessWidget {
  const TimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finger That Mouse',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QueueBloc(),
      child: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: const [
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
            return SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  for (final movie in movies) MovieTileContainer(movie),
                ],
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
            isFailed: true,
          );
        } else {
          return const MovieTile(title: 'Loading...');
        }
      },
    );
  }
}

class MovieTile extends StatelessWidget {
  final String title;
  final int? year;
  final String? rating;
  final Cover? cover;
  final String? url;
  final bool isFailed;

  const MovieTile({
    required this.title,
    this.isFailed = false,
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
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 10,
      ),
      child: InkWell(
        onTap: url == null ? null : () => _openUrl(url),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoverImage(
                cover,
                loadFailurePlaceholder: isFailed,
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                year == null ? '' : '$year',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                rating == null ? '' : '$rating/10',
                style: Theme.of(context).textTheme.titleMedium,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CoverImage extends StatelessWidget {
  static const double height = 400;
  static const double width = 250;
  static const enableFailurePhoto = false;

  final Cover? cover;
  final bool loadFailurePlaceholder;

  const CoverImage(
    this.cover, {
    required this.loadFailurePlaceholder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cover = this.cover;
    if (cover == null) {
      if (enableFailurePhoto && loadFailurePlaceholder) {
        return Image.network(
          'https://picsum.photos/seed/$hashCode/$width/$height?blur',
        );
      } else {
        return Container(
          width: width,
          height: height,
          color: Colors.black12,
        );
      }
    }
    return Image.network(
      cover.url,
      height: height,
      width: width,
      filterQuality: FilterQuality.medium,
    );
  }
}
