import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';

import '../models/category_list_item.dart';
import '../models/kgino_item.dart';
import '../resources/krs_storage.dart';
import '../ui/lists/horizontal_list_view.dart';
import '../ui/lists/kgino_list_tile.dart';
import '../ui/lists/kgino_raw_list_tile.dart';
import '../ui/lists/vertical_list_view.dart';

class MoviesPage extends HookWidget {
  const MoviesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    /// хранилище данных
    final storage = GetIt.instance<KrsStorage>();

    final categories = useState({

      'services': CategoryListItem(
        title: 'Выберите сервис',
        items: [
          KginoItem(
            provider: KginoProvider.flmxShow.name,
            id: '/flmx/movies',
            name: 'Filmix',
            posterUrl: 'assets/images/flmx.svg',
            isFolder: true,
          ),

          KginoItem(
            provider: KginoProvider.tskg.name,
            id: '/ockg',
            name: 'OC.KG',
            posterUrl: 'https://oc.kg/templates/mobile/img/logooc_winter.png',
            isFolder: true,
          ),
        ],
      ),

    });

    /// фильтруем сохранённые сериалы
    final savedItemsQuery = storage.db.kginoItems
      .where()
      .filter()
      .bookmarkedIsNotNull()
      .providerEqualTo(KginoProvider.flmxMovie.name)
      .or()
      .providerEqualTo(KginoProvider.ockg.name)
      .sortByBookmarkedDesc()
      .build();

    final savedItems = savedItemsQuery.watch(fireImmediately: true);
    savedItems.listen((data) {
      final newCategories = {...categories.value};
      newCategories['saved'] = CategoryListItem(
        title: 'В закладках',
        items: data,
      );
      categories.value = newCategories;
    });

    return VerticalListView(
      itemCount: categories.value.length,
      itemBuilder: (context, focusNode, index) {
        final category = categories.value.values.elementAt(index);

        return HorizontalListView<KginoItem>(
          focusNode: focusNode,
          titleText: category.title,
          itemsFuture: category.itemsFuture,
          itemBuilder: (context, focusNode, index, item) {

            if (item.isFolder) {
              return KginoRawListTile(
                focusNode: focusNode,
                onFocused: (focusNode) {
                  
                },
                onTap: () {
                  context.push(item.id);
                },
                title: item.name,
                imageUrl: item.posterUrl,
              );
            }

            /// карточка фильма
            return KginoListTile(
              focusNode: focusNode,
              onTap: () {
                /// переходим на страницу сериала
                context.pushNamed(item.provider == KginoProvider.flmxShow.name
                  ? 'flmxMovieDetails' : 'ockgDetails',
                  pathParameters: {
                    'id': item.id,
                  },
                );
              },
              item: item,
            );

          },
          
        );
      },
    );

  }
}