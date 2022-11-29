import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../../constants.dart';
import '../../../controllers/tskg/tskg_news_controller.dart';
import '../../../controllers/tskg/tskg_show_details_controller.dart';
import '../../../models/tskg/tskg_show.dart';
import '../../lists/krs_list_view.dart';
import '../../loading_indicator.dart';
import 'tskg_show_card.dart';
import 'tskg_shows_list_view.dart';

class TskgHomePageListView extends StatefulWidget {
  const TskgHomePageListView({
    super.key,
  });

  @override
  State<TskgHomePageListView> createState() => _TskgHomePageListViewState();
}

class _TskgHomePageListViewState extends State<TskgHomePageListView> {
  final _autoScrollController = AutoScrollController(
    axis: Axis.vertical,
    viewportBoundaryGetter: () => const Rect.fromLTRB(0.0, 0.0, 0.0, 32.0),
  );

  @override
  void dispose() {
    _autoScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(context) {
    return BlocProvider(
      create: (context) => TskgNewsController(),
      child: BlocBuilder<TskgNewsController, RequestState<List<TskgShow>>>(
        builder: (context, state) {
          if (state.isSuccess) {
            final news = state.data;
            
            /// сериалы сгруппированные по дате добавления
            final showsGroupedByDate = groupBy(
              news,
              (item) => item.date,
            );

            final itemsCount = 3;

            return ListView.separated(
              controller: _autoScrollController,
              itemCount: itemsCount + 1,
              
              /// разделитель
              separatorBuilder: (context, index) {
                return const SizedBox(height: 24.0);
              },

              itemBuilder: (context, index) {
                if (index == itemsCount) {
                  /// ^ последний элемент в списке
                  return const SizedBox(height: 32.0);
                }

                /// дата добавления сериала
                final date = showsGroupedByDate.keys.elementAt(index)!;
                final dateFormatter = DateFormat('dd MMMM', 'ru');
                final titleText = 'Добавленные ${dateFormatter.format(date)}';

                final shows = showsGroupedByDate.values.elementAt(index);

                return Focus(
                  skipTraversal: true,
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _autoScrollController.scrollToIndex(index,
                        preferPosition: AutoScrollPosition.begin,
                      );
                    }
                  },
                  child: AutoScrollTag(
                    key: ValueKey(index), 
                    controller: _autoScrollController,
                    index: index,
                    child: SizedBox.fromSize(
                      size: const Size.fromHeight(tskgListViewHeight),
                      child: KrsListView(
                        onItemFocused: (index) {
                          context.read<TskgShowDetailsController>().getShowById(
                            shows[index].showId,
                          );
                        },
                        titleText: titleText,
                        itemCount: shows.length,
                        itemBuilder: (context, index) {
                          final show = shows[index];

                          return TskgShowCard(
                            show: show,
                            
                            /// при выборе элемента
                            onTap: () {
                              /// переходим на страницу деталей о фильме
                              context.goNamed('tskgShowDetails', params: {
                                'id': show.showId,
                              });

                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const LoadingIndicator();
        },
      ),
    );
  }
}