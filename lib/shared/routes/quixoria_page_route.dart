import 'package:flutter/material.dart';
import '../widgets/blur_dissolve_transition.dart';

/// A fluid, photographic Blur-Dissolve page transition:
/// The outgoing screen blurs away as it fades, while the incoming screen
/// sharpens from blur into crisp focus. Snappy and responsive.
class QuixoriaPageRoute<T> extends PageRouteBuilder<T> {
  final Widget? child;
  final WidgetBuilder? builder;
  final double maxBlur;

  QuixoriaPageRoute({
    this.child,
    this.builder,
    this.maxBlur = 8.0,
    super.settings,
  })  : assert(child != null || builder != null, 'Either child or builder must be provided'),
        super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              child ?? builder!(context),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondaryAnimation, childWidget) {
            return BlurDissolvePageTransition(
              animation: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              secondaryAnimation: CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              maxBlur: maxBlur,
              child: childWidget,
            );
          },
        );
}
