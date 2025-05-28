import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:frontend/exception.dart';

part 'api.g.dart';

abstract class TimApi {
  Future<Movie?> getMovie(String id);

  Future<List<QueueItem>> getQueue();

  FutureOr<void> close();

  factory TimApi.http(Uri baseUrl) => _HttpTimApi(baseUrl);
}

typedef Json = Map<String, dynamic>;
typedef FromJson<T> = T Function(Json);

@immutable
@JsonSerializable(createToJson: false)
final class QueueItem {
  final String id;
  final String? userId;

  const QueueItem({required this.id, required this.userId});

  factory QueueItem.fromJson(Json json) => _$QueueItemFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
final class Queue {
  final List<QueueItem> queue;

  const Queue(this.queue);

  factory Queue.fromJson(Json json) => _$QueueFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.pascal)
enum MovieStatus { queued, watched, deleted }

@immutable
@JsonSerializable(createToJson: false)
final class Cover {
  final String url;
  final double ratio;

  const Cover({required this.url, required this.ratio});

  factory Cover.fromJson(Json json) => _$CoverFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
final class MovieMetadata {
  final String id;
  final String title;
  final int? year;
  final String? rating;
  final Cover? cover;
  final String infoPageUrl;

  const MovieMetadata({
    required this.id,
    required this.title,
    required this.year,
    required this.rating,
    required this.cover,
    required this.infoPageUrl,
  });

  factory MovieMetadata.fromJson(Json json) => _$MovieMetadataFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
final class Movie {
  final String id;
  final MovieStatus status;
  final MovieMetadata? imdb;
  final MovieMetadata? tmdb;

  MovieMetadata get metadata => (tmdb ?? imdb)!;

  const Movie({
    required this.id,
    required this.status,
    required this.imdb,
    required this.tmdb,
  });

  factory Movie.fromJson(Json json) => _$MovieFromJson(json);
}

extension on http.Response {
  T deserialize<T>(FromJson<T> fromJson) {
    return fromJson(jsonDecode(utf8.decode(bodyBytes)));
  }
}

class _HttpTimApi implements TimApi {
  final Uri _baseUri;
  final http.Client _client;

  _HttpTimApi(this._baseUri) : _client = RetryClient(http.Client());

  @override
  Future<Movie?> getMovie(String id) async {
    final client = _client;
    final url = _baseUri.resolve('/movie/$id');

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    switch (response.statusCode) {
      case 200:
        return response.deserialize(Movie.fromJson);
      case 404:
        return null;
      default:
        throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  Future<List<QueueItem>> getQueue() async {
    final client = _client;
    final url = _baseUri.resolve('/queue');

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    switch (response.statusCode) {
      case 200:
        return response.deserialize(Queue.fromJson).queue;
      default:
        throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  void close() {
    _client.close();
  }
}
