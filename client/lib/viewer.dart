// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library viewer;

import 'dart:async';
import 'dart:convert';
import 'dart:html' show Element, querySelector, window, ScrollAlignment,
    Event, AnchorElement;


import 'package:polymer/polymer.dart';
import 'package:dartdoc_viewer/data.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/location.dart';
import 'package:dartdoc_viewer/read_yaml.dart';
import 'package:dartdoc_viewer/search.dart';
import 'shared.dart';

/// The Dartdoc Viewer application state.
class Viewer extends Observable {

  @observable bool isDesktop;

  final Completer _finishedCompleter = new Completer();

  Future get finished => _finishedCompleter.future;

  /// The homepage from which every [Item] can be reached.
  @observable Home homePage;

  /// The page we should display first and which we go back to if
  /// there's an error and we can't find any sub-page. By default
  /// this is the same as the homePage, but if we're showing
  /// docs for a package, it may be different.
  @observable Item startPage;

  bool _showPkgLibraries = false;
  @observable bool get showPkgLibraries => _showPkgLibraries;
  @observable set showPkgLibraries(bool newValue) {
    if (_showPkgLibraries == newValue) return;

    _showPkgLibraries = notifyPropertyChange(#showPkgLibraries,
        _showPkgLibraries, newValue);

    _updateLibraries();
  }

  @observable List libraries;

  _updateLibraries() {
    if (currentPage == null) {
      libraries = [];
    } else {
      libraries = currentPage.home.libraries;
      if (!showPkgLibraries) {
        libraries = libraries.where((x) => x is Library).toList();
      }
    }
  }

  Item _currentPage;

  /// The current page being shown. An Item.
  @observable Item get currentPage => _currentPage;
  @observable set currentPage(Item newPage) {
    if (_currentPage == newPage) return;

    _currentPage = notifyPropertyChange(#currentPage, _currentPage, newPage);
    _updateLibraries();
  }

  // TODO(jmesserly): split this into the preference and the computed value
  // (we only take the preference into account when in desktop mode)
  /// State for whether or not the library list panel should be shown.
  @observable bool isPanel = true;
  bool _isPanel = true;

  /// State for whether or not the minimap panel should be shown.
  @observable bool isMinimap = true;
  bool _isMinimap = true;

  /// State for whether or not inherited members should be shown.
  @observable bool isInherited = true;

  /// Should members inherited from Object be shown.
  @observable bool showObjectMembers = false;

  Filter get filter => new Filter()
    ..showInherited = isInherited
    ..showObjectMembers = showObjectMembers;

  /// The current element on the current page being shown (e.g. #dartdoc-top).
  String _hash;

  /// The current member on the current page being shown (e.g. #id_created).
  /// This will be empty if we simply want to select the library or class.
  String get activeMember => _hash;

  // Private constructor for singleton instantiation.
  Viewer() {
    var manifest = retrieveFileContents(sourcePath);
    var libraryFuture = manifest.then((response) {
      var libraries = JSON.decode(response);
      isYaml = libraries['filetype'] == 'yaml';
      homePage = new Home(libraries);
      var startPageName = libraries['startPage'];
      startPage = startPageName == null ? homePage :
          homePage.memberNamed(startPageName, orElse: () => homePage);
    });
    var indexFuture = retrieveFileContents('docs/index.json').then(
        (String json) {
            searchIndex.map = JSON.decode(json);
         });

    Future.wait([libraryFuture, indexFuture]).then((_) {
      _finishedCompleter.complete();
    });

    _updateDesktopMode(null);
    window.onResize.listen(_updateDesktopMode);
  }

  _updateDesktopMode(_) {
    isDesktop = window.innerWidth > DESKTOP_SIZE_BOUNDARY;
    isMinimap = isDesktop && _isMinimap;
    isPanel = isDesktop && _isPanel;
  }

  /// The title of the current page.
  String get title => currentPage == null ? '' : currentPage.decoratedName;

  /// Scrolls the screen to the correct member if necessary.
  void _scrollScreen(String hash) {
    if (hash == null || hash == '') {
      Timer.run(() {
        window.scrollTo(0, 0);
      });
    } else {
      Timer.run(() {
        // All ids are created using getIdName to avoid creating an invalid
        // HTML id from an operator or setter.
        hash = hash.substring(1, hash.length);
        var e = queryEverywhere(dartdocMain, hash);

        if (e != null) {
          e.scrollIntoView();
          // The navigation bar at the top of the page is 60px wide,
          // so scroll down 60px once the browser scrolls to the member.
          window.scrollBy(0, -80);
          // TODO(alanknight): The focus only shows up the element if it's
          // a link, e.g. classes. It would be nice to highlight sub-members
          e.focus();
        }
      });
    }
  }

  /// Query for an element by [id] in [parent] and in all the shadow
  /// roots. If it's not found, return [null].
  Element queryEverywhere(Element parent, String id) {
    if (parent.id == id) return parent;
    var shadowChildren =
        parent.shadowRoot != null ? parent.shadowRoot.children : const [];
    var allChildren = [parent.children, shadowChildren]
        .expand((x) => x);
    for (var e in allChildren) {
      var found = queryEverywhere(e, id);
      if (found != null) return found;
    }
    return null;
  }

  /// We are given a page and a location which is either the same or a
  /// reference to some anchor within that page. Make sure they are valid
  /// and return a List of (page, location) which may have been modified.
  List _pageAndLocationFor(Item page, DocsLocation location) {
    // Fall back to home if we haven't found anything at all. This should
    // only happen on an invalid initial page or to terminate recursion.
    if (location.isEmpty || location == homePage.location) {
       return [startPage, startPage.location];
    }

    var usablePage = page.firstItemUsableAsPage;

    // Page and location match exactly.
    var canonicalLocation = location.asMemberOrSubMemberNotAnchor;
    var matchingItem = canonicalLocation.exactItem(homePage);
    if (usablePage == matchingItem) return [usablePage, location];

    // No matching item, try the parent location.
    if (matchingItem == null) {
      return _pageAndLocationFor(usablePage, canonicalLocation.parentLocation);
    }

    // Location is a sub-element of page.
    if (matchingItem.isOwnedBy(usablePage)) {
      return [usablePage, matchingItem.anchorHrefLocation];
    }

    // Location seems to be junk. Find the first valid parent and use its page.
    var validParent = location.firstValidParent(homePage);
    return [validParent.exactItem(homePage), location];
  }

  /// Updates [currentPage] to be [page].
  Future _updatePage(Item page, DocsLocation location) {
    var replacement = _pageAndLocationFor(page, location);
    var newPage = replacement.first;
    var newLocation = replacement.last;
    if (page != newPage || location != newLocation) {
      return handleLink(_replaceLocation(newLocation));
    }

    // Avoid reloading the page if it isn't necessary.
    if (page != null && page != currentPage) {
      var main = window.document.querySelector("#dartdoc-main");
      main.hideOrShowNavigation(hide: true);
      currentPage = page;
    }
    _hash = location.anchorPlus;
    _scrollScreen(location.anchorPlus);
    return new Future.value(true);
  }

  /// Rewrite the location to correspond to something that exists. We
  /// rewrite bottom-level member references from e.g. class.method to
  /// class@id_method.
  DocsLocation _rewriteLocation(DocsLocation location) {
    if (location.subMemberName == null) return location;
    var newLocation = new DocsLocation(location.parentQualifiedName);
    newLocation.anchor = newLocation.toHash(location.subMemberName);
    return newLocation;
  }

  /// Replace the window location with [location]
  String _replaceLocation(DocsLocation location) {
    var newUri = location.withAnchor;
    var encoded = Uri.encodeFull(newUri);
    window.location.replace(locationPrefixed(encoded));
    return encoded;
  }

  /// Loads the [libraryName] [Library] and [className] [Class] if necessary
  /// and updates the current page to the member described by [location]
  /// once the correct member is found and loaded.
  Future _loadAndUpdatePage(DocsLocation location) {
    // If it's loaded, it will be in the index.
    var destination = pageIndex[location.withoutAnchor];
    if (destination == null) {
      var newLocation = _rewriteLocation(location);
      if (newLocation != location) {
        return handleLink(_replaceLocation(newLocation));
      } else {
        return getItem(location).then((items) =>
            _updatePage(location.itemFromList(items.toList()), location));
      }
    } else {
      return destination.load().then((_) => _updatePage(destination, location));
    }
  }

  /// Find the item corresponding to this location
  Future getItem(DocsLocation location) =>
    getLibrary(location)
      .then((lib) =>
          getMember(lib, location))
      .then((libWithMember) =>
          getSubMember(libWithMember, location));

  // All libraries should be in [pageIndex], but may not be loaded.
  // TODO(alanknight): It would be nice if this could all be methods on
  // Location, but it doesn't have access to the lookup context right now.
  /// Return a future for the given item, ensuring that it and all its
  /// parent items are loaded.
  Future<Item> getLibrary(DocsLocation location) {
    var lib = pageIndex[location.libraryQualifiedName];
    // If we can't find the name in the pageIndex, look through the home
    // to see if we can find it there, searching by displayed name. Mostly
    // important to find things like dart:html, which is really dart-dom-html
    if (lib == null) {
      lib = homePage.memberNamed(location.libraryName);
    }
    if (lib == null) return new Future.value(homePage);
    return lib.load();
  }

  Future<List<Item>> getMember(lib, DocsLocation location) {
    if (lib == null) return new Future.value(null);
    var member = lib.memberNamed(location.memberName);
    if (member == null) return new Future.value([lib, null]);
    if (member is Class) {
      // Load all interfaces and superclasses, too, so our parameter links are
      // correct.
      // TODO(efortuna): All of this can be avoided if we resolve links after
      // we've added the inherited methods? As it is, the methods are there,
      // but the comments aren't correctly resolved without our help.
      return member.load().then((Class mem) {
        var interfaces = [];
        for (LinkableType iface in mem.interfaces) {
          interfaces.add(getMember(lib, iface.loc));
        }
        return Future.wait(interfaces).then((loaded) {
          if (mem.superClass.loc.memberName != 'Object') {
            return getMember(lib, mem.superClass.loc).then(
                (_) => [lib, member]) ;
          } else {
            return new Future.value([lib, member]);
          }
        });
      });
    } else {
      return member.load().then((mem) => new Future.value([lib, member]));
    }
  }

  Future<List<Item>> getSubMember(List libWithMember, DocsLocation location) {
    if (libWithMember == null) return new Future.value([]);
    if (libWithMember.last == null) {
      return new Future.value([libWithMember.first]);
    }
    return new Future.value(_concat(libWithMember,
      [libWithMember.last.memberNamed(location.subMemberName)]));
  }

  /// Looks for the correct [Item] described by [location]. If it is found,
  /// [currentPage] is updated and state is not pushed to the history api.
  /// Returns a [Future] to determine if a link was found or not.
  /// [location] is a [String] path to the location (either a qualified name
  /// or a url path).
  Future handleLink(String uri) {
    // Links are the hash part of the URI without the leading #.
    // Valid forms for links are
    // home - the global home page
    // library.memberName.subMember@anchor
    // where @anchor is optional and library can be any of
    // dart:library, library-foo, package-foo/library-bar
    // So we need an unambiguous form.
    // [package/]libraryWithDashes[.class.method]@anchor

    // We will tolerate colons in the location instead of dashes, though
    var decoded = Uri.decodeFull(uri);
    var location = new DocsLocation(decoded);

    if (location.libraryName == 'home') {
      _updatePage(homePage, location);
      return new Future.value(true);
    }
    showLoadIndicator();
    return _loadAndUpdatePage(location)..whenComplete(hideLoadIndicator);
    // TODO(alanknight) : This is now letting the history automatically
    // update, even for non-found items. Is that an issue?
  }

  /// Toggles the library panel
  void togglePanel() {
    _isPanel = !_isPanel;
    isPanel = isDesktop && _isPanel;
  }

  /// Toggles the minimap panel
  void toggleMinimap() {
    _isMinimap = !_isMinimap;
    isMinimap = isDesktop && _isMinimap;
  }

  void togglePkg() {
    showPkgLibraries = !showPkgLibraries;
  }

  /// Toggles showing inherited members.
  void toggleInherited() {
    isInherited = !isInherited;
  }

  /// Toggles showing members inherited from Object.
  void toggleObjectMembers() {
    showObjectMembers = !showObjectMembers;
  }


  Element _loadIndicator;
  Timer _loadIndicatorUpdateTimer;
  static const _loadIndicatorSpeed = 150;
  double _progess = 1.0;

  /// When we have to fetch the JSON for an Item, display a spinning
  /// indicator to show the user that something is happening.
  Element get loadIndicator {
    if (_loadIndicator == null) {
      _loadIndicator = dartdocMain.shadowRoot
          .querySelector("#loading-indicator");
    }
    return _loadIndicator;
  }

  /// Make the indicator that we're loading data visible.
  showLoadIndicator() {
    if (loadIndicator.style.display != '') {
      loadIndicator.style.display = '';
      loadIndicator.children.first.style
          ..transition = 'all 0ms linear'
          ..transform = 'translate3d(-100%,0,0)';

      _progess = 1.0;
      _updateLoadIndicator();
    }
  }

  /// Hide the indicator that we're loading data.
  hideLoadIndicator() {
    if (_loadIndicatorUpdateTimer != null) {
      _loadIndicatorUpdateTimer.cancel();
      _loadIndicatorUpdateTimer = null;
    }

    if (_progess >= 1.0 / 1.168) {
      // Very short time, don't show it a fill width, looks "faster".
      loadIndicator.style.display = 'none';
    } else {
      // Before hiding the load indicator, show it at least for a moment at 
      // full width.
      loadIndicator.children.first.style
          ..transition = 'all ${_loadIndicatorSpeed}ms linear'
          ..transform = 'translate3d(0%,0,0)';

      _loadIndicatorUpdateTimer = new Timer(const Duration(milliseconds: 
        _loadIndicatorSpeed), () => loadIndicator.style.display = 'none');
    }
  }

  _updateLoadIndicator() {
    if (loadIndicator.style.display == '') {
      loadIndicator.children.first.style
          ..transition = 'all ${_loadIndicatorSpeed}ms linear'
          ..transform = 'translate3d(${-100 * _progess}%,0,0)';
      _progess /= 1.168;

      if (_loadIndicatorUpdateTimer != null) {
        _loadIndicatorUpdateTimer.cancel();
        _loadIndicatorUpdateTimer = null;
      }

      _loadIndicatorUpdateTimer = new Timer(const Duration(milliseconds: 
        _loadIndicatorSpeed), _updateLoadIndicator);
    }
  }
}

Iterable _concat(Iterable list1, Iterable list2) =>
    [list1, list2].expand((x) => x);
