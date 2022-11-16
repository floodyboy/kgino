import 'package:collection/collection.dart';
import 'package:ensure_visible_when_focused/ensure_visible_when_focused.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/ockg/ockg_bestsellers_category.dart';

class OckgBestsellersCategoryList extends StatefulWidget {
  final OckgBestsellersCategory category;

  const OckgBestsellersCategoryList({
    super.key,
    required this.category,
  });

  @override
  State<OckgBestsellersCategoryList> createState() => _OckgBestsellersCategoryListState();
}

class _OckgBestsellersCategoryListState extends State<OckgBestsellersCategoryList> {
  bool _focused = false;
  bool _wasFocused = false;
  bool _focuseRequested = false;

  final _titleFocusNode = FocusNode();
  final _fakeFocusNode = FocusNode();
  late final List<FocusNode> _elementsFocusNodes;

  @override
  void initState() {
    /// инициализируем [FocusNode] для карточек фильмов
    _elementsFocusNodes = List.generate(widget.category.movies.length, (index) {
      return FocusNode();
    });

    // _titleFocusNode.onKeyEvent = (node, event) {
    //   if (_wasFocused && event.logicalKey == LogicalKeyboardKey.arrowDown) {
    //     _elementsFocusNodes.first.requestFocus();
    //     return KeyEventResult.skipRemainingHandlers;
    //   }

    //   return KeyEventResult.ignored;
    // };

    // _titleFocusNode.onKey = (node, event) {
    //   if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
    //     _elementsFocusNodes.first.requestFocus();
    //     return KeyEventResult.skipRemainingHandlers;
    //   }

    //   return KeyEventResult.ignored;
    // };

    super.initState();
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();

    for (final focusNode in _elementsFocusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        //print('onFocusChange ${widget.category.name}');
        
        // if (!_focused && hasFocus) {
        //   /// ^ если фокус только что перешёл на этот элемент
          
        //   /// запрашиваем фокус на название категории
        //   _titleFocusNode.requestFocus();
        // }

        _wasFocused = _focused;
        _focused = hasFocus;
      },

      onKey: (node, event) {
        print('onKey ${widget.category.name}');
        print('node hasFocus ${node.hasFocus}');
        print('node event.character ${event.character}');
        print('node event.isKeyPressed up ${event.isKeyPressed(LogicalKeyboardKey.arrowUp)}');
        print('node event.isKeyPressed down ${event.isKeyPressed(LogicalKeyboardKey.arrowDown)}');
        print('node event.logicalKey ${event.logicalKey}');

        node.traversalChildren.forEachIndexed((index, element) {
          if (index == 0 && element.hasFocus) {
            print('title focused');
          }
        });

        if (_wasFocused && _titleFocusNode.hasFocus && event.logicalKey == LogicalKeyboardKey.arrowDown && !event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          node.traversalChildren.elementAt(1).requestFocus();
        }

        // if (node.hasFocus) {
        //   /// ^ если блок в фокусе

        if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          /// ^ если нажали вверх
          
          if (_titleFocusNode.hasFocus) {
            /// если название категории уже в фокусе
            
            /// игнорируем нажатие - передаём выбор системе
            return KeyEventResult.ignored;
          
          } else {
            /// если название категории не в фокусе
            
            /// ставим фокус на название категории
            _titleFocusNode.requestFocus();
            return KeyEventResult.handled;

          }

        }

        if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          /// ^ если нажали вниз
          
          if (_titleFocusNode.hasFocus) {
            _elementsFocusNodes.first.requestFocus();
            _focuseRequested = true;
            //return KeyEventResult.handled;
          }

        }

        if (_fakeFocusNode.hasFocus) {
          if (_focuseRequested) {
            _elementsFocusNodes.first.requestFocus();
            _focuseRequested = false;
            return KeyEventResult.handled;
          } else {
            
            if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              node.nextFocus();
            }
            // if (!_wasFocused) {
            //   _elementsFocusNodes.first.requestFocus();
            // }
            
          }
          
        }

        //   if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
        //     /// ^ если нажали вниз
            
        //     if (_titleFocusNode.hasFocus) {
        //       /// если название категории уже в фокусе
              
        //       /// 
        //       // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        //       //   _elementsFocusNodes.first.requestFocus();
        //       // });

        //       // setState(() {
                
        //       // });
        //       node.focusInDirection(TraversalDirection.left);
        //       return KeyEventResult.ignored;
        //       //.requestFocus();
        //       //FocusScope.of(context).previousFocus();
        //       //return KeyEventResult.skipRemainingHandlers;
            
        //     } else {
        //       /// если название категории не в фокусе
              
        //       // /// ставим фокус на название категории
        //       // _titleFocusNode.requestFocus();
        //       // return KeyEventResult.handled;

        //     }
            
        //   }

          
          
        // }

        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            focusNode: _titleFocusNode,
            onPressed: () {

            },
            child: Text(widget.category.name),
          ),

          SizedBox.fromSize(
            size: const Size.fromHeight(168.0),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.category.movies.length,
              itemBuilder: (context, index) {
                final movie = widget.category.movies[index];
                return Stack(
                    children: <Widget>[
                      Image.network('https://oc.kg${movie.cover}',
                        width: 120.0,
                        height: 168.0,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: EnsureVisibleWhenFocused(
                            focusNode: _elementsFocusNodes[index],
                            child: InkWell(
                              focusNode: _elementsFocusNodes[index],
                              onTap: () {

                              },
                            ),
                          ),

                        ),
                      ),
                    ],
                );
              },
              separatorBuilder: (context, index) {
                return const SizedBox(width: 24.0);
              },
              
            ),
          ),
          // Focus(
          //   skipTraversal: true,
          //   canRequestFocus: true,
          //   focusNode: _fakeFocusNode,
          //   child: const SizedBox(),
          // ),
          Focus(
            canRequestFocus: true,
            focusNode: _fakeFocusNode,
            
            child: Text(widget.category.name),
          ),
        ],
      ),
    );
  }
}