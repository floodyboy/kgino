import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
// import 'package:dio_http_cache_lts/dio_http_cache_lts.dart';
import 'package:flutter/foundation.dart';
import 'package:kgino/models/ockg/ockg_bestsellers_category.dart';

import '../models/episode_item.dart';
import '../models/kgino_item.dart';
import '../models/ockg/ockg_catalog.dart';
import '../models/ockg/ockg_comment.dart';
import '../models/ockg/ockg_movie.dart';
import '../models/season_item.dart';
import 'logs_interceptor.dart';

class OckgApiProvider {

  /// cinema online
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://oc.kg/api.php?format=json',
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  OckgApiProvider() {
    /// добавляем перехватчик, для логов запросов
    _dio.interceptors.add(LogsInterceptor());
  }


  /// список бестселлеров по категориям
  Future<List<OckgBestsellersCategory>> getBestsellers() async {

    final formData = FormData.fromMap({
      'action[0]': 'Video.getBestsellers',
    });

    try {
    
      final response = await _dio.post('', data: formData);

      final jsonResponse = json.decode(response.data);
      final bestsellers = jsonResponse['json'][0]['response']['bestsellers'];

      return bestsellers.map<OckgBestsellersCategory>((item) {
        return OckgBestsellersCategory.fromJson(item);
      }).toList();
      
    } on SocketException catch (_) {

      debugPrint('no internet connection');
      
      return [];
    
    } catch (exception, stacktrace) {
      
      debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
      return [];
    }
    
  }

  
  // /// список популярных фильмов
  // Future<List<OckgMovie>> getPopMovies() async {

  //   final formData = FormData.fromMap({
  //     'action[0]': 'Video.getPopMovies',
  //   });

  //   try {
    
  //     final response = await _dio.post('', data: formData);

  //     final jsonResponse = json.decode(response.data);
  //     final movies = jsonResponse['json'][0]['response']['movies'];

  //     return movies.map<OckgMovie>((item) {
  //       return OckgMovie.fromJson(item);
  //     }).toList();
      
  //   } on SocketException catch (_) {

  //     debugPrint('no internet connection');
      
  //     return [];
    
  //   } catch (exception, stacktrace) {
      
  //     debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
  //     return [];
  //   }
    
  // }


  /// поиск фильмов
  Future<List<KginoItem>> searchMovies(String searchQuery) async {
    // final runes = searchQuery.runes.map((r) {
    //   return '%u${r.toRadixString(16).padLeft(4, '0')}';
    // }).toList();

    // final formData = FormData.fromMap({
    //   'action[0]': 'Video.search',
    //   'query[0]': searchQuery,
    // });

    try {

      // final response = await _dio.post('', data: formData);
    
      final response = await _dio.get('https://oc.kg/suggestion.php',
        queryParameters: {
          'q': searchQuery,
        }
      );

      final jsonResponse = json.decode(response.data);
      final moviesJson = jsonResponse['json'][0]['response']['movies'];

      final Iterable<OckgMovie> movies = moviesJson.map<OckgMovie>((item) {
        return OckgMovie.fromJson(item);
      });

      final List<KginoItem> a = movies.map<KginoItem>((movie) {
        return KginoItem(
          type: KginoItemType.movie,
          provider: KginoProvider.ockg,
          id: '${movie.movieId}',
          name: movie.name,
          posterUrl: movie.posterUrl,
          updatedAt: DateTime.now(),
        );
      }).toList();

      return a;
      
    } on SocketException catch (_) {

      debugPrint('no internet connection');
      
      return [];
    
    } catch (exception, stacktrace) {
      
      debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
      return [];
    }

    
  }


  /// список фильмов по id жанра
  Future<List<OckgMovie>> getMoviesByGenreId(int genreId) async {

    final formData = FormData.fromMap({
      'action[0]': 'Video.getCatalog',
      'genre[0]': genreId,
      'offset[0]': 0,
      'size[0]': 20,
    });

    try {
    
      final response = await _dio.post('', data: formData);

      final jsonResponse = json.decode(response.data);
      final movies = jsonResponse['json'][0]['response']['movies'];

      return movies.map<OckgMovie>((item) {
        return OckgMovie.fromJson(item);
      }).toList();
      
    } on SocketException catch (_) {

      debugPrint('no internet connection');
      
      return [];
    
    } catch (exception, stacktrace) {
      
      debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
      return [];
    }

  }


  /// список фильмов из каталога
  Future<OckgCatalog> getCatalog({
    String genreId = '',
    String selectionId = '',
    required int offset,
    int pageSize = 15,
  }) async {

    final formData = FormData.fromMap({
      'action[0]': 'Video.getCatalog',
      if (genreId.isNotEmpty) 'genre[0]': genreId,
      if (selectionId.isNotEmpty) 'selection[0]': selectionId,
      'offset[0]': offset,
      'size[0]': pageSize,
    });

    debugPrint(formData.fields.toString());

    try {
    
      final response = await _dio.post('', data: formData);

      final jsonResponse = json.decode(response.data);
      debugPrint('getCatalog: $jsonResponse');
      final catalog = jsonResponse['json'][0]['response'];

      return OckgCatalog.fromJson(catalog);
      
    } on SocketException catch (_) {

      debugPrint('no internet connection');
      
      return const OckgCatalog();
    
    } catch (exception, stacktrace) {
      
      debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
      return const OckgCatalog();
    }

  }

  /// список подборок
  Future<List<KginoItem>> getSelections() async {

    final items = <KginoItem>[];

    try {

      /// <div class=\"item\" mid=\"2\" title=\" TOP-20 лучших триллеров \"> <div class=\"cover\"> <a href=\"?s=2&v=s#/catalog/selection/2/page/1\"> <img src=\"/media/images/topImages/thriller.jpg\" class=\"cover\"> </a> </div> <a class=\"title\" href=\"?s=2&v=s#/catalog/selection/2/page/1\"> TOP-20 лучших триллеров </a> <a class=\"subtitle\" href=\"?s=2&v=s#/catalog/selection/2/page/1\"> По версии нашего каталога </a> </div>
      /// <div class=\\\"item\\\" mid=\\\"(\d+?)\\\" title=\\\"(.+?)\\\"> <div class=\\\"cover\\\"> <a href=\\\"(.+?)\\\"> <img src=\\\"(.+?)\\\" class=\\\"cover\\\"> <\/a> <\/div> <a class=\\\"title\\\" href=\\\"(.+?)\\\">(.+?)<\/a> <a class=\\\"subtitle\\\" href=\\\"(.+?)\\\"> По версии нашего каталога <\/a> <\/div>
      final response = await _dio.get('https://oc.kg/#/selections');

      final regExp = RegExp(r'<div class=\\\"item\\\" mid=\\\"(\d+?)\\\" title=\\\"(.+?)\\\"> <div class=\\\"cover\\\"> <a href=\\\"(.+?)\\\"> <img src=\\\"(.+?)\\\" class=\\\"cover\\\"> <\/a> <\/div> <a class=\\\"title\\\" href=\\\"(.+?)\\\">(.+?)<\/a> <a class=\\\"subtitle\\\" href=\\\"(.+?)\\\"> По версии нашего каталога <\/a> <\/div>');
            
      if (regExp.hasMatch(response.data)) {
        final matches = regExp.allMatches(response.data);
        for (final match in matches) {
          final id = match.group(1) ?? '';
          final name = match.group(2)?.trim() ?? '';
          final posterUrl = 'https://oc.kg${match.group(4)}';
          
          items.add(
            KginoItem(
              type: KginoItemType.folder,
              provider: KginoProvider.ockg,
              id: id,
              name: name,
              posterUrl: posterUrl,
              updatedAt: DateTime.now(),
            )
          );
        }

      }

      /// удаляем дубликаты
      return items.toSet().toList();
      
    } on SocketException catch (_) {

      debugPrint('no internet connection');
      
      return [];
    
    } catch (exception, stacktrace) {
      
      debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
      return [];
    }

  }

  
  /// информация о фильме
  Future<KginoItem?> getMovie(String movieId) async {

    final formData = FormData.fromMap({
      'action[0]': 'Video.getMovie',
      'movie_id[0]': movieId,
    });

    try {
    
      final response = await _dio.post('', data: formData);

      final jsonResponse = json.decode(response.data);
      final movieJson = jsonResponse['json'][0]['response']['movie'];

      final movie = OckgMovie.fromJson(movieJson);

      final seasons = [
        SeasonItem(
          name: '',
          episodes: movie.files.mapIndexed((index, file) {
            return EpisodeItem(
              id: '${file.fileId}',
              name: file.name,
              videoFileUrl: file.path.replaceFirst('/home/video/', 'https://p1.oc.kg:8082/'),
              seasonNumber: 1,
              episodeNumber: index + 1,
              duration: file.metainfo.playtimeSeconds,
              updatedAt: DateTime.now(),
            );
          }).toList(),
        ),
      ];

      final hasSixAudioChannels = movie.files.where((file) {
        final audios = file.metainfo.audio;
        return audios.where((audio) => audio.info.contains('6ch')).isNotEmpty;
      }).isNotEmpty;

      return KginoItem(
        type: KginoItemType.movie,
        provider: KginoProvider.ockg,
        id: '${movie.movieId}',
        name: movie.name,
        posterUrl: movie.posterUrl,
        originalName: movie.internationalName,
        description: movie.description,
        year: movie.year,
        genres: movie.genres,
        countries: movie.countries,
        
        imdbRating: movie.ratingImdbValue,
        kinopoiskRating: movie.ratingKinopoiskValue,

        //hasSixAudioChannels: hasSixAudioChannels,

        seasons: seasons,
        updatedAt: DateTime.now(),
      );
      
    } on SocketException catch (_) {

      debugPrint('no internet connection');
      
      return null;
    
    } catch (exception, stacktrace) {
      
      debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
      return null;
    }

  }


  /// комментарии к фильму
  Future<List<OckgComment>> getComments(int movieId) async {

    final formData = FormData.fromMap({
      'action[0]': 'Video.getComments',
      'movie_id[0]': movieId,
    });

    try {
    
      final response = await _dio.post('', data: formData);

      final jsonResponse = json.decode(response.data);
      final movies = jsonResponse['json'][0]['response']['comments'];

      return movies.map<OckgComment>((item) {
        return OckgComment.fromJson(item);
      }).toList();
      
    } on SocketException catch (_) {

      debugPrint('no internet connection');
      
      return [];
    
    } catch (exception, stacktrace) {
      
      debugPrint('Exception: $exception, stacktrace: $stacktrace');
      
      return [];
    }

  }

}
