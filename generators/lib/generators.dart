library generators;

import 'package:build/build.dart';
import 'package:generators/src/radius_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder generatorMethods(BuilderOptions options) {
  return SharedPartBuilder(
    [RadiusGenerator()],
    'radius_generator',
  );
}
