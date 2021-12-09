class TasksData {
  final String name;
  final String code;
  final String description;
  final int level;
  final String status;
  final String? type;
  final String? category;

  const TasksData(
      {required this.name,
      required this.code,
      required this.description,
      required this.level,
      required this.status,
      this.type,
      this.category});

  //CategoriesData();
}

class TaskData {
  String name = '';
  String code = '';
  String description = '';
  String type = '';
  String status = '';
  String category = '';
  //CategoriesData();
}
