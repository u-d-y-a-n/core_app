class RadiusAnnotation {
  final double min;
  final double max;
  final double gap;

  const RadiusAnnotation({
    required this.min,
    required this.max,
    this.gap = 1.0,
  });
}
