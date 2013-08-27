library member;

import 'dart:html';

import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/search.dart';
import 'package:web_ui/web_ui.dart';

import 'app.dart' as app;

/// This is a web component to be extended by all Dart members with comments.
/// Each member has an [Item] associated with it as well as a comment to
/// display, so this class handles those two aspects shared by all members.
class MemberElement extends WebComponent {
  @observable Item item;
 
  /// A valid string for an HTML id made from this [Item]'s name.
  String get idName {
    var name = item.name;
    if (item.name == '') name = item.decoratedName;
    return app.viewer.toHash(name);
  }
  
  /// Adds [item]'s comment to the the [elementName] element with markdown
  /// links converted to working links.
  void addComment(String elementName, {preview: false}) {
    var comment = item.comment;
    if (preview && (item is Class || item is Library)) 
      comment = item.previewComment;
    if (preview && (item is Method || item is Variable || item is Typedef)) {
      var index = item.comment.indexOf('</p>');
      // All comments when read in from the YAML is surrounded by a <span> tag.
      // This finds the first paragraph, and surrounds it with a span tag for
      // use as the snippet. 
      if (index == -1) comment = '<span></span>';
      else comment = item.comment.substring(0, index) + '</p></span>';
    }
    if (comment != '' && comment != null) {
      var commentLocation = getShadowRoot(elementName).query('.description');
      commentLocation.children.clear();
      var commentElement = new Element.html(comment);
      var links = commentElement.queryAll('a');
      for (AnchorElement link in links) {
        if (link.href =='') {
          if (link.text.contains('#')) {
            // If the link is to a parameter of this method, it shouldn't be
            // made into a working link. It instead is replaced with an <i>
            // tag to make it stand out within the comment.
            // TODO(tmandel): Handle parameters differently?
            var index = link.text.indexOf('#');
            var newName = link.text.substring(index + 1, link.text.length);
            link.replaceWith(new Element.html('<i>$newName</i>'));
          } else if (!index.keys.contains(link.text)) {
            // If markdown links to private or otherwise unknown members are
            // found, make them <i> tags instead of <a> tags for CSS.
            link.replaceWith(new Element.html('<i>${link.text}</i>'));
          } else {
            var linkable = new LinkableType(link.text);
            link
              ..href = '#${linkable.location}'
              ..text = linkable.simpleType;
          }
        }
      }
      commentLocation.children.add(commentElement);
    }
  }
  
  /// Creates an HTML element for a parameterized type.  
  static Element createInner(NestedType type) {
    var span = new SpanElement();
    if (index.keys.contains(type.outer.qualifiedName)) {
      var outer = new AnchorElement()
        ..text = type.outer.simpleType
        ..href = '#${type.outer.location}';
      span.append(outer);
    } else {
      span.appendText(type.outer.simpleType);
    }
    if (type.inner.isNotEmpty) {
      span.appendText('<');
      type.inner.forEach((element) {
        span.append(createInner(element));
        if (element != type.inner.last) span.appendText(', ');
      });
      span.appendText('>');
    }
    return span;
  }
  
  /// Creates a new HTML element describing a possibly parameterized type
  /// and adds it to [memberName]'s tag with class [className].
  void createType(NestedType type, String memberName, String className) {
    var location = getShadowRoot(memberName).query('.$className');
    location.children.clear();
    location.children.add(createInner(type));
  }
}

/// A [MemberElement] that could be inherited from another [MemberElement].
class InheritedElement extends MemberElement {
  LinkableType inheritedFrom;
  LinkableType commentFrom;
  
  inserted() {
    if (isInherited) {
      inheritedFrom = findInheritance(item.inheritedFrom);
    }
    if (hasInheritedComment) {
      commentFrom = findInheritance(item.commentFrom);
    }
  }
  
  bool get isInherited => 
      item.inheritedFrom != '' && item.inheritedFrom != null;
  
  bool get hasInheritedComment =>
      item.commentFrom != '' && item.commentFrom != null;
  
  /// Returns whether [location] exists within the search index.
  bool exists(String location) {
    return index.keys.contains(location.replaceAll('-','.'));
  }
  
  /// Creates a [LinkableType] for the owner of [qualifiedName].
  LinkableType findInheritance(String qualifiedName) {
    return new LinkableType(ownerName(qualifiedName));
  }
}

class MethodElement extends InheritedElement {
  List<Parameter> get parameters => item.parameters;
}