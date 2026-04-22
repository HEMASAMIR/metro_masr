import 'package:flutter/material.dart';

/// Breakpoints
/// - phone  : width < 600
/// - tablet : 600 <= width < 1024
/// - desktop: width >= 1024
class Responsive {
  final BuildContext _context;
  late final double _width;
  late final double _height;
  late final Orientation _orientation;

  Responsive(this._context) {
    final mq = MediaQuery.of(_context);
    _width = mq.size.width;
    _height = mq.size.height;
    _orientation = mq.orientation;
  }

  // ── Device type ──────────────────────────────────────────────────────────
  bool get isPhone => _width < 600;
  bool get isTablet => _width >= 600 && _width < 1024;
  bool get isDesktop => _width >= 1024;
  bool get isLandscape => _orientation == Orientation.landscape;
  bool get isPortrait => _orientation == Orientation.portrait;

  // ── Screen dimensions ────────────────────────────────────────────────────
  double get screenWidth => _width;
  double get screenHeight => _height;

  // ── Adaptive values ──────────────────────────────────────────────────────

  /// Adaptive padding: phone=16, tablet=28, desktop=40
  double get pagePadding => isPhone ? 16 : isTablet ? 28 : 40;

  /// Adaptive font sizing
  double fontSize(double phoneSize) {
    if (isDesktop) return phoneSize * 1.4;
    if (isTablet) return phoneSize * 1.2;
    return phoneSize;
  }

  /// Adaptive icon sizing
  double iconSize(double phoneSize) {
    if (isDesktop) return phoneSize * 1.5;
    if (isTablet) return phoneSize * 1.25;
    return phoneSize;
  }

  /// Number of columns in a grid
  /// phone portrait=1, phone landscape=2, tablet portrait=2, tablet landscape=3
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet && isLandscape) return 3;
    if (isTablet || isLandscape) return 2;
    return 1;
  }

  /// FeatureCard grid columns on home page
  int get featureGridColumns {
    if (isDesktop || (isTablet && isLandscape)) return 2;
    if (isTablet || isLandscape) return 2;
    return 1;
  }

  /// Vertical spacing between sections
  double get sectionSpacing => isPhone ? 16 : 24;

  /// Card border radius
  double get cardRadius => isPhone ? 16 : 20;

  /// Whether the route planner should show side-by-side layout
  bool get useSideBySideLayout => isTablet || isDesktop || isLandscape;

  /// Max content width (for centering on wide screens)
  double get maxContentWidth => isDesktop ? 900 : isTablet ? 700 : double.infinity;
}

/// Convenience extension so you can write `context.responsive`
extension ResponsiveExt on BuildContext {
  Responsive get responsive => Responsive(this);
}
