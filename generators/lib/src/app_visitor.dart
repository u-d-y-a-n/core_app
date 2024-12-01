import 'package:analyzer/dart/element/element.dart'
    show ConstructorElement, FieldElement;
import 'package:analyzer/dart/element/visitor.dart' show SimpleElementVisitor;

class AppVisitor extends SimpleElementVisitor<void> {
  String className = '';
  Map<String, dynamic> fields = {};

  @override
  void visitConstructorElement(ConstructorElement element) {
    final String returnType = element.returnType.toString();
    className = returnType.replaceAll("*", ""); // ClassName* -> ClassName
  }

  @override
  void visitFieldElement(FieldElement element) {
    String elementType = element.type.toString().replaceAll("*", "");
    fields[element.name] = elementType;
  }
}
