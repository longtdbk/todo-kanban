class TaskStatusData {
  final String name;
  final String id;
  final String shortName;
  final String? code;
  const TaskStatusData({
    required this.id,
    required this.name,
    required this.shortName,
    this.code,
  });

  @override
  String toString() => 'Task status : $name, shortName: $shortName';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is TaskStatusData && o.name == name && o.shortName == shortName;
  }

  @override
  int get hashCode => name.hashCode ^ shortName.hashCode;
}
