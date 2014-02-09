// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.page;

import 'package:polymer/polymer.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/member.dart';

/** An HTML representation of a page */
@CustomTag("dartdoc-page")
class PageElement extends DartdocElement {
  @published Item item;
  @observable bool isLibrary;
  @observable bool isMethod;
  @observable bool isClass;
  @observable bool isTypedef;
  @observable bool isHome;

  PageElement.created() : super.created();

  itemChanged() {
    isLibrary = item is Library;
    isMethod = item is Method;
    isClass = item is Class;
    isTypedef = item is Typedef;
    isHome = item is Home;
  }
}
