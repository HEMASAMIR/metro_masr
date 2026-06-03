import 'package:flutter/material.dart';

/// Feature #10: Unified premium page transitions for the entire app.
///
/// Usage:
/// ```dart
/// Navigator.push(context, RafiqPageRoute(page: MyPage()));
/// ```
class RafiqPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RafiqTransitionType type;

  RafiqPageRoute({
    required this.page,
    this.type = RafiqTransitionType.slideUp,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (type) {
              case RafiqTransitionType.slideUp:
                return _slideUpTransition(animation, child);
              case RafiqTransitionType.fadeScale:
                return _fadeScaleTransition(animation, child);
              case RafiqTransitionType.slideRight:
                return _slideRightTransition(animation, child);
            }
          },
        );

  static Widget _slideUpTransition(Animation<double> animation, Widget child) {
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(curve);
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }

  static Widget _fadeScaleTransition(Animation<double> animation, Widget child) {
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
        child: child,
      ),
    );
  }

  static Widget _slideRightTransition(Animation<double> animation, Widget child) {
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(curve);
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

enum RafiqTransitionType {
  slideUp,
  fadeScale,
  slideRight,
}
