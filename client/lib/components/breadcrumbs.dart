// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.breadcrumbs;

import 'package:dartdoc_viewer/item.dart';
import 'package:polymer/polymer.dart';
import 'package:dartdoc_viewer/app.dart';
import 'package:dartdoc_viewer/shared.dart';

@CustomTag('dartdoc-breadcrumbs')
class Breadcrumbs extends PolymerElement {
  @observable List<Item> breadcrumbs;
  @observable Item lastCrumb;

  Breadcrumbs.created() : super.created();

  get syntax => defaultSyntax;
  get applyAuthorStyles => true;

  enteredView() {
    super.enteredView();
    registerObserver('viewer', viewer.changes.listen((changes) {
      for (var change in changes) {
        if (change.name == #currentPage || change.name == #homePage) {
          _updateBreadcrumbs();
          return;
        }
      }
    }));
    _updateBreadcrumbs();
  }

  _updateBreadcrumbs() {
    breadcrumbs = [];
    lastCrumb = null;
    if (viewer.homePage != null && viewer.currentPage != null) {
      for (var p = viewer.currentPage; p != viewer.homePage; p = p.owner) {
        breadcrumbs.add(p);
      }
      breadcrumbs = breadcrumbs.reversed.toList();
      if (breadcrumbs.isNotEmpty) {
        lastCrumb = breadcrumbs.removeLast();
      }
    }

    // Fire an event to tell our parent that we updated, in case it wants to
    // adjust any layout in light of our new size.
    fire('update');
  }
}
