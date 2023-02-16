import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:frontend/exception.dart';
import 'package:meta/meta.dart';

import 'api.dart';

@immutable
abstract class _QueueEvent {}

@immutable
class _InitEvent implements _QueueEvent {
  const _InitEvent();
}

enum LoadingStage {
  queue,
  movies,
  error,
}

@immutable
class QueueState {
  final LoadingStage loadingStage;
  final List<Future<Movie>> movies;
  final String? queueLoadingError;

  const QueueState._({
    required this.loadingStage,
    required this.movies,
    this.queueLoadingError,
  });

  factory QueueState.initial() => const QueueState._(
        loadingStage: LoadingStage.queue,
        movies: [],
      );

  QueueState loadingMovies(List<Future<Movie>> movies) {
    return QueueState._(
      loadingStage: LoadingStage.movies,
      movies: movies,
    );
  }

  QueueState loadingError(String error) {
    return QueueState._(
      loadingStage: LoadingStage.error,
      movies: const [],
      queueLoadingError: error,
    );
  }
}

class QueueBloc extends Bloc<_QueueEvent, QueueState> {
  final TimApi _api;

  QueueBloc()
      : _api = TimApi.http(),
        super(QueueState.initial()) {
    on<_InitEvent>(_init);

    add(const _InitEvent());
  }

  Future<Movie> _loadMovie(MovieRef ref) async {
    final movie = await _api.getMovie(ref.id);
    if (movie == null) {
      throw MovieNotFoundException(ref.id);
    }
    return movie;
  }

  Future<void> _init(_InitEvent event, Emitter<QueueState> emit) async {
    final List<MovieRef> movieRefs;
    try {
      movieRefs = await _api.getQueue();
    } on ApiException catch (e) {
      emit(state.loadingError(e.toString()));
      return;
    }

    final List<Future<Movie>> movies =
        List.unmodifiable(movieRefs.map(_loadMovie));
    emit(state.loadingMovies(movies));
  }

  @override
  Future<void> close() {
    _api.close();
    return super.close();
  }
}
