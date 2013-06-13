library category_item;

import 'package:web_ui/web_ui.dart';
import 'package:dartdoc_viewer/data.dart';
import 'package:dartdoc_viewer/read_yaml.dart';

/**
 * Represents anything that can store information. 
 */
@observable
class CategoryItem {
  List<CategoryItem> content = toObservable([]);
  
  // Empty constructor needed as the super constructor for Literals. 
  CategoryItem();
  
  /**
   * Returns a CategoryItem based off a map input based off Yaml. 
   */
  CategoryItem.fromYaml(yaml) {
    if (yaml is Map) {
      yaml.keys.forEach((k) => 
        content.add(Category._isCategoryKey(k) ? 
          new Category.fromYaml(k, yaml[k]) : new Item.fromYaml(k, yaml[k])));
    } else if (yaml is List) {
      yaml.forEach((n) => content.add(new Literal(n)));
    } else {
      content.add(new Literal(yaml));
    }
  }
}

/**
 * An item that has more content under it, which will be shown in another page.
 * 
 * Content can be other items, categories, or literals. 
 */
class Item extends CategoryItem {
  String name;
  
  Item.fromYaml(String this.name, yaml) : super.fromYaml(yaml);
}

/**
 * An item at its lowest level, and have no more layers under it. 
 */
class Literal extends CategoryItem {
  String content;
  
  Literal(String this.content);
}

/**
 * Category is a container for CategoryItems. 
 */
class Category extends CategoryItem {
  String name;
  
  /**
   * Words that are category heading should go in this list. 
   */
  static const List<String> _categoryKey = const [
    "libraries", "classes", "constructors", 
    "functions", "variables", "comments", "setters",
    "getters", "interfaces", "superclass", 
    "abstract", "methods", "rtype", "parameters",
    "type", "optional", "default", "static", 
    "operators", "final"
  ];
  
  Category.fromYaml(String this.name, yaml) : super.fromYaml(yaml);
  
  static bool _isCategoryKey(String key) => _categoryKey.contains(key);
}