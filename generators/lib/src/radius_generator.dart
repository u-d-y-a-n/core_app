import 'dart:math';

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

    return generateRadiusClasses(visitor, annotation);
  }

  // Helper function to calculate decimal places based on gap
  int getDecimalPlaces(double gap) {
    return gap.toString().split('.').last.length;
  }

  String generateRadiusClasses(AppVisitor visitor, ConstantReader annotation) {
    final double min = annotation.read('min').doubleValue;
    final double max = annotation.read('max').doubleValue;
    final double gap = annotation.read('gap').doubleValue;

    final buffer = StringBuffer();
    buffer.writeln('sealed class ${visitor.className.substring(1)} {');

    // Generate Radius values
    buffer.writeln('  // Radius Constants');
    final radiusValues = <String>{}; // Use a Set to avoid duplicates
    final decimalPlaces =
        getDecimalPlaces(gap); // Get decimal places based on gap

    for (double value = min; value <= max; value += gap) {
      final roundedValue =
          _roundToDecimalPlaces(value, decimalPlaces: decimalPlaces);
      radiusValues
          .add(_generateRadiusConstant(roundedValue, decimalPlaces, gap));
    }

    buffer.writeln(radiusValues.join('\n  '));

    // Generate BorderRadius constants
    buffer.writeln('\n  // BorderRadius Constants');
    final borderRadiusValues = <String>{}; // Use a Set to avoid duplicates

    const directionMap = {
      'T': 'topLeft',
      'B': 'bottomRight',
      'L': 'bottomLeft',
      'R': 'topRight',
    };

    const combinationSets = [
      ['T'],
      ['B'],
      ['L'],
      ['R'],
      ['T', 'R'],
      ['T', 'L'],
      ['B', 'R'],
      ['B', 'L'],
      ['T', 'R', 'B'],
      ['T', 'L', 'B'],
      ['T', 'L', 'R'],
      ['B', 'L', 'R'],
    ];

    for (double value = min; value <= max; value += gap) {
      final roundedValue =
          _roundToDecimalPlaces(value, decimalPlaces: decimalPlaces);
      for (var direction in directionMap.keys) {
        borderRadiusValues.add(
          _generateSingleBorderRadiusConstant(
              roundedValue, direction, decimalPlaces, gap),
        );
      }

      for (var combination in combinationSets) {
        borderRadiusValues.add(
          _generatePartialBorderRadiusConstant(
              roundedValue, combination, decimalPlaces, gap),
        );
      }

      // New constants for BorderRadius.all and specific direction combinations
      borderRadiusValues.add(
        _generateAllBorderRadiusConstant(roundedValue, decimalPlaces),
      );
      borderRadiusValues.add(
        _generateVerticalBorderRadiusConstant(roundedValue, decimalPlaces),
      );
      borderRadiusValues.add(
        _generateHorizontalBorderRadiusConstant(roundedValue, decimalPlaces),
      );
    }

    buffer.writeln(borderRadiusValues.join('\n  '));
    buffer.writeln('}');

    return buffer.toString();
  }

  // Helper function to round to the desired number of decimal places
  double _roundToDecimalPlaces(double value, {int decimalPlaces = 1}) {
    final factor = pow(10, decimalPlaces);
    return (value * factor).roundToDouble() / factor;
  }

  // Helper to generate Radius name based on the exact value with decimal places and gap
  String _generateRadiusName(double value, {int decimalPlaces = 2}) {
    final roundedValue =
        _roundToDecimalPlaces(value, decimalPlaces: decimalPlaces);

    // If it's a whole number, no need for a decimal part in the name
    if (roundedValue == roundedValue.toInt()) {
      return 'r${roundedValue.toInt()}';
    } else {
      // Otherwise, handle decimal places (e.g., r0p25 for 0.25)
      return 'r${roundedValue.toStringAsFixed(decimalPlaces).replaceAll('.', 'p')}';
    }
  }

  // Generate Radius constant with the correct naming
  String _generateRadiusConstant(double value, int decimalPlaces, double gap) {
    final clampedValue = value.clamp(0.0, double.infinity);
    final name =
        _generateRadiusName(clampedValue, decimalPlaces: decimalPlaces);
    return 'static const Radius $name = Radius.circular($clampedValue);';
  }

  // Generate Single Direction BorderRadius constant with the correct naming
  String _generateSingleBorderRadiusConstant(
      double value, String direction, int decimalPlaces, double gap) {
    final clampedValue = value.clamp(0.0, double.infinity);
    final name =
        _generateRadiusName(clampedValue, decimalPlaces: decimalPlaces);
    const directionMap = {
      'T': 'topLeft',
      'B': 'bottomRight',
      'L': 'bottomLeft',
      'R': 'topRight',
    };

    return '''
static const BorderRadius brOnly$direction$name = BorderRadius.only(
  ${directionMap[direction]}: $name,
);
''';
  }

  // Generate Partial BorderRadius constant with the correct naming
  String _generatePartialBorderRadiusConstant(
      double value, List<String> directions, int decimalPlaces, double gap) {
    final clampedValue = value.clamp(0.0, double.infinity);
    final name =
        _generateRadiusName(clampedValue, decimalPlaces: decimalPlaces);
    const directionMap = {
      'T': 'topLeft',
      'B': 'bottomRight',
      'L': 'bottomLeft',
      'R': 'topRight',
    };

    final corners =
        directions.map((dir) => '${directionMap[dir]}: $name').join(', ');

    final directionName = directions.join();
    return '''
static const BorderRadius brOnly$directionName$name = BorderRadius.only(
  $corners,
);
''';
  }

  // Generate BorderRadius.all constant
  String _generateAllBorderRadiusConstant(double value, int decimalPlaces) {
    final name = _generateRadiusName(value, decimalPlaces: decimalPlaces);
    return '''
static const BorderRadius b$name = BorderRadius.all(
  $name,
);
''';
  }

  // Generate Vertical BorderRadius constants (top and bottom)
  String _generateVerticalBorderRadiusConstant(
      double value, int decimalPlaces) {
    final name = _generateRadiusName(value, decimalPlaces: decimalPlaces);
    return '''
static const BorderRadius brVerticalT$name = BorderRadius.vertical(
  top: $name,
);
static const BorderRadius brVerticalD$name = BorderRadius.vertical(
  bottom: $name,
);
''';
  }

  // Generate Horizontal BorderRadius constants (left and right)
  String _generateHorizontalBorderRadiusConstant(
      double value, int decimalPlaces) {
    final name = _generateRadiusName(value, decimalPlaces: decimalPlaces);
    return '''
static const BorderRadius brHorizontalL$name = BorderRadius.horizontal(
  left: $name,
);
static const BorderRadius brHorizontalR$name = BorderRadius.horizontal(
  right: $name,
);
''';
  }
}
