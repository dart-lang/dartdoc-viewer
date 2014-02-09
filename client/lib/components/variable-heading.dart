// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.variable_heading;

import 'package:polymer/polymer.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/member.dart';

/** An HTML representation of a Variable. */
@CustomTag("variable-heading")
class VariableHeading extends MemberElement {
  @observable String getter;
  @observable String name;
  @observable bool isNotSetter;

  VariableHeading.created() : super.created();

  get defaultItem => _defaultItem;
  static final _defaultItem =
      new Variable({'type' : [null], 'name' : 'loading'});
  wrongClass(newItem) => newItem is! Variable;

  itemChanged() {
    super.itemChanged();
    if (item == null) return;

    getter = item.isGetter ? 'get ' : '';
    isNotSetter = !item.isSetter;

    final n = item.name;
    name = item.isSetter ? n.substring(0, n.length - 1) : n;
  }
}
