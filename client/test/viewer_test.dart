// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.viewer_test;

import 'package:dartdoc_viewer/data.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/read_yaml.dart';
import 'package:dartdoc_viewer/search.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';
import 'package:polymer/polymer.dart';

// TODO(alanknight): These tests mostly exercise parsing YAML in the expected
// form. Convert them to use JSON, and add tests.

// Since YAML is sensitive to whitespace, these are declared in the top-level
// for readability and to avoid possible parsing errors.
String empty = '';

// The 'value' field is escaped more than normal to
// account for the use of literal strings.
String parameter = '''"name" : "input"
"optional" : "true"
"named" : "true"
"default" : "true"
"type" :
  - "inner" :
    "outer" : "dart.core.String"
"value" : "\\\"test\\\""
"annotations" :''';

String variable = '''"name" : "variable"
"qualifiedName" : "Library.variable"
"comment" : "<p>This is a test comment</p>"
"final" : "false"
"static" : "false"
"constant" : "false"
"type" :
  - "inner" :
    "outer" : "dart.core.String"
"annotations" :''';

String genericOneLevelVariable = '''"name" : "generic"
"qualifiedName" : "Library.generic"
"comment" : "<p>This is a test comment for generic types</p>"
"final" : "false"
"static" : "false"
"constant" : "false"
"type" :
  - "inner" :
      - "inner" :
        "outer" : "dart.core.String"
    "outer" : "dart.core.List"
"annotations" :''';

String genericTwoLevelVariable = '''"name" : "generic"
"qualifiedName" : "Library.generic"
"comment" : "<p>This is a test comment for generic types</p>"
"final" : "false"
"static" : "false"
"constant" : "false"
"type" :
  - "inner" :
      - "inner" :
          - "inner" :
            "outer" : "dart.core.int"
          - "inner" :
            "outer" : "dart.core.String"
        "outer" : "dart.core.Map"
    "outer" : "dart.core.List"
"annotations" :''';

String setter = '''"abstract" : "false"
"annotations" :
"comment" : "<p>This is a setter</p>"
"commentfrom" : ""
"constant" : "false"
"name" : "length="
"parameters" :
  "newLength" :
    "annotations" :
    "default" : "false"
    "name" : "newLength"
    "named" : "false"
    "optional" : "false"
    "type" :
      - "inner" :
        "outer" : "dart.core.int"
    "value" : "null"
"qualifiedName" : "Library.Class.length="
"return" :
  - "inner" :
    "outer" : "void"
"static" : "false"''';

String method =  '''"name" : "getA"
"qualifiedName" : "Library.getA"
"comment" : ""
"static" : "false"
"constant" : "false"
"abstract" : "false"
"annotations" :
"return" :
  - "inner" :
    "outer" : "Library.A"
"parameters" :
  "testInt" :
    "name" : "testInt"
    "optional" : "false"
    "named" : "false"
    "default" : "false"
    "type" :
      - "inner" :
        "outer" : "dart.core.int"
    "value" : "null"
    "annotations" :''';

String clazz = '''"name" : "A"
"qualifiedName" : "Library.A"
"comment" : "<p>This class is used for testing.</p>"
"isAbstract" : "false"
"superclass" : "dart.core.Object"
"implements" :
  - "Library.B"
  - "Library.C"
"variables" :
"annotations" :
"generics" :
"methods" :
  "getters" :
  "setters" :
  "constructors" :
    "" :
      "abstract" : "false"
      "annotations" :
      "comment" :
      "commentfrom" : ""
      "constant" : "false"
      "name" : ""
      "parameters" :
      "qualifiedName" : "Library.A."
      "return" :
        - "inner" :
          "outer" : "Library.A"
      "static" : "false"
  "operators" :
  "methods" :
    "doAction" :
      "name" : "doAction"
      "qualifiedName" : "Library.A.doAction"
      "comment" : "<p>This is a test comment</p>."
      "static" : "true"
      "constant" : "false"
      "abstract" : "false"
      "annotations" :
      "return" :
        - "inner" :
          "outer" : "void"
      "parameters" :''';

String library = '''"name" : "Library"
"qualifiedName" : "Library"
"comment" : "<p>This is a library.</p>"
"variables" :
"functions" :
"annotations" :
"classes" :
  "class" :
    - "name" : "Library.A"
      "preview" : "<p>This is a preview comment</p>"
  "error" :
  "typedef" :''';

// A string of YAML with return types that are in scope for testing links.
String dependencies =  '''"name" : "Library"
"qualifiedName" : "Library"
"annotations" :
"comment" : "<p>This is a library.</p>"
"variables" :
  "variable" :
    "name" : "variable"
    "qualifiedName" : "Library.variable"
    "comment" : "<p>This is a test comment</p>"
    "final" : "false"
    "static" : "false"
    "constant" : "false"
    "type" :
      - "inner" :
        "outer" : "Library.A"
    "annotations" :
"functions" :
  "setters" :
  "getters" :
  "constructors" :
  "operators" :
  "methods" :
    "changeA" :
      "name" : "changeA"
      "qualifiedName" : "Library.changeA"
      "comment" : ""
      "constant" : "false"
      "static" : "false"
      "abstract" : "false"
      "return" :
        - "inner" :
          "outer" : "Library.A"
      "parameters" :
        "testA" :
          "name" : "testA"
          "annotations" :
          "optional" : "false"
          "named" : "false"
          "default" : "false"
          "type" :
            - "inner" :
              "outer" : "Library.A"
          "value" : "null"
      "annotations" :
"classes" :
  "class" :
    - "name" : "A"
      "qualifiedName" : "Library.A"
    - "name" : "B"
      "qualifiedName" : "Library.B"
    - "name" : "C"
      "qualifiedName" : "Library.C"''';

String annotationsAndGenerics = '''"name" : "Library"
"qualifiedName" : "Library"
"comment" : "<p>This is an annotation test</p>"
"variables" :
  "generic" :
    "name" : "generic"
    "qualifiedName" : "Library.generic"
    "comment" : "<p>This is a test comment for generic types</p>"
    "final" : "false"
    "static" : "false"
    "constant" : "false"
    "type" :
      - "inner" :
          - "inner" :
              - "inner" :
                "outer" : "Library.A"
              - "inner" :
                "outer" : "Library.A"
            "outer" : "Library.B"
        "outer" : "Library.C"
    "annotations" :
  "variable" :
    "name" : "variable"
    "qualifiedName" : "Library.variable"
    "comment" : ""
    "final" : "false"
    "static" : "false"
    "constant" : "false"
    "type" :
      - "inner" :
        "outer" : "Library.A"
    "annotations" :
      - "name" : "Library.B"
        "parameters" :
          - "firstParameter"
          - "secondParameter"
      - "name" : "Library.A"
        "parameters" :
"functions" :
  "setters" :
  "getters" :
  "constructors" :
  "operators" :
  "methods" :
"classes" :
  "class" :
    - "name" : "A"
      "qualifiedName" : "Library.A"
    - "name" : "B"
      "qualifiedName" : "Library.B"
    - "name" : "C"
      "qualifiedName" : "Library.C"
  "error" :
  "typedef" :''';

String clazzA = '''"name" : "A"
"qualifiedName" : "Library.A"
"isAbstract" : "false"
"annotations" :
"generics" :
"comment" : ""
"superclass" : "Library.B"
"implements" :
  - "Library.B"
"inheritedVariables" :
  "inheritance" :
    "name" : "inheritance"
    "qualifiedName" : "Library.B.inheritance"
    "comment" : "<p>Comment for Library.B.inheritance</p>"
    "commentFrom" : ""
    "final" : "false"
    "static" : "false"
    "constant" : "false"
    "type" :
      - "inner" :
        "outer" : "dart.core.String"
    "annotations" :
"variables" :
  "inheritance" :
    "name" : "inheritance"
    "qualifiedName" : "Library.A.inheritance"
    "comment" : ""
    "final" : "false"
    "static" : "false"
    "constant" : "false"
    "type" :
      - "inner" :
        "outer" : "dart.core.String"
    "annotations" :
"methods" :
  "constructors" :
  "getters" :
  "methods" :
    "getA" :
      "name" : "getA"
      "qualifiedName" : "Library.A.getA"
      "comment" : ""
      "static" : "false"
      "constant" : "false"
      "abstract" : "false"
      "annotations" :
      "return" :
        - "inner" :
          "outer" : "Library.B"
      "parameters" :
        "testInt" :
          "name" : "testInt"
          "optional" : "false"
          "named" : "false"
          "default" : "false"
          "type" :
            - "inner" :
              "outer" : "Library.C"
          "value" : "null"
          "annotations" :
  "operators" :
  "setters" :''';

String clazzB = '''"name" : "B"
"qualifiedName" : "Library.B"
"annotations" :
"isAbstract" : "true"
"generics" :
"comment" : ""
"superclass" : "dart.core.Object"
"implements" :
"variables" :
  "inheritance" :
    "name" : "inheritance"
    "qualifiedName" : "Library.B.inheritance"
    "comment" : "<p>Comment for Library.B.inheritance</p>"
    "final" : "false"
    "static" : "false"
    "constant" : "false"
    "type" :
      - "inner" :
        "outer" : "dart.core.String"
    "annotations" :
"methods" :''';

String clazzC =  '''"name" : "C"
"qualifiedName" : "Library.C"
"annotations" :
"isAbstract" : "true"
"generics" :
"comment" : ""
"superclass" : "Library.A"
"implements" :
"inheritedVariables" :
  "inheritance" :
    "name" : "inheritance"
    "qualifiedName" : "Library.A.inheritance"
    "comment" : "<p>Comment for Library.B.inheritance</p>"
    "commentFrom" : "Library.B.inheritance"
    "final" : "false"
    "static" : "false"
    "constant" : "false"
    "type" :
      - "inner" :
        "outer" : "dart.core.String"
    "annotations" :
"variables" :
"methods" :''';

String manyLibrariesIndex = '''dart.core library
dart.core.Object class
dart.core.Object.toString method
dart.core.Object.runtimeType getter
dart.core.Object.hashCode method
dart.core.List class
dart.core.int class
dart.core.String class
dart.core.num class
dart.core.num.isNaN getter
dart.core.num.isNegative getter
dart.collection library
dart.collection.LinkedList class
dart.collection.LinkedList.forEach method
dart.collection.HashSet class
dart.mirrors library
dart.mirrors.Mirror class
dart.dom.svg library
dart.dom.svg.Number class''';

String oneLibraryIndex = '''Library1 library
Library1.function method
Library1.variable property
Library1.Class class
Library1.Class.method method
Library1.Class.variable property
Library1.Class. constructor
Library1.Class.from constructor''';

@initMethod void main() {
  isYaml = true;
  useHtmlConfiguration();

  test('read_empty', () {
    // Check that read_yaml reads the right data.
    retrieveFileContents('yaml/empty.yaml').then(expectAsync((data) {
      expect(_fixYamlString(data), empty);
      // Test that reading in an empty file doesn't throw an exception.
      expect(() => loadData(data), returnsNormally);
    }));
  });

  test('parameter_test', () {
    // Check that read_yaml reads the right data.
    retrieveFileContents('yaml/parameter.yaml').then(expectAsync((data) {
      expect(_fixYamlString(data), parameter);
    }));

    var currentMap = loadYaml(parameter);
    var item = new Parameter(currentMap['name'], currentMap);
    expect(item is Parameter, isTrue);
    expect(item.name is String, isTrue);
    expect(item.type is NestedType, isTrue);
    expect(item.annotations is AnnotationGroup, isTrue);
  });

  test('variable_test', () {
    // Check that read_yaml reads the right data.
    retrieveFileContents('yaml/variable.yaml').then(expectAsync((data) {
      expect(_fixYamlString(data), variable);
    }));

    var yaml = loadYaml(variable);
    var item = new Variable(yaml);
    expect(item is Variable, isTrue);
    expect(item.annotations is AnnotationGroup, isTrue);
    expect(item.comment is String, isTrue);
    expect(item.setterParameter, isNull);
    expect(item.type is NestedType, isTrue);
  });

  test('setter_test', () {
    var currentMap = loadYaml(setter);
    var item = new Variable(currentMap, isSetter: true);
    expect(item is Variable, isTrue);
    expect(item.annotations is AnnotationGroup, isTrue);
    expect(item.comment is String, isTrue);
    expect(item.type is NestedType, isTrue);

    expect(item.setterParameter is Parameter, isTrue);
    var parameter = item.setterParameter;
    expect(parameter.type is NestedType, isTrue);
    expect(parameter.annotations is AnnotationGroup, isTrue);
  });

  // A test for A<B> type generic links.
  test('one_level_generic_variable_test', () {
    var currentMap = loadYaml(genericOneLevelVariable);
    var item = new Variable(currentMap);
    expect(item is Variable, isTrue);
    expect(item.type is NestedType, isTrue);

    var returnType = item.type;
    expect(returnType.outer is LinkableType, isTrue);
    expect(returnType.inner is List<NestedType>, isTrue);

    var innerType = returnType.inner.first;
    expect(innerType.outer is LinkableType, isTrue);
    expect(innerType.inner is List<NestedType>, isTrue);
    expect(innerType.inner, isEmpty);
  });

  // A test for A<B<C,D>> type generic links.
  test('two_level_generic_variable_test', () {
    var currentMap = loadYaml(genericTwoLevelVariable);
    var item = new Variable(currentMap);
    expect(item is Variable, isTrue);
    expect(item.type is NestedType, isTrue);

    var returnType = item.type;
    expect(returnType.outer is LinkableType, isTrue);
    expect(returnType.inner is List<NestedType>, isTrue);

    var innerType = returnType.inner.first;
    expect(innerType.outer is LinkableType, isTrue);
    expect(innerType.inner is List<NestedType>, isTrue);

    var firstInner = innerType.inner.first;
    expect(firstInner, isNotNull);
    expect(firstInner is NestedType, isTrue);
    expect(firstInner.inner is List<NestedType>, isTrue);
    expect(firstInner.inner, isEmpty);
    expect(firstInner.outer is LinkableType, isTrue);

    var secondInner = innerType.inner[1];
    expect(secondInner, isNotNull);
    expect(secondInner is NestedType, isTrue);
    expect(secondInner.inner is List<NestedType>, isTrue);
    expect(secondInner.inner, isEmpty);
    expect(secondInner.outer is LinkableType, isTrue);
  });

  test('method_test', () {
    // Check that read_yaml reads the right data.
    retrieveFileContents('yaml/method.yaml').then(expectAsync((data) {
      expect(_fixYamlString(data), method);
    }));

    var yaml = loadYaml(method);
    var item = new Method(yaml);
    expect(item is Method, isTrue);

    expect(item.type is NestedType, isTrue);
    expect(item.parameters is List, isTrue);
    expect(item.parameters.first is Parameter, isTrue);
    expect(item.parameters.first.type is NestedType, isTrue);
  });

  test('clazz_test', () {
    // Check that read_yaml reads the right data.
    retrieveFileContents('yaml/class.yaml').then(expectAsync((data) {
      expect(_fixYamlString(data), clazz);
    }));

    var yaml = loadYaml(clazz);
    var item = new Class(yaml);
    expect(item is Class, isTrue);

    expect(item.variables is Category, isTrue);
    expect(item.operators is Category, isTrue);
    expect(item.constructs is Category, isTrue);
    expect(item.functions is Category, isTrue);

    var functions = item.functions;
    expect(functions.content.first is Method, isTrue);

    var method = functions.content.first;
    expect(method.type is NestedType, isTrue);

    var constructor = item.constructs.content.first;
    expect(constructor is Method, isTrue);
    expect(constructor.isConstructor, isTrue);
    expect(constructor.decoratedName != constructor.name, isTrue);

    for (var interface in item.interfaces) {
       expect(interface is LinkableType, isTrue);
    }

    expect(item.superClass is LinkableType, isTrue);
  });

  test('library_test', () {
    // Check that read_yaml reads the right data.
    retrieveFileContents('yaml/library.yaml').then(expectAsync((data) {
      expect(_fixYamlString(data), library);
    }));

    var yaml = loadYaml(library);
    // Manually instantiated Library object from yaml.
    var itemManual = new Library(yaml);
    expect(itemManual is Library, isTrue);

    // Automatically instantiated Library object from loadData in read_yaml.
    var itemAutomatic = loadData(library);
    expect(itemAutomatic is Library, isTrue);

    // Test that the same results are produced.
    expect(itemAutomatic.name, equals(itemManual.name));
    expect(itemAutomatic.comment, equals(itemManual.comment));
    expect(itemAutomatic.classes.content.length,
        equals(itemManual.classes.content.length));

    expect(itemManual.classes is Category, isTrue);
    expect(itemManual.errors is Category, isTrue);
    expect(itemManual.typedefs is Category, isTrue);
    expect(itemManual.variables is Category, isTrue);
    expect(itemManual.functions is Category, isTrue);
    expect(itemManual.operators is Category, isTrue);

    var clazz = itemManual.classes.content.first;
    expect(clazz is Class, isTrue);
    clazz.loadValues(loadYaml(clazzA));

    for (var element in clazz.interfaces) {
      expect(element is LinkableType, isTrue);
    }
  });

  // Test that links that are in scope are aliased to the correct objects.
  test('dependencies_test', () {
    var currentMap = loadYaml(dependencies);
    var library = new Library(currentMap);

    var classes = library.classes;
    var variables = library.variables;
    var functions = library.functions;

    var variable = variables.content.first;
    var classA, classB, classC;
    classes.content.forEach((element) {
      if (element.name == 'A') classA = element;
      if (element.name == 'B') classB = element;
      if (element.name == 'C') classC = element;
    });
    var function = functions.content.first;

    expect(classA.isLoaded, isFalse);
    expect(classB.isLoaded, isFalse);
    expect(classC.isLoaded, isFalse);

    classA.loadValues(loadYaml(clazzA));
    classB.loadValues(loadYaml(clazzB));
    classC.loadValues(loadYaml(clazzC));

    // Test that the destination of the links are aliased with the right class.
    var location = pageIndex[variable.type.outer.location];
    expect(location, equals(classA));

    location = pageIndex[function.type.outer.location];
    expect(location, equals(classA));

    var parameter = function.parameters.first;
    location = pageIndex[parameter.type.outer.location];
    expect(location, equals(classA));

    var interfaces = classA.interfaces.first;
    location = pageIndex[interfaces.location];
    expect(location, equals(classB));

    var superClass = classC.superClass;
    location = pageIndex[superClass.location];
    expect(location, equals(classA));
  });

  // Test that search returns the desired members
  test('many_library_index_search_test', () {
    var searchIndex = new SearchIndex();
    var index = searchIndex.map;
    var members = manyLibrariesIndex.split('\n');
    members.forEach((element) {
      var splitElements = element.split(' ');
      index[splitElements[0]] = splitElements[1];
    });

    var results = lookupSearchResults(searchIndex, 'dart', 10);
//    // Expect the top 4 results to be libraries.
//    // TODO(alanknight): This is no longer true, and it's not clear
//    // if it ought to be. Revisit search algorithm and test.
//    for (int i = 0; i < 4; i++) {
//      expect(index.map[results[i].element], equals('library'));
//    }

    results = lookupSearchResults(searchIndex, 'object', 10);
    expect(results[0].element, equals('dart.core.Object'));
    for (int i = 1; i < 4; i++) {
      expect(results[i].element.startsWith('dart.core.Object.'), isTrue);
      expect(results[i].score, equals(results[1].score));
    }
  });

  // Test that annotations link to the proper classes.
  test('annotation_link_test', () {
    var currentMap = loadYaml(annotationsAndGenerics);
    var library = new Library(currentMap);

    var variable = library.variables.content.firstWhere((item) =>
        item.name == 'variable');
    var firstAnnotation = variable.annotations.annotations.first;
    var secondAnnotation = variable.annotations.annotations[1];

    var classA, classB;
    library.classes.content.forEach((element) {
      if (element.name == 'A') classA = element;
      if (element.name == 'B') classB = element;
    });
    classA.loadValues(loadYaml(clazzA));
    classB.loadValues(loadYaml(clazzB));

    expect(pageIndex[firstAnnotation.link.location], equals(classA));
    expect(pageIndex[secondAnnotation.link.location], equals(classB));

    expect(firstAnnotation.parameters, isEmpty);
  });

  // Test that generic types link to the proper types.
  test('generic_type_test', () {
    var currentMap = loadYaml(annotationsAndGenerics);
    var library = new Library(currentMap);

    var variable = library.variables.content.firstWhere((item) =>
        item.name == 'generic');
    var type = variable.type;

    var classA, classB, classC;
    library.classes.content.forEach((element) {
      if (element.name == 'A') classA = element;
      if (element.name == 'B') classB = element;
      if (element.name == 'C') classC = element;
    });

    var outer = type.outer;
    expect(pageIndex[outer.location], equals(classC));
    var inner = type.inner;
    type = inner.first;
    expect(pageIndex[type.outer.location], equals(classB));
    inner = type.inner;
    type = inner.first;
    expect(pageIndex[type.outer.location], equals(classA));
    expect(type.inner, isEmpty);
    type = inner[1];
    expect(pageIndex[type.outer.location], equals(classA));
    expect(type.inner, isEmpty);
  });

  // Test that member paths are correct.
  test('breadcrumbs_test', () {
    var currentMap = loadYaml(dependencies);
    var library = new Library(currentMap);

    expect(library.path[0], equals(library));
    expect(library.path.length, equals(1));

    var classA, classB, classC;
    library.classes.content.forEach((element) {
      if (element.name == 'A') classA = element;
      if (element.name == 'B') classB = element;
      if (element.name == 'C') classC = element;
    });
    classA.loadValues(loadYaml(clazzA));
    buildHierarchy(classA, classA);

    expect(classA.path[0], equals(library));
    expect(classA.path[1], equals(classA));

    var method = classA.functions.content.first;

    expect(method.path[0], equals(library));
    expect(method.path[1], equals(classA));
    expect(method.path[2], equals(method));

    expect(classB.path[0], equals(library));
    expect(classB.path[1], equals(classB));

    expect(classC.path[0], equals(library));
    expect(classC.path[1], equals(classC));

    method = library.functions.content.first;

    expect(method.path[0], equals(library));
    expect(method.path[1], equals(method));
  });

  // Test that methods, variables, and comments are inherited
  // correctly from public superclasses.
  test('inheritance_test', () {
    var currentMap = loadYaml(dependencies);
    var library = new Library(currentMap);

    var classA, classB, classC;
    library.classes.content.forEach((element) {
      if (element.name == 'A') classA = element;
      if (element.name == 'B') classB = element;
      if (element.name == 'C') classC = element;
    });
    classA.loadValues(loadYaml(clazzA));
    buildHierarchy(classA, classA);

    classB.loadValues(loadYaml(clazzB));
    buildHierarchy(classB, classB);

    classC.loadValues(loadYaml(clazzC));
    buildHierarchy(classC, classC);

    var inheritanceA = classA.variables.content.first;
    var inheritanceB = classB.variables.content.first;
    var inheritanceC = classC.variables.content.first;

    expect(inheritanceA.comment, equals(inheritanceB.comment));
    expect(inheritanceC.comment, equals(inheritanceB.comment));

    expect(inheritanceC.commentFrom, equals(inheritanceB.qualifiedName));
  });

  // Test that search returns the desired members
  test('many_library_index_search_test', () {
    var searchIndex = new SearchIndex();
    var index = searchIndex.map;
    var members = manyLibrariesIndex.split('\n');
    members.forEach((element) {
      var splitElements = element.split(' ');
      index[splitElements[0]] = splitElements[1];
    });

    var results = lookupSearchResults(searchIndex, 'dart', 10);
    // Expect the top 4 results to be libraries.
    // TODO(alanknight) : This is no longer true, and it's not clear
    // if it ought to be. Revisit search algorithm and tests.
//    for (int i = 0; i < 4; i++) {
//      expect(index.map[results[i].element], equals('library'));
//    }

    results = lookupSearchResults(searchIndex, 'object', 10);
    expect(results[0].element, equals('dart.core.Object'));
    for (int i = 1; i < 4; i++) {
      expect(results[i].element.startsWith('dart.core.Object.'), isTrue);
      expect(results[i].score, equals(results[1].score));
    }
  });

  // Test searching with a single library in the index.
  test('search_single_library_test', () {
    var searchIndex = new SearchIndex();
    var index = searchIndex.map;
    var members = oneLibraryIndex.split('\n');
    members.forEach((element) {
      var splitElements = element.split(' ');
      index[splitElements[0]] = splitElements[1];
    });

    var results = lookupSearchResults(searchIndex, 'Class.from', 2);
    expect(results.length, equals(2)); // Returns the constructor and the class.
    expect(results[0].element, equals('Library1.Class.from'));
    expect(results[1].element, equals('Library1.Class'));

    results = lookupSearchResults(searchIndex, 'Class', 6);
    expect(results[0].element, equals('Library1.Class'));
    expect(results.any((x) => x.element == 'Library1.Class.'), isTrue);
    expect(results.length, equals(5));
    expect(results[2].score, equals(results[3].score));
    expect(results[3].score, equals(results[4].score));

    results = lookupSearchResults(searchIndex, 'variable', 2);
    var expected = ['Library1.variable', 'Library1.Class.variable'];
    expect(expected.contains(results[0].element), isTrue);
    expect(expected.contains(results[1].element), isTrue);

    results = lookupSearchResults(searchIndex, 'method', 2);
    expect(results[0].element, equals('Library1.Class.method'));
    expect(results.length, equals(1));

    results = lookupSearchResults(searchIndex, 'Library', 9);
    expect(results[0].element, equals('Library1'));
    expect(results[1].element, equals('Library1.Class'));
    // The remaining results should all have the same score.
    for (int i = 3; i < results.length; i++) {
      expect(results[i].score, equals(results[2].score));
    }
    expect(results.length, equals(8));
  });
}

/// Our YAML literals avoid trailing whitespace. Remove it from loaded files so
/// they match.
String _fixYamlString(String str) => str.replaceAll(' \n', '\n');
