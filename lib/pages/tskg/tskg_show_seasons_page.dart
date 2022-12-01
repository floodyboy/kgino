import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../../controllers/seen_items_controller.dart';
import '../../models/seen_item.dart';
import '../../models/tskg/tskg_episode.dart';
import '../../models/tskg/tskg_show.dart';
import '../../resources/krs_locale.dart';
import '../../resources/krs_theme.dart';
import '../../ui/lists/krs_list_view.dart';
import '../../ui/pages/episode_card.dart';
import '../../utils.dart';


class TskgShowSeasonsPage extends StatefulWidget {
  final TskgShow show;

  const TskgShowSeasonsPage({
    super.key,
    required this.show,
  });

  @override
  State<TskgShowSeasonsPage> createState() => _TskgShowSeasonsPageState();
}

class _TskgShowSeasonsPageState extends State<TskgShowSeasonsPage> {
  final _seasonsScrollController = ListObserverController(
    controller: ScrollController()
  );

  final _episodesScrollController = ListObserverController(
    controller: ScrollController(),
  );

  final _episodes = <TskgEpisode>[];
  late final int _episodeCount;
  int _selectedSeasonIndex = 0;
  int _selectedEpisodeIndex = 0;

  @override
  void initState() {
    /// все эпизоды в одном списке
    for (final season in widget.show.seasons) {
      _episodes.addAll(season.episodes);
    }

    /// количество эпизодов во всех сезонах
    _episodeCount = widget.show.seasons.fold(0, (previousValue, season) {
      return previousValue + season.episodes.length;
    });

    super.initState();
  }

  @override
  void dispose() {
    // _seasonsScrollController.dispatchOnceObserve();
    // _episodesScrollController.dispatchOnceObserve();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = KrsLocale.of(context);

    final currentSeason = widget.show.seasons[_selectedSeasonIndex];
    final seenEpisodesController = GetIt.instance<SeenItemsController>();
    // final seenEpisodes = seenEpisodesController.findByParentId(
    //   tag: SeenEpisode.tskgTag,
    //   parentId: widget.show.showId,
    // );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// номера сезонов
          SizedBox(
            height: 40.0 + 48.0 * 2,
            child: KrsListView(
              padding: const EdgeInsets.all(48.0),
              controller: _seasonsScrollController,
              spacing: 8.0,
              onLoadNextPage: () {
                
              },
              onItemFocused: (index) {
                _checkEpisodeBySeasonIndex(index);
              },
              requestItemIndex: () => _selectedSeasonIndex,
              itemCount: widget.show.seasons.length,
              itemBuilder: (context, index) {
                return IconButton(
                  style: ButtonStyle(
                    
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.focused)) {
                        return theme.colorScheme.primary;
                      }

                      if (_selectedSeasonIndex == index) {
                        return theme.colorScheme.primary.withOpacity(0.62);
                      } else {
                        return theme.colorScheme.secondaryContainer;
                      }
                    }),

                    foregroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.focused)) {
                        return theme.colorScheme.onPrimary;
                      }
                    }),
                    textStyle: MaterialStateProperty.resolveWith((states) {
                      return const TextStyle();
                    }),

                    overlayColor: MaterialStateProperty.all(null),
                    
                  ),
                  // _selectedSeasonIndex == index
                  //     ? KrsTheme.filledButtonStyleOf(context)
                  //     : KrsTheme.filledTonalButtonStyleOf(context),
                  onPressed: () {
                    /// при нажатии на номер сезона
                    _checkEpisodeBySeasonIndex(index);
                  },
                  icon: Text('${index + 1}'),
                );
              },
            ),
          ),

          const SizedBox(height: 48.0),

          /// список эпизодов
          Expanded(
            child: SizedBox.fromSize(
              size: const Size.fromHeight(112.0 + 24.0 + 18.0 + 8.0),
              child: KrsListView(
                controller: _episodesScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                spacing: 24.0,
                titleText: '${currentSeason.title}, ${locale.episodesCount(currentSeason.episodes.length)}',
                onLoadNextPage: () {
                  
                },
                onItemFocused: (index) {
                  _checkSeasonByEpisodeIndex(index);
                },
                requestItemIndex: () => _selectedEpisodeIndex,
                itemCount: _episodeCount,
                itemBuilder: (context, index) {
                  // final seasonAndEpisode = getSeasonByGlobalEpisodeIndex(index);
                  // final season = seasonAndEpisode.season;
                  final episode = _episodes[index];

                  /// просмотренное время [0; 1]
                  double seenValue = 0.0;
                  final seenEpisode = seenEpisodesController.findEpisode(
                    tag: SeenItem.tskgTag,
                    itemId: widget.show.showId,
                    episodeId: episode.id,
                  );

                  if (seenEpisode != null) {
                    seenValue = seenEpisode.percentPosition;
                  }

                  return EpisodeCard(
                    titleText: episode.name,
                    description: '${episode.quality} ${Utils.formatDuration(episode.duration)}',

                    /// время просмотра
                    seenValue: seenValue,

                    onPressed: () {
                      /// переходим на страницу плеера сериала
                      context.goNamed('tskgPlayer',
                        params: {
                          'id': widget.show.showId,    
                        },
                        queryParams: {
                          'startTime': 0.toString(),
                          'episodeIndex': index.toString(),
                        },
                        extra: widget.show,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkSeasonByEpisodeIndex(int episodeIndex) {
    int episodesOffset = 0;
    
    for (int i = 0; i < widget.show.seasons.length; i++) {
      /// текущий сезон
      final season = widget.show.seasons[i];

      /// количество эпизодов в текущем сезоне
      final episodesCount = season.episodes.length;

      /// относительный индекс эпизода в нужном сезоне
      final index = episodeIndex - episodesOffset;
      
      if (episodesCount > index) {

        /// обновляем индекс сезона
        setState(() {
          _selectedSeasonIndex = i;
        });

        /// прокручиваем список сезонов к выбранному сезону
        _seasonsScrollController.animateTo(
          index: _selectedSeasonIndex,
          isFixedHeight: true,
          offset: (offset) => 48.0,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeIn,
        );
        
        break;
      }
      episodesOffset += episodesCount;
    }

    /// обновляем индекс эпизода
    setState(() {
      _selectedEpisodeIndex = episodeIndex;
    });

  }

  void _checkEpisodeBySeasonIndex(int seasonIndex) {
    int minIndex = 0;

    for (int i = 0; i < seasonIndex; i++) {
      /// текущий сезон
      final season = widget.show.seasons[i];

      /// количество эпизодов в текущем сезоне
      final episodesCount = season.episodes.length;

      /// минимальный индекс эпизода в нужном сезоне
      minIndex += episodesCount;
    }

    /// максимальный индекс эпизода в нужном сезоне
    int maxIndex = minIndex + widget.show.seasons[seasonIndex].episodes.length;

    if (_selectedEpisodeIndex < minIndex
        || _selectedEpisodeIndex >= maxIndex) {
      /// ^ если текущий выбранный эпизод не в выбранном сезоне

      /// прокручиваем список к первому эпизоду выбранного сезона
      _episodesScrollController.animateTo(
        index: minIndex,
        isFixedHeight: true,
        offset: (offset) => 48.0,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeIn,
      );

      /// обновляем индексы эпизода и сезона
      setState(() {
        _selectedEpisodeIndex = minIndex;
        _selectedSeasonIndex = seasonIndex;
      });

    } else {
      /// ^ если текущий выбранный эпизод из выбранного сезона

      /// обновляем индекс сезона
      setState(() {
        _selectedSeasonIndex = seasonIndex;
      });

    }
    
  }

}
