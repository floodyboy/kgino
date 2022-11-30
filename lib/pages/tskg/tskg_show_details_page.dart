import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../controllers/tskg/tskg_favorites_controller.dart';
import '../../controllers/tskg/tskg_favorites_cubit.dart';
import '../../controllers/tskg/tskg_show_details_controller.dart';
import '../../models/tskg/tskg_favorite.dart';
import '../../models/tskg/tskg_show.dart';
import '../../resources/krs_locale.dart';
import '../../resources/krs_theme.dart';
import '../../ui/krs_scroll_view.dart';
import '../../ui/loading_indicator.dart';
import '../../ui/pages/try_again_message.dart';
import '../../ui/pages/tskg/tskg_show_details.dart';


class TskgShowDetailsPage extends StatefulWidget {
  final String showId;

  const TskgShowDetailsPage(this.showId, {
    super.key,
  });

  @override
  State<TskgShowDetailsPage> createState() => _TskgShowDetailsPageState();
}

class _TskgShowDetailsPageState extends State<TskgShowDetailsPage> {
  final _scrollController = ScrollController();
  bool _isScrolling = false;

  @override
  Widget build(BuildContext context) {

    final locale = KrsLocale.of(context);

    final tskgFavoritesController = TskgFavoritesController();

    return Scaffold(
      body: BlocProvider(
        create: (context) => TskgShowDetailsController(
          showId: widget.showId,
        ),
        child: BlocBuilder<TskgShowDetailsController, RequestState<TskgShow>>(
          builder: (context, state) {
            if (state.isError || state.isEmpty) {
              return TryAgainMessage(
                onRetry: () {
                  
                }
              );
            }
            
            if (state.isSuccess) {
              final show = state.data;
              return KrsScrollView(
                scrollController: _scrollController,
                onStartScroll: (scrollMetrics) {
                  _isScrolling = true;
                },
                onEndScroll: (scrollMetrics) {
                  _isScrolling = false;
                },
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 72.0),
                    height: MediaQuery.of(context).size.height - (32 * 2 + 40 + 72.0),
                    child: TskgShowDetais(
                      show: show,
                      expanded: true,
                    ),
                  ),

                  Focus(
                    skipTraversal: true,
                    onKey: (node, event) {
                      if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                        if (!_isScrolling) {
                          _scrollController.animateTo(0.0,
                            duration: KrsTheme.animationDuration,
                            curve: Curves.easeIn,
                          );
                        }
                      }

                      return KeyEventResult.ignored;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Row(
                        children: [

                          /// кнопка начала просмотра
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton.icon(
                              autofocus: true,
                              style: KrsTheme.filledTonalButtonStyleOf(context),
                              onPressed: () {
                                /// переходим на страницу плеера фильма
                                context.goNamed('tskgPlayer',
                                  params: {
                                    'id': show.showId,
                                  },
                                  queryParams: {
                                    'startTime': '0',
                                    'episodeIndex': '0',
                                  },
                                  extra: show,
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: Text(locale.play),
                            ),
                          ),

                          /// кнопка выбора эпизода
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton.icon(
                              style: KrsTheme.filledTonalButtonStyleOf(context),
                              onPressed: () {
                                /// переходим на страницу выбора эпизода
                                context.goNamed('tskgShowSeasons',
                                  params: {
                                    'id': show.showId,
                                  },
                                  extra: show,
                                );
                              },
                              icon: const Icon(Icons.folder_open),
                              
                              /// если сезонов несколько "выбрать сезон", иначе
                              /// "выбрать серию"
                              label: Text(show.seasons.length > 1
                                  ? locale.selectSeason : locale.selectEpisode
                              ),
                            ),
                          ),

                          ValueListenableBuilder(
                            valueListenable: tskgFavoritesController.box.listenable(),
                            builder: (context, Box<TskgFavorite> box, _) {
                              if (box.containsKey(show.showId)) {
                                /// ^ если уже добавлен в избранное
                                
                                /// кнопка удаления из избранного
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ElevatedButton.icon(
                                    style: KrsTheme.filledTonalButtonStyleOf(context),
                                    onPressed: () {
                                      /// убираем из избранного
                                      tskgFavoritesController.remove(show.showId);
                                    },
                                    icon: const Icon(Icons.bookmark_remove),
                                    label: Text(locale.removeFromFavorites),
                                  ),
                                );
                                
                              } else {
                                /// ^ если ещё нет в избранном

                                /// кнопка добавления в избранное
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ElevatedButton.icon(
                                    style: KrsTheme.filledTonalButtonStyleOf(context),
                                    onPressed: () {
                                      /// добавляем в избранное
                                      tskgFavoritesController.add(show);
                                    },
                                    icon: const Icon(Icons.bookmark_add_outlined),
                                    label: Text(locale.addToFavorites),
                                  ),
                                );
                              }
                            }
                          ),

                        ],
                      ),
                    ),
                  ),

                  // if (movie.files.length > 1) SizedBox(
                  //   height: 300,
                  //   child: ListView.separated(
                  //     scrollDirection: Axis.horizontal,
                  //     itemCount: movie.files.length,
                  //     itemBuilder: (context, index) {
                  //       final file = movie.files[index];

                  //       return InkWell(
                  //         onTap: () {
                  //           print(file);
                  //         },
                  //         child: Card(
                  //           child: Text(file.name),
                  //         ),
                  //       );
                  //     },
                  //     separatorBuilder: (context, index) {
                  //       return const SizedBox(width: 24.0,);
                  //     },
                  //   ),
                  // )

                ],
              );
            }

            return const LoadingIndicator();
          },
        ),
      ),
    );
  }
}
