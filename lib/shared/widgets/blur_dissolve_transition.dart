import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium transition widget that executes a photographic "blur dissolve":
/// the outgoing content blurs away as it fades, while the incoming content
/// sharpens from an ethereal blur into crisp focus.
/// Fast and responsive so it never feels slow.
class BlurDissolveSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double maxBlur;
  final Curve curve;

  const BlurDissolveSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.maxBlur = 8.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            // When t goes from 0 -> 1, blur goes from maxBlur -> 0
            final currentBlur = ((1.0 - t) * maxBlur).clamp(0.0, maxBlur);
            final opacity = t.clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: currentBlur > 0.1
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: currentBlur,
                        sigmaY: currentBlur,
                      ),
                      child: child,
                    )
                  : child,
            );
          },
        );
      },
      child: child,
    );
  }
}

/// Transition for page routes where the incoming screen sharpens into focus
/// while the outgoing screen blurs away.
class BlurDissolvePageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final double maxBlur;

  const BlurDissolvePageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.maxBlur = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, _) {
        final enterT = animation.value;
        final exitT = secondaryAnimation.value;

        // Primary entering: opacity goes 0 -> 1, blur goes maxBlur -> 0
        double opacity = enterT;
        double blur = (1.0 - enterT) * maxBlur;

        // Secondary exiting (pushed over by another route): blurs away as it fades
        if (exitT > 0.0) {
          opacity = (opacity * (1.0 - exitT * 0.7)).clamp(0.0, 1.0);
          blur = (blur + exitT * maxBlur).clamp(0.0, maxBlur);
        }

        final effectiveBlur = blur.clamp(0.0, maxBlur);

        if (effectiveBlur <= 0.05 && opacity >= 0.99) {
          return child;
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: effectiveBlur > 0.1
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: effectiveBlur,
                    sigmaY: effectiveBlur,
                  ),
                  child: child,
                )
              : child,
        );
      },
    );
  }
}

/// A PageTransitionsBuilder that produces a snappy blur-dissolve transition for MaterialApp.
class BlurDissolvePageTransitionsBuilder extends PageTransitionsBuilder {
  final double maxBlur;

  const BlurDissolvePageTransitionsBuilder({this.maxBlur = 8.0});

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
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
      child: child,
    );
  }
}

/// Custom Route for explicit blur-dissolve route pushing
class BlurDissolvePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final Duration duration;

  BlurDissolvePageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 280),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
              child: child,
            );
          },
        );
}
