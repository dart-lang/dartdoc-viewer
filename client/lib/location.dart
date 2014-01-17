// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library location;

import 'package:observe/observe.dart';

// These regular expressions are not strictly accurate for picking Dart
// identifiers out of arbitrary text, e.g. identifiers must start with an
// alphabetic or underscore, this would allow "9a" as a library name. But
// they should be sufficient for extracting them from URLs that were created
// from valid identifiers.

/// A package in one of our URIs is an identifer and ends with a slash
final packageMatch = new RegExp(r'(\w+)/');
/// A library in one of our URIs is an identifier but may contain either
/// ':' or '-' in place of the '.' that is legal in a Dart library name.
final libraryMatch = new RegExp(r'([\w\-\:]+)');
/// A member or sub-member in one of our URI's starts with a '.' and is
/// an identifier.
final memberMatch = new RegExp(r'\.(\w+)');
/// A sub-member can be a normal identifier but can also be an operator.
/// Constructors always contain a "-" and are of the form
/// "className-constructorName" (if constructorName is empty, it will just be
/// "className-".
final subMemberMatch = new RegExp(r'\.([\w\<\+\|\[\]\>\/\^\=\&\~\*\-\%]+)');
final anchorMatch = new RegExp(r'\@([\w\<\+\|\[\]\>\/\^\=\&\~\*\-\%\.]+)');

// This represents a component described by a URI and can give us
// the URI given the component or vice versa.
class DocsLocation {
  String packageName;
  String libraryName;
  String memberName;
  String subMemberName;
  String anchor;

  // TODO(alanknight): These might be nicer to work with as immutable value
  // objects with methods to get modified versions.
  DocsLocation.empty();

  DocsLocation(String uri) {
    _extractPieces(uri);
  }

  DocsLocation.fromList(List<String> components) {
    if (components.length > 0) packageName = components[0];
    if (components.length > 1) libraryName = components[1];
    if (components.length > 2) memberName = components[2];
    if (components.length > 3) subMemberName = components[3];
    if (components.length > 4) anchor = components[4];
  }

  DocsLocation.clone(DocsLocation original) {
    packageName == original.packageName;
    libraryName == original.libraryName;
    memberName = original.memberName;
    subMemberName = original.subMemberName;
    anchor = original.anchor;
  }

  void _extractPieces(String uri) {
    if (uri == null || uri.length == 0) return;
    var position = uri[0] == "#" ? 1 : 0;

    _check(regex) {
      var match = regex.matchAsPrefix(uri, position);
      if (match != null) {
        var matchedString = match.group(1);
        position = position + match.group(0).length;
        return matchedString;
      }
    }

    packageName = _check(packageMatch);
    libraryName = _check(libraryMatch);
    memberName = _check(memberMatch);
    subMemberName = _check(subMemberMatch);
    anchor = _check(anchorMatch);
  }

  /// The URI hash string without its leading hash
  /// and without any trailing anchor portion, e.g. for
  /// http://site/#args/args.ArgParser#id_== it would return args/argsArgParser
  @reflectable String get withoutAnchor =>
      [packagePlus, libraryPlus, memberPlus, subMemberPlus].join("");

  /// The URI hash for just the library portion of this location.
  @reflectable String get libraryQualifiedName => "$packagePlus$libraryPlus";

  /// The full URI hash string without the leading hash character.
  /// e.g. for
  /// http://site/#args/args.ArgParser#id_==
  /// it would return args/argsArgParser#id_==
  @reflectable String get withAnchor => withoutAnchor + anchorPlus;

  @reflectable DocsLocation get locationWithoutAnchor =>
      new DocsLocation.clone(this)..anchor = null;

  /// The package name with the trailing / separator, or the empty
  /// string if the package name is not set.
  @reflectable get packagePlus => packageName == null
      ? ''
      : libraryName == null
          ? packageName
          : '$packageName/';
  /// The name of the library. This never has leading or trailing separators,
  /// so it's the same as [libraryName].
  @reflectable  get libraryPlus => libraryName == null ? '' :  libraryName;
  /// The name of the library member, with a leading period if the [memberName]
  /// is non-empty.
  @reflectable get memberPlus => memberName == null ? '' : '.$memberName';
  /// The name of the member's sub-member (e.g. the field of a class),
  /// with a leading period if the [subMemberName] is non-empty.
  @reflectable get subMemberPlus =>
      subMemberName == null ? '' : '.$subMemberName';
  /// The trailing anchor e.g. #id_hashCode, including the leading hash.
  @reflectable get anchorPlus => anchor == null ? '' : '@$anchor';

  /// Return a list of the components' basic names. Omits the anchor, but
  /// includes the package name, even if it is null.
  @reflectable List<String> get componentNames =>
      [packageName]..addAll(
          [libraryName, memberName, subMemberName].where((x) => x != null));

  /// Return all component names, including the anchor, and including those
  /// which are null.
  @reflectable List<String> get allComponentNames =>
      [packageName, libraryName, memberName, subMemberName, anchor];

  /// Return the simple name of the lowest-level component.
  @reflectable String get name {
    if (anchor != null) return anchor;
    if (subMemberName != null) return subMemberName;
    if (memberName != null) return memberName;
    if (libraryName != null) return libraryName;
    if (packageName != null) return packageName;
    return '';
  }

  /// Return a minimal list of the items along our path, using [root] for
  /// context. The [root] is of type Home, and it returns a list of Item,
  /// but we can't see those types from here.
  @reflectable List items(root) {
    // TODO(alanknight): Re-arrange the structure so that we can see
    // those types without needing to import html as well.
    var items = [];
    var package = packageName == null
        ? null
        : root.memberNamed(packageName);
    if (package != null) items.add(package);
    if (libraryName == null) return items;
    var home = items.isEmpty ? root : items.last;
    var library = home.memberNamed(libraryName);
    if (library == null) return items;
    items.add(library);
    var member = memberName == null
        ? null : library.memberNamed(memberName);
    if (member != null) {
      items.add(member);
      var subMember = subMemberName;
      if (subMember != null) {
        var lookupName = subMemberName;
        if (subMember.contains('-')) {
          // Constructors are hyphenated Classname-constructorname. We want to
          // look up just the constructor name.
          lookupName = subMemberName.substring(subMemberName.indexOf('-') + 1);
        }
        subMember = member.memberNamed(lookupName);
      }
      if (subMember != null) items.add(subMember);
    }
    return items;
  }

  /// Find the part of us that refers to an [Item] accessible from
  /// root and return a new [DocsLocation] with just that portion.
  /// e.g. if we had dart-core.String.substring.startIndex it
  /// would return dart-core.String.substring, since the method
  /// parameter doesn't have an [Item]. The [root] parameter is a Home.
  DocsLocation itemLocation(root) => item(root).location;

  /// Find the bottom-most [Item] that we refer to, accessible from
  /// root, and return it.
  /// e.g. if we had dart-core.String.substring.startIndex it
  /// would return the substring [Method], since the method
  /// parameter doesn't have an [Item]. The [root] parameter is a Home.
  item(root) {
    var myItems = items(root);
    return myItems.isEmpty ? null : myItems.last;
  }

  /// Return the item in the list that corresponds to the thing we represent.
  /// Assumes that the items all match what we describe, so really amounts
  /// to finding the last non-nil entry.
  @reflectable itemFromList(List items) => items.reversed
      .firstWhere((x) => x != null, orElse: () => null);

  /// Change [hash] into the form we use for identifying a doc entry within
  /// a larger page.
  @reflectable String toHash(String hash) => 'id_' + hash;

  /// The string that identifies our parent (e.g. the package containing a
  /// library, or the class containing a method) or an empty string if
  /// we don't have a parent.
  @reflectable String get parentQualifiedName => parentLocation.withoutAnchor;

  /// The [DocsLocation] that identifies our parent (e.g. the package
  /// containing a
  /// library, or the class containing a method)
  @reflectable DocsLocation get parentLocation =>
      new DocsLocation.fromList(componentNames..removeLast());

  @reflectable DocsLocation get asHash =>
      parentLocation..anchor = toHash(name);

  /// The simple name of our parent
  @reflectable String get parentName {
    var names = componentNames;
    return names.length < 2 ? '' : names[names.length - 2];
  }

  @reflectable bool get isEmpty => packageName == null && libraryName == null
      && memberName == null && subMemberName == null && anchor == null;

  /// Return the last component for which we have a value, not counting
  /// the anchor.
  @reflectable String get lastName {
    if (subMemberName != null) return subMemberName;
    if (memberName != null) return memberName;
    if (libraryName != null) return libraryName;
    if (packageName != null) return packageName;
    return null;
  }

  @reflectable toString() => 'DocsLocation($withAnchor)';
}
