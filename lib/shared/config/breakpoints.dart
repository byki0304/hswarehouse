/// Responsive breakpoints for hswarehouse layout.
class Breakpoints {
  /// Desktop sidebar layout when width >= this value.
  static const double desktop = 769;

  /// Mobile top-nav layout when width < [desktop].
  static const double mobileMax = 768;

  static bool isDesktop(double width) => width >= desktop;
  static bool isMobile(double width) => width < desktop;
}
