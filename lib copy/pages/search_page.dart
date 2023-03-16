import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kgino/constants.dart';

import '../controllers/flmx/flmx_search_controller.dart';
import '../controllers/ockg/ockg_search_controller.dart';
import '../controllers/tskg/tskg_search_controller.dart';
import '../models/movie_item.dart';
import '../resources/krs_locale.dart';
import '../models/category_list_item.dart';
import '../ui/lists/krs_horizontal_list_view.dart';
import '../ui/lists/krs_vertical_list_view.dart';
import '../ui/lists/krs_list_item_card.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final locale = KrsLocale.of(context);

    final ockgSearch = context.watch<OckgSearchController>().state;
    final tskgSearch = context.watch<TskgSearchController>().state;
    final flmxSearch = context.watch<FlmxSearchController>().state;

    final items = <CategoryListItem<MovieItem>>[];
    if (ockgSearch.isSuccess) {
      items.add(
        CategoryListItem(
          title: locale.movies,
          items: ockgSearch.data,
        )
      );
    }
    if (tskgSearch.isSuccess) {
      items.add(
        CategoryListItem(
          title: locale.shows,
          items: tskgSearch.data,
        )
      );
    }
    if (flmxSearch.isSuccess) {
      items.add(
        CategoryListItem(
          title: 'Filmix',
          items: flmxSearch.asData.data,
        )
      );
    }

    if (items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48.0),
        child: KrsVerticalListView(
          itemCount: items.length,
          itemBuilder: (context, focusNode, index) {
            final item = items[index];

            return SizedBox.fromSize(
              size: const Size.fromHeight(ockgListViewHeight),
              child: KrsHorizontalListView<MovieItem>(
                key: UniqueKey(),
                focusNode: focusNode,
                titleText: item.title,
                items: item.items,
                itemBuilder: (context, focusNode, index, show) {
                  return KrsListItemCard(
                    focusNode: focusNode,
                    posterSize: (show.type == MovieItemType.ockg)
                      ? ockgPosterSize
                      : (show.type == MovieItemType.flmx)
                      ? ockgPosterSize
                      : tskgPosterSize,
                    item: show,
                    
                    /// при выборе элемента
                    onTap: () {

                      late final String routeName;
                      switch (show.type) {
                        case MovieItemType.ockg:
                          routeName = 'ockgMovieDetails';
                          break;

                        case MovieItemType.flmx:
                          routeName = 'flmxDetails';
                          break;

                        case MovieItemType.tskg:
                        default:
                          routeName = 'tskgShowDetails';
                          break;
                      }

                      /// переходим на страницу деталей
                      context.goNamed(routeName,
                        params: {
                          'id': show.id,
                        },
                      );

                    },
                  );
                },
              ),
            );
          },
          
        )
      );
    }

    return const SizedBox();

  }
}