// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.method;

import 'package:polymer/polymer.dart';

import 'package:dartdoc_viewer/member.dart';
import 'package:dartdoc_viewer/item.dart';


@initMethod _init() {
  Polymer.register('method-panel', MethodElement);
  Polymer.register('dartdoc-method', MethodElement);
}

/// Shared type for dartdoc-method and method-panel
@reflectable
class MethodElement extends InheritedElement {
  @observable bool isNotConstructor;
  @observable String modifiers;
  @observable String constantModifier;
  @observable String staticModifier;

  MethodElement.created() : super.created();

  wrongClass(newItem) => newItem is! Method;

  itemChanged() {
    super.itemChanged();
    if (item == null) return;

    isNotConstructor = !item.isConstructor;
    constantModifier = item.isConstant ? 'const' : '';
    staticModifier = item.isStatic ? 'static' : '';
    modifiers = constantModifier + staticModifier;
  }

  get defaultItem => _defaultItem;
  static final _defaultItem = new Method({
    "name" : "Loading",
    "qualifiedName" : "Loading",
    "comment" : "",
    "parameters" : null,
    "return" : [null],
  }, isConstructor: true);
}
