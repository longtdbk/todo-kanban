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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskStatusData &&
        other.name == name &&
        other.shortName == shortName;
  }

  @override
  int get hashCode => name.hashCode ^ shortName.hashCode;
}
