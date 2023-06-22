import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';

import '../../controllers/tabs_cubit.dart';
import '../../resources/krs_theme.dart';

class KrsTabBarButton extends HookWidget {
  final int index;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget label;
  final bool selected;

  const KrsTabBarButton({
    super.key,
    required this.index,
    required this.onPressed,
    this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final focusState = useState(false);

    final tabsCubit = GetIt.instance<TabsCubit>();

    final selected = tabsCubit.state == index;
    final focusNode = tabsCubit.focusNodes[index];
    void onFocusChange(hasFocus) {
      if (hasFocus) {
        tabsCubit.updateSelected(index);
      }

      focusState.value = hasFocus;
    }

    Color? backgroundColor;
    if (focusState.value) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.24);
    } else if (selected) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.12);
    }
    final foregroundColor = theme.textTheme.bodyMedium?.color;

    final buttonStyle = TextButton.styleFrom(      
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );


    return TextButton(
      style: buttonStyle,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onPressed: () {
        tabsCubit.unfocusAll();
        tabsCubit.updateSelected(index);
      },
      child: label
    );
    
    // InkWell(
    //   focusNode: focusNode,
    //   onFocusChange: onFocusChange,

    //   borderRadius: BorderRadius.circular(32.0),

    //   onTap: () {
    //     tabsCubit.unfocusAll();
    //     tabsCubit.updateSelected(index);
    //   },

    //   child: AnimatedContainer(
    //     height: 40.0,
    //     padding: const EdgeInsetsDirectional.symmetric(horizontal: 16.0),
    //     duration: KrsTheme.animationDuration,
    //     decoration: BoxDecoration(
    //       borderRadius: BorderRadius.circular(32.0),
    //       color: backgroundColor,
    //     ),
    //     child: Row(
    //       children: [
    //         if (icon != null) Padding(
    //           padding: const EdgeInsetsDirectional.only(end: 12.0),
    //           child: icon,
    //         ),
            
    //         DefaultTextStyle(
    //           style: DefaultTextStyle.of(context).style.copyWith(
    //             fontSize: 16.0,
    //             fontWeight: FontWeight.w500,
    //           ),
    //           child: label,
    //         ),
    //       ],
    //     ),
    //   ),
    // );

  }
}
