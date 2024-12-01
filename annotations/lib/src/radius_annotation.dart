class RadiusAnnotation {
  final num min;
  final num max;
  final num gap;

  const RadiusAnnotation({
    required this.min,
    required this.max,
    this.gap = 1.0,
  });
}
