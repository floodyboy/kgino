import 'package:go_router/go_router.dart';

import '../models/ockg/ockg_movie.dart';
import '../models/playable_item.dart';
import '../pages/error_page.dart';
import '../pages/home_page.dart';
import '../pages/ockg/ockg_catalog_page.dart';
import '../pages/ockg/ockg_movie_details_page.dart';
import '../pages/ockg/ockg_movie_files_page.dart';
import '../pages/ockg/ockg_player_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../pages/player_page.dart';

class KrsRouter {
  static final routes = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    errorBuilder: (context, state) => const ErrorPage(),

    routes: [

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomePage();
        },
        routes: [
          GoRoute(
            path: 'ockg/movie/:id',
            name: 'ockgMovieDetails',
            builder: (context, state) {
              final movieId = int.tryParse(state.params['id'] ?? '') ?? 0;
              return OckgMovieDetailsPage(movieId);
            },
            routes: [
              GoRoute(
                path: 'files',
                name: 'ockgMovieFiles',
                builder: (context, state) {
                  final movie = state.extra as OckgMovie;
                  return OckgMovieFilesPage(
                    movie: movie,
                  );
                },
              ),

              GoRoute(
                path: 'player',
                name: 'ockgMoviePlayer',
                builder: (context, state) {
                  final movie = state.extra as OckgMovie;
                  final startTime = int.tryParse(state.queryParams['startTime'] ?? '0');
                  final fileIndex = int.tryParse(state.queryParams['fileIndex'] ?? '0');

                  return OckgPlayerPage(
                    movie: movie,
                    startTime: startTime ?? 0,
                    fileIndex: fileIndex ?? 0,
                  );
                },
              ),
            ]
          ),

          GoRoute(
            path: 'ockg/genre/:id',
            builder: (context, state) {
              final titleText = state.extra! as String;
              final genreId = int.tryParse(state.params['id'] ?? '') ?? 0;
              return OckgCatalogPage(
                titleText: titleText,
                genreId: genreId,
              );
            },
          ),

          GoRoute(
            path: 'player',
            builder: (context, state) {
              final videoPlayerItem = state.extra as PlayableItem;
              return PlayerPage(
                videoPlayerItem: videoPlayerItem,
              );
            },
          ),

        ]
      ),

      
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          return const SettingsPage();
        },
      ),

      GoRoute(
        path: '/search',
        builder: (context, state) {
          return const SearchPage();
        },
      ),
      
    ],
  );
}