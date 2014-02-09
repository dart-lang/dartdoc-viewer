// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.category;

import 'package:polymer/polymer.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/app.dart';
import 'package:dartdoc_viewer/member.dart';
import 'dart:html';

/**
 * An HTML representation of a Category.
 *
 * Used as a placeholder for an CategoryItem object.
 */
 @CustomTag("dartdoc-category")
class CategoryElement extends DartdocElement {
  @published Category category;

  // Note: only one of these is used at any given time, the other two will be
  // null. We do it this way to keep the <template if> outside of the
  // <template repeat>, so the repeat is more strongly typed.
  @published ObservableList<Item> items;
  @published ObservableList<Variable> variables;
  @published ObservableList<Method> methods;

  @observable bool hasItems = false;

  @observable String title;
  @observable String stylizedName;

  @observable String accordionStyle;
  @observable String divClass;
  @observable String caretStyle;
  @observable String lineHeight;

  CategoryElement.created() : super.created() {
    registerObserver('viewer', viewer.changes.listen((changes) {
      if (changes.any((c) => c.name == #isDesktop)) {
        _isExpanded = viewer.isDesktop;
      }
    }));
    _isExpanded = viewer.isDesktop;
  }

  bool __isExpanded;
  bool get _isExpanded => __isExpanded;
  set _isExpanded(bool expanded) {
    __isExpanded = expanded;
    accordionStyle = expanded ? '' : 'collapsed';
    divClass = expanded ? 'collapse in' : 'collapse';
    caretStyle = expanded ? '' : 'caret';
    lineHeight = expanded ? 'auto' : '0px';
  }

  void categoryChanged() {
    title = category == null ? '' : category.name;
    stylizedName = category == null ? '' : category.name.replaceAll(' ', '-');
  }

  void itemsChanged() => _updateHasItems();
  void variablesChanged() => _updateHasItems();
  void methodsChanged() => _updateHasItems();

  _updateHasItems() {
    hasItems = items != null && items.isNotEmpty ||
        variables != null && variables.isNotEmpty ||
        methods != null && methods.isNotEmpty;
  }

  hideShow(event, detail, AnchorElement target) {
    _isExpanded = !_isExpanded;
  }
}
