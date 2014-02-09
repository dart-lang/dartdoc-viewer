// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.variable;

import 'package:polymer/polymer.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/member.dart';

/**
 * An HTML representation of a Variable.
 */
@CustomTag("dartdoc-variable")
class VariableElement extends InheritedElement {
  @observable AnnotationGroup annotations;

  VariableElement.created() : super.created();

  get defaultItem => _defaultItem;
  static final _defaultItem =
      new Variable({'type' : [null], 'name' : 'loading'});
  wrongClass(newItem) => newItem is! Variable;
}
