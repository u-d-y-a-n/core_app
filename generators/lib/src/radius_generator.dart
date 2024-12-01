import 'package:analyzer/dart/element/element.dart' show Element;
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'app_visitor.dart';

class RadiusGenerator extends GeneratorForAnnotation<RadiusAnnotation> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final AppVisitor visitor = AppVisitor();
    element.visitChildren(visitor);

    return generateRadiusClass(visitor, annotation);
  }

  String generateRadiusClass(AppVisitor visitor, ConstantReader annotation) {
    final min = annotation.read('min').literalValue as num;
    final max = annotation.read('max').literalValue as num;
    final gap = annotation.read('gap').literalValue as num;

    final radiusValues = <String>[];
    for (num value = min; value <= max; value += gap) {
      final clampedValue = value.clamp(0.0, double.infinity);
      radiusValues.add(
          'static const Radius r${clampedValue.toInt()} = Radius.circular($clampedValue);');
    }

    final buffer = StringBuffer();

    buffer.writeln('sealed class ${(visitor.className).substring(1)} {');
    buffer.writeln(radiusValues.join('\n  '));
    buffer.writeln('}');

    return buffer.toString();
  }
}
