class TasksData {
  final String name;
  final String code;
  final String description;
  final int level;
  final String status;
  final double profit;
  final String? email;
  final String? type;
  final String? category;

  const TasksData(
      {required this.name,
      required this.code,
      required this.description,
      required this.level,
      required this.status,
      this.email = '',
      this.profit = 0,
      this.type,
      this.category});

  //CategoriesData();
}

class TaskData {
  String name = '';
  String code = '';
  String description = '';
  String customFields = '';
  String type = '';
  String email = '';
  double profit = 0;
  String status = '';
  String category = '';
  //CategoriesData();
}
