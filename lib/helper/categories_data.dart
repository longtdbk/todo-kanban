class CategoriesData {
  final String name;
  final String id;
  final String code;
  final String key;
  final int level;
  final String? parent;
  final bool? isParent;

  const CategoriesData(
      {required this.name,
      required this.id,
      required this.code,
      required this.key,
      required this.level,
      this.parent,
      this.isParent});

  //CategoriesData();
}

class CategoryData {
  String name = '';
  String id = '';
  String code = '';
  String key = '';
  int level = 0;
  String parent = '';
  bool? isParent = false;
  //CategoriesData();
}
