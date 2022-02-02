import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kgino/api/tskg/tskg_api.dart';
import 'package:kgino/controllers/controllers.dart';
import 'package:kgino/ui/pages/show_page/show_details.dart';
import 'package:palette_generator/palette_generator.dart';

class ShowPage extends StatefulWidget {
  final String id;

  const ShowPage({
    Key? key,
    this.id = '',
  }) : super(key: key);

  @override
  State<ShowPage> createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {

  List<Color> _imageColors = [Colors.black, Colors.black, Colors.black];
  late String posterUrl;

  @override
  void initState() {
    super.initState();

    /// формируем ссылку на постер сериала
    posterUrl = TskgApi.getPosterUrl(widget.id);

    /// меняем цвет фона, в зависимости от основных цветов постера
    setBackgroundColors();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    /// определяем ширину постера на фоне
    final width = (size.width < 480.0) ? size.width + (size.width * 0.1) : 480.0;

    return Scaffold(
      // appBar: AppBar(
      //   leading: const BackButton(),
      //   elevation: 0,
      // ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(
            top: -(width * 0.18),
            right: -(width * 0.05),

            /// "смягчаем" левую границу постера
            child: ShaderMask(
              blendMode: BlendMode.dstOut,
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.center,
                  stops: const [0.05, 1],
                  colors: [theme.scaffoldBackgroundColor, Colors.transparent],
                ).createShader(rect);
              },

              /// "смягчаем" нижнюю границу постера
              child: ShaderMask(
                blendMode: BlendMode.dstOut,
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    stops: const [0.05, 1],
                    colors: [theme.scaffoldBackgroundColor, Colors.transparent],
                  ).createShader(rect);
                },
                

                child: CachedNetworkImage(
                  width: width,
                  fit: BoxFit.cover,
                  imageUrl: posterUrl,
                  progressIndicatorBuilder: (context, url, downloadProgress) {
                    return CircularProgressIndicator(
                      value: downloadProgress.progress
                    );
                  },
                  errorWidget: (context, url, error) {
                    return const Icon(Icons.error);
                  },
                ),
              ),
            ),

          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.5, 1],
                  colors: [
                    _imageColors[0].withOpacity(0.2),
                    _imageColors[1].withOpacity(0.5),
                    _imageColors[2].withOpacity(0.5),
                  ],
                )
              ),

              /// информация о сериале
              child: ShowDetails(widget.id),
              
            ),
          ),
          
        ],
      ),
    );
  }

  Future<void> setBackgroundColors() async {
    /// вычисляем основные цвета изображения
    final pallete = await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(posterUrl),
      maximumColorCount: 4,
    );

    if (pallete.colors.isNotEmpty) {
      _imageColors = pallete.colors.toList();

      while (_imageColors.length < 3) {
        _imageColors.add(_imageColors[0]);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
}