// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.member;

import 'dart:html';

import 'package:dartdoc_viewer/item.dart';
import 'package:polymer/polymer.dart';
import 'app.dart' as app;
import 'viewer.dart';
import 'shared.dart';
import 'package:dartdoc_viewer/location.dart';

class SameProtocolUriPolicy implements UriPolicy {
  final AnchorElement _hiddenAnchor = new AnchorElement();
  final Location _loc = window.location;

  bool allowsUri(String uri) {
    _hiddenAnchor.href = uri;
    // IE leaves an empty protocol for same-origin URIs.
    var older = _hiddenAnchor.protocol;
    var newer = _loc.protocol;
    if ((older == "http:" && newer == "https:")
        || (older == "https:" && newer == "http:")) {
      return true;
    }
    return (older == newer || older == ':');
  }
}

var uriPolicy = new SameProtocolUriPolicy();
var validator = new NodeValidatorBuilder()
    ..allowElement("a", attributes: ["rel"])
    ..allowHtml5(uriPolicy: uriPolicy);

var nullSanitizer = new NullTreeSanitizer();

// TODO(alanknight): Switch to using the validator, verify it doesn't slow
// things down too much, and that it's not disallowing valid content.
/// A sanitizer that allows anything to maximize speed and not disallow any
/// tags.
class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}

//// An abstract class for all Dartdoc elements.
@reflectable abstract class DartdocElement extends PolymerElement {

  DartdocElement.created() : super.created();

  get syntax => defaultSyntax;
  get applyAuthorStyles => true;

  Viewer get viewer => app.viewer;

  enteredView() {
    super.enteredView();
    // Handle clicks and redirect.
    onClick.listen(handleClick);
  }

  var _pathname = window.location.pathname;

  void handleClick(Event e) {
    if (e.target is AnchorElement) {
      var anchor = e.target;
      if (anchor.host == window.location.host
          && anchor.pathname == _pathname && !(e as MouseEvent).ctrlKey) {
        e.preventDefault();
        var location = anchor.hash.substring(1, anchor.hash.length);
        viewer.handleLink(location);
      }
    }
  }
}

//// This is a web component to be extended by all Dart members with comments.
//// Each member has an [Item] associated with it as well as a comment to
//// display, so this class handles those two aspects shared by all members.
@reflectable abstract class MemberElement extends DartdocElement {
  MemberElement.created() : super.created() {
    _item = defaultItem;
  }

  bool wrongClass(newItem);
  Container get defaultItem;
  Container _item;

  @published set item(newItem) {
    if (newItem == null || wrongClass(newItem)) return;
    _item = notifyPropertyChange(#item, _item, newItem);
  }
  @published get item => _item == null ? _item = defaultItem : _item;

  /// A valid string for an HTML id made from this [Item]'s name.
  @observable String idName;

  itemChanged() {
    if (item == null) {
      idName = '';
    } else {
      var loc = item.anchorHrefLocation;
      idName = loc.anchor == null ? '' : loc.anchor;
    }
  }
}

//// A [MemberElement] that could be inherited from another [MemberElement].
@reflectable abstract class InheritedElement extends MemberElement {
  @observable LinkableType inheritedFrom;
  @observable LinkableType commentFrom;
  @observable bool isInherited;
  @observable bool hasInheritedComment;
  @observable bool shouldShowComment;
  @observable bool shouldShowCommentFrom;

  InheritedElement.created() : super.created() {
    registerObserver('isInherited', viewer.changes.listen((changes) {
      for (var c in changes) {
        if (c.name == #isInherited) {
          _update();
          return;
        }
      }
    }));
  }

  itemChanged() {
    super.itemChanged();
    _update();
  }

  _update() {
    if (item == null) return;

    isInherited = item.inheritedFrom != '' && item.inheritedFrom != null;
    inheritedFrom = new LinkableType(
        new DocsLocation(item.inheritedFrom).asHash.withAnchor);
    hasInheritedComment = item.commentFrom != '' && item.commentFrom != null;
    commentFrom = new LinkableType(
        new DocsLocation(item.commentFrom).asHash.withAnchor);

    shouldShowComment = item.hasComment &&
        (!hasInheritedComment || viewer.isInherited);
    shouldShowCommentFrom = item.hasComment &&
        hasInheritedComment && viewer.isInherited;
  }
}
