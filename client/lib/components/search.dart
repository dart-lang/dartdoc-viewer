// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web.search;

import 'dart:async';
import 'dart:html';
import 'package:dartdoc_viewer/app.dart';
import 'package:dartdoc_viewer/shared.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/search.dart';
import 'package:dartdoc_viewer/location.dart';
import 'package:polymer/polymer.dart';

/**
 * Component implementing the Dartdoc_viewer search.
 */
@CustomTag("search-box")
class Search extends PolymerElement {
  @published String searchQuery = '';

  @observable bool isFocused = false;
  @observable ObservableList<SearchResult> results = toObservable([]);
  @observable String dropdownOpen;
  int currentIndex = -1;

  Search.created() : super.created();

  get syntax => defaultSyntax;
  get applyAuthorStyles => true;

  void searchQueryChanged() {
    currentIndex = -1;
    results.clear();
    results.addAll(lookupSearchResults(
        searchIndex,
        searchQuery,
        viewer.isDesktop ? 10 : 5,
        locationValidInContext));

    _updateDropdownOpen();
  }

  void _updateDropdownOpen() {
    dropdownOpen = !searchQuery.isEmpty && isFocused ? 'open' : '';
  }

  /// Return true if we consider [location] valid in the current context. This
  /// is used to filter search so that if we're inside a package we will
  /// give search priority to things within that package, or if we're
  /// not showing pkg, we will give lower priority to search results from there.
  bool locationValidInContext(DocsLocation location) {
    var currentContext = viewer.currentPage.home;
    var showPkg = viewer.showPkgLibraries;
    if (currentContext == viewer.homePage) {
      if (viewer.showPkgLibraries) {
        return true;
      } else {
        return location.packageName == null;
      }
    } else {
      return location.packageName == currentContext.name;
    }
  }

  void onBlurCallback(_) {
    isFocused = false;
    new Future.value(null).then((_) => _updateDropdownOpen());
  }

  void onFocusCallback(_) {
    isFocused = true;
  }

  void onSubmitCallback(event, detail, target) {
    if (results.isEmpty) return;

    String refId;
    var actualTarget = event.path.firstWhere(
        (x) => x is Element && x.dataset['ref-id'] != null,
        orElse: () => target);
    refId = actualTarget.dataset['ref-id'];
    if (refId == null || refId.isEmpty) {
      // If nothing is focused, use the first search result.
      refId = results.first.element;
    }
    var newLocation = new LinkableType(refId).location;
    var encoded = Uri.encodeFull(newLocation);
    viewer.handleLink(encoded);
    window.history.pushState(locationPrefixed(encoded),
        viewer.title, locationPrefixed(encoded));
    searchQuery = "";
    results.clear();
  }

  void enteredView() {
    super.enteredView();

    registerObserver('onfocus', Element.focusEvent
        .forTarget(this, useCapture: true).listen(onFocusCallback));

    registerObserver('onblur',  Element.blurEvent
        .forTarget(this, useCapture: true).listen(onBlurCallback));
    registerObserver('onkeydown', onKeyDown.listen(handleUpDown));
    registerObserver('window.onkeydown',
        window.onKeyDown.listen(shortcutHandler));
  }

  void handleUpDown(KeyboardEvent e) {
    if (e.keyCode == KeyCode.UP) {
      if (currentIndex > 0) {
        currentIndex--;
        shadowRoot.querySelector('#search$currentIndex').parent.focus();
      } else if (currentIndex == 0) {
        searchBox.focus();
      }
      e.preventDefault();
    } else if (e.keyCode == KeyCode.DOWN) {
      if (currentIndex < results.length - 1) {
        currentIndex++;
        shadowRoot.querySelector('#search$currentIndex').parent.focus();
      }
      e.preventDefault();
    } else if (e.keyCode == KeyCode.ENTER) {
      onSubmitCallback(e, null,
          shadowRoot.querySelector('#search$currentIndex'));
      e.preventDefault();
    }
  }

  /** Activate search on Ctrl+3, /, and S. */
  void shortcutHandler(KeyboardEvent event) {
    if (event.keyCode == KeyCode.THREE && event.ctrlKey) {
      searchBox.focus();
      event.preventDefault();
    } else if (!isFocused &&
        (event.keyCode == KeyCode.S || event.keyCode == KeyCode.SLASH)) {
      // Allow writing 's' and '/' in the search input.
      searchBox.focus();
      searchBox.select();
      event.preventDefault();
    } else if (event.keyCode == KeyCode.ESC) {
      searchQuery = "";
      searchBox.value = '';
      event.preventDefault();
    }
  }

  get searchBox => shadowRoot.querySelector('#q');
}
