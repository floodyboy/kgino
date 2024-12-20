import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/api_request.dart';
import '../models/filmix/filmix_item.dart';
import '../models/filmix/filmix_profile.dart';
import '../models/filmix/filmix_token.dart';
import '../models/media_item.dart';
import '../providers/device_provider.dart';
import '../providers/providers.dart';

part 'filmix_api_provider.g.dart';

@Riverpod(keepAlive: true)
FilmixApi filmixApi(FilmixApiRef ref) => FilmixApi(ref);

class FilmixApi {
  final FilmixApiRef ref;

  CancelToken getCancelToken() => CancelToken();

  static const String _filmixAppVersion = '2.0.9';

  late final Map<String, String> _queryParams;

  /// cinema online
  final _dio = Dio(BaseOptions(
    baseUrl: 'http://filmixapp.cyou/api/v2',
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  FilmixApi(this.ref) {
    /// добавляем перехватчик, для логов запросов
    if (kDebugMode) {
      // _dio.interceptors.add(LogInterceptor(responseBody: true));
    }

    /// хранилище данных
    final storage = ref.read(storageProvider);

    String authToken =
        storage.sharedStorage.getString('filmix_auth_token') ?? '';
    if (authToken.isEmpty) {
      authToken = md5
          .convert(const Uuid().v4().codeUnits)
          .toString(); //.substring(0, 18);
      storage.sharedStorage.setString('filmix_auth_token', authToken);
    }

    String deviceId = storage.sharedStorage.getString('filmix_device_id') ?? '';
    if (deviceId.isEmpty) {
      deviceId =
          md5.convert(const Uuid().v4().codeUnits).toString().substring(0, 16);
      storage.sharedStorage.setString('filmix_device_id', deviceId);
    }

    /// информация об устройстве
    final deviceDetails = ref.read(deviceProvider);

    _queryParams = {
      'user_dev_apk': _filmixAppVersion,
      'user_dev_id': deviceId,
      'user_dev_token': authToken,
      'user_dev_name': deviceDetails.name,
      'user_dev_vendor': deviceDetails.vendor,
      'user_dev_os': deviceDetails.osVersion,
    };
  }

  /// поиск фильмов или сериалов
  Future<List<MediaItem>> search({
    required String searchQuery,
    CancelToken? cancelToken,
  }) async {
    return ApiRequest<List<MediaItem>>().call(
      request: _dio.get(
        '/search',
        queryParameters: {..._queryParams, 'story': searchQuery},
        cancelToken: cancelToken,
      ),
      onError: (error) => [],
      decoder: (json) async =>
          json.map<MediaItem>((item) => FilmixItem.fromJson(item)).toList(),
    );
  }

  /// детали фильма или сериала
  Future<FilmixItem> getDetails({
    required String id,
    CancelToken? cancelToken,
    // required MediaItemType mediaItemType,
  }) async {
    return ApiRequest<FilmixItem>().call(
      request: _dio.get(
        '/post/$id',
        queryParameters: {..._queryParams},
        cancelToken: cancelToken,
      ),
      decoder: (json) async {
        final item = FilmixItem.fromJson(json);

        /// парсим рейтинги
        item.imdbRating = double.tryParse('${json['imdb_rating']}') ?? 0.0;
        item.kinopoiskRating = double.tryParse('${json['kp_rating']}') ?? 0.0;

        return item;
      },
    );
  }

  /// список с фильтрацией
  Future<List<MediaItem>> getFiltered(
    List<String> filter,
    int page, {
    CancelToken? cancelToken,
  }) async {
    return ApiRequest<List<MediaItem>>().call(
      request: _dio.get(
        '/catalog',
        queryParameters: {
          ..._queryParams,
          'orderby': 'date',
          'orderdir': 'desc',
          'filter': filter.join('-'),
          'page': page,
        },
        cancelToken: cancelToken,
      ),
      decoder: (json) async => json.map<FilmixItem>((item) {
        final data = item as Map<String, dynamic>;
        data.remove('quality');
        return FilmixItem.fromJson(data);
      }).toList(),
    );
  }

  /// список новых фильмов
  Future<List<MediaItem>> getLatestMovies() async {
    return getFiltered(['s0', 's14'], 1);
  }

  /// список популярных фильмов
  Future<List<MediaItem>> getPopularMovies({CancelToken? cancelToken}) async {
    return ApiRequest<List<MediaItem>>().call(
      request: _dio
          .get('/popular', queryParameters: {..._queryParams, 'section': '0'}),
      decoder: (json) async =>
          json.map<MediaItem>((item) => FilmixItem.fromJson(item)).toList(),
    );
  }

  /// список фильмов за последние три года
  Future<List<MediaItem>> getMoviesLastThreeYears({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final year = DateTime.now().year;
    return getFiltered(
      ['s0', 's14', 'y${year - 2}', 'y${year - 1}', 'y$year'],
      page,
    );
  }

  /// список фильмов по категории
  Future<List<MediaItem>> getMoviesByCategory(
    String categoryId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async =>
      getFiltered(['s0', 's14', categoryId], page);

  /// список сериалов по категории
  Future<List<MediaItem>> getShowsByCategory(
    String categoryId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async =>
      getFiltered(['s7', 's93', categoryId], page);

  /// список новых сериалов
  Future<List<MediaItem>> getLatestShows({CancelToken? cancelToken}) async =>
      getFiltered(['s7', 's93'], 1);

  /// список популярных сериалов
  Future<List<MediaItem>> getPopularShows({CancelToken? cancelToken}) async {
    return ApiRequest<List<MediaItem>>().call(
      request: _dio.get(
        '/popular',
        queryParameters: {..._queryParams, 'section': '7'},
        cancelToken: cancelToken,
      ),
      decoder: (json) async =>
          json.map<MediaItem>((item) => FilmixItem.fromJson(item)).toList(),
    );
  }

  /// список новых сериалов
  Future<List<MediaItem>> getNewestShows({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final year = DateTime.now().year;
    return getFiltered(
        ['s7', 's93', 'y${year - 2}', 'y${year - 1}', 'y$year'], page);
  }

  /// запрос профиля пользователя
  Future<FilmixProfile> getProfile({
    CancelToken? cancelToken,
  }) async {
    return ApiRequest<FilmixProfile>().call(
      request: _dio.get(
        '/user_profile',
        queryParameters: {..._queryParams},
        cancelToken: cancelToken,
      ),
      decoder: (json) async => FilmixProfile.fromJson(json),
    );
  }

  /// запрос ключа авторизации
  Future<FilmixToken> getToken({
    CancelToken? cancelToken,
  }) async {
    return ApiRequest<FilmixToken>().call(
      request: _dio.get(
        '/token_request',
        queryParameters: {
          ..._queryParams,
        },
        cancelToken: cancelToken,
      ),
      decoder: (json) async {
        final token = FilmixToken.fromJson(json);

        /// хранилище данных
        final storage = ref.read(storageProvider);

        storage.sharedStorage.setString('filmix_auth_token', token.code);

        _queryParams['user_dev_token'] = token.code;

        return token;
      },
    );
  }

  /// список категорий
  Future<List<MediaItem>> getCategories({CancelToken? cancelToken}) async {
    return ApiRequest<List<MediaItem>>().call(
      request: _dio.get(
        '/category_list',
        queryParameters: {
          ..._queryParams,
        },
        cancelToken: cancelToken,
      ),
      decoder: (json) async {
        final categories = <MediaItem>[];

        Map.from(json).forEach((key, value) {
          categories.add(FilmixItem(
            id: key.toString().replaceAll('f', 'g'),
            type: MediaItemType.folder,
            title: value,
            poster: '',
          ));
        });

        return categories;
      },
    );
  }
}
