import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import 'package:kanban_dashboard/dashboard.dart';
import 'package:kanban_dashboard/project_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/categories_data.dart';
import 'helper/project_data.dart';
import 'helper/task_status_data.dart';
import 'project_add.dart';
import 'register.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_slidable/flutter_slidable.dart';
// import 'util/languages.dart';
// import 'util/box.dart';
import 'util/util.dart';

class TaskStatusScreen extends StatelessWidget {
  const TaskStatusScreen({Key? key}) : super(key: key);
  // {
  //   this.code = code;
  // };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trạng thái Công Việc',
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const ProjectListScreen()))),
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: const TaskStatus(),
    );
  }
}

class TaskStatus extends StatefulWidget {
  final String? projectId;
  const TaskStatus({Key? key, this.projectId}) : super(key: key);

  @override
  TaskStatusState createState() => TaskStatusState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class TaskStatusState extends State<TaskStatus> {
  var taskStatuses = [];
  List<TaskStatusData> selectedStatus = [];
  ProjectData projectData = ProjectData();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    //getProject('cai-tien');
    // getTaskStatusSimple();
    getTaskStatus();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getTaskStatus() async {
    taskStatuses = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getTaskStatus/' + widget.projectId!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskStatusData taskStatus = TaskStatusData(
            id: dat['id'],
            name: dat['name'],
            shortName: dat['name'],
            code: dat['code']);
        taskStatuses.add(taskStatus);
      }
      getProject();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getProject() async {
    selectedStatus = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getProjectId/' + widget.projectId!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        projectData.id = dat['id'];
        projectData.name = dat['name'];
        projectData.taskStatuses = dat['task_statuses'];
        projectData.code = dat['code'];
      }

      var taskStatusesMap =
          jsonDecode(projectData.taskStatuses.replaceAll("'", "\""));

      for (int i = 1; i <= taskStatusesMap.length; i++) {
        // TaskStatusData taskStatusData = TaskStatusData(
        //     id: i.toString(),
        //     name: taskStatuses[i].name,
        //     shortName: taskStatuses[i].name,
        //     code: taskStatuses[i].code);
        for (int j = 0; j < taskStatuses.length; j++) {
          if (taskStatuses[j].id == taskStatusesMap[i.toString()]) {
            selectedStatus.add(taskStatuses[j]);
            break;
          }
        }
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> addTaskStatus(String name) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addTaskStatusPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': name,
          'project': widget.projectId!,
        });

    updateProjectTaskStatus();
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      if (status == 'true') {
        var id = json['data'][0]['id'];
        var code = json['data'][0]['code'];
        // add vao cuoi thoi :)
        selectedStatus.add(
            TaskStatusData(id: id, name: name, shortName: name, code: code));
      }
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    //Navigator.pop(context);
  }

  Future<void> editTaskStatus(String name, String taskStatusId) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/editTaskStatusPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': name,
          'id': taskStatusId,
          'project': widget.projectId!,
        });

    // updateProjectTaskStatus();
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      if (status == 'true') {
        for (int i = 0; i < selectedStatus.length; i++) {
          if (selectedStatus[i].id == taskStatusId) {
            selectedStatus[i] = TaskStatusData(
                id: taskStatusId, name: name, shortName: name, code: name);
            break;
          }
        }
      }
      // add vao cuoi thoi :)
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    //Navigator.pop(context);
  }

  // Sửa thứ tự thôi, tên không cần --> OK luôn
  Future<void> updateProjectTaskStatus() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    String value = "{";
    for (int i = 0; i < selectedStatus.length; i++) {
      value += "'" + (i + 1).toString() + "':'" + selectedStatus[i].id + "',";
    }
    value = value != "{" ? value.substring(0, value.length - 1) + "}" : "{}";

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/updateProjectPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'id': widget.projectId,
          'value': value,
          'option': '1',
        });
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    //Navigator.pop(context);
  }
  // void getTaskStatusSimple() {
  //   CategoryData category = CategoryData();
  //   category.name = 'Khối vận hành';
  //   category.code = 'khoi-van-hanh';
  //   categories.add(category);
  // }

  void _routeToAddProject() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const ProjectAddScreen()));
  }

  static const double _horizontalHeight = 96;
  static const List<String> options = [
    'Shuffle',
    'Test',
  ];

  // final List<TaskStatusData> selectedStatus = [
  //   const TaskStatusData(
  //       name: "To do", id: "1", shortName: "to do", code: "to-do"),
  //   const TaskStatusData(
  //       name: "Doing", id: "2", shortName: "doing", code: "doing"),
  //   const TaskStatusData(
  //       name: "Block", id: "3", shortName: "block", code: "block"),
  //   const TaskStatusData(
  //       name: "Block2", id: "4", shortName: "block2", code: "block2"),
  //   const TaskStatusData(
  //       name: "Block3", id: "5", shortName: "block3", code: "block3"),
  //   const TaskStatusData(
  //       name: "Block4", id: "6", shortName: "block4", code: "block4"),
  //   const TaskStatusData(
  //       name: "Block5", id: "7", shortName: "block5", code: "block5"),
  //   const TaskStatusData(
  //       name: "Block6", id: "8", shortName: "block6", code: "block6"),
  //   const TaskStatusData(
  //       name: "Block7", id: "9", shortName: "block7", code: "block7"),
  //   const TaskStatusData(
  //       name: "Block8", id: "10", shortName: "block8", code: "block8"),
  //   const TaskStatusData(
  //       name: "Block9", id: "11", shortName: "block9", code: "block9"),
  // ];

  bool inReorder = false;

  ScrollController scrollController = ScrollController();
  void onReorderFinished(List<TaskStatusData> newItems) {
    scrollController.jumpTo(scrollController.offset);
    setState(() {
      inReorder = false;

      selectedStatus
        ..clear()
        ..addAll(newItems);
    });
    updateProjectTaskStatus();
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);

    return RefreshIndicator(
        onRefresh: () async {
          //Do whatever you want on refrsh.Usually update the date of the listview
          //getProject('cai-tien');
        },
        child: isLoading
            ? const LinearProgressIndicator()
            : ListView(
                controller: scrollController,
                // Prevent the ListView from scrolling when an item is
                // currently being dragged.
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  _buildHeadline('Vertically'),
                  const Divider(height: 0),
                  // _buildVerticalLanguageList(),
                  _buildVerticalStatusList(),
                  _buildHeadline('Horizontally'),
                  // _buildHorizontalLanguageList(),
                  _buildHorizontalTaskStatusList(),
                  const SizedBox(height: 500),
                ],
              ),
        color: Colors.white,
        backgroundColor: Colors.red);
  }

  Widget _buildHeadline(String headline) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    Widget buildDivider() => Container(
          height: 2,
          color: Colors.grey.shade300,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        buildDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            headline,
            style: textTheme.bodyText1?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        buildDivider(),
        const SizedBox(height: 16),
      ],
    );
  }

  // cái này có thể dùng được
  Widget _buildVerticalStatusList() {
    final theme = Theme.of(context);

    Reorderable buildReorderable(
      TaskStatusData taskStatus,
      Widget Function(Widget tile) transition,
    ) {
      return Reorderable(
        key: ValueKey(taskStatus),
        builder: (context, dragAnimation, inDrag) {
          final tile = Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTileStatus(taskStatus),
              const Divider(height: 0),
            ],
          );

          return AnimatedBuilder(
            animation: dragAnimation,
            builder: (context, _) {
              final t = dragAnimation.value;
              final color = Color.lerp(Colors.white, Colors.grey.shade100, t);

              return Material(
                color: color,
                elevation: lerpDouble(0, 8, t)!,
                child: transition(tile),
              );
            },
          );
        },
      );
    }

    return ImplicitlyAnimatedReorderableList<TaskStatusData>(
      items: selectedStatus,
      shrinkWrap: true,
      reorderDuration: const Duration(milliseconds: 200),
      liftDuration: const Duration(milliseconds: 300),
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
      onReorderStarted: (item, index) => setState(() => inReorder = true),
      onReorderFinished: (movedLanguage, from, to, newItems) {
        // Update the underlying data when the item has been reordered!
        onReorderFinished(newItems);
      },
      itemBuilder: (context, itemAnimation, taskStatus, index) {
        return buildReorderable(taskStatus, (tile) {
          return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: itemAnimation,
            child: tile,
          );
        });
      },
      updateItemBuilder: (context, itemAnimation, taskStatus) {
        return buildReorderable(taskStatus, (tile) {
          return FadeTransition(
            opacity: itemAnimation,
            child: tile,
          );
        });
      },
      footer: _buildFooter(context, theme.textTheme),
    );
  }

  // // cái này thì cần thay đổi đi xem nào ???
  Widget _buildHorizontalTaskStatusList() {
    return Container(
      height: _horizontalHeight,
      alignment: Alignment.center,
      child: ImplicitlyAnimatedReorderableList<TaskStatusData>(
        items: selectedStatus,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
        onReorderStarted: (item, index) => setState(() => inReorder = true),
        onReorderFinished: (item, from, to, newItems) =>
            onReorderFinished(newItems),
        itemBuilder: (context, itemAnimation, item, index) {
          return Reorderable(
            key: ValueKey(item.toString()),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final box = _buildBoxTaskStatus(item, t);

              return SizeFadeTransition(
                animation: itemAnimation,
                axis: Axis.horizontal,
                axisAlignment: 1.0,
                curve: Curves.ease,
                child: box,
              );
            },
          );
        },
        updateItemBuilder: (context, itemAnimation, item) {
          return Reorderable(
            key: ValueKey(item.toString()),
            child: FadeTransition(
              opacity: itemAnimation,
              child: _buildBoxTaskStatus(item, 0),
            ),
          );
        },
      ),
    );
  }

// // đã hiểu cái này --> ko cần xem lại nữa
  Widget _buildTileStatus(TaskStatusData taskStatus) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final List<Widget> actionsStart = [
      SlidableAction(
        //closeOnTap: true,
        autoClose: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        //onPressed: () => setState(() => selectedLanguages.remove(lang)),
        onPressed: (BuildContext context) =>
            {setState(() => selectedStatus.remove(taskStatus))},
        label: 'Delete',
        icon: Icons.delete,
      ),
      SlidableAction(
        //closeOnTap: true,
        autoClose: true,
        backgroundColor: Color(0xFF21B7CA),
        foregroundColor: Colors.white,
        //onPressed: () => setState(() => selectedLanguages.remove(lang)),
        onPressed: (BuildContext context) =>
            {setState(() => selectedStatus.remove(taskStatus))},
        label: 'Share',
        icon: Icons.share,
      ),
    ];

    final List<Widget> actionsEnd = [
      SlidableAction(
        //closeOnTap: true,
        autoClose: true,
        backgroundColor: Color(0xFF7BC043),
        foregroundColor: Colors.white,
        //onPressed: () => setState(() => selectedLanguages.remove(lang)),
        onPressed: (BuildContext context) => {
          // setState(() => selectedStatus.remove(taskStatus))
          editTaskStatusDialog(taskStatus)
        },
        label: 'Sửa tên',
        icon: Icons.edit,
      ),
      SlidableAction(
        //closeOnTap: true,
        autoClose: true,
        backgroundColor: Color(0xFF0392CF),
        foregroundColor: Colors.white,
        //onPressed: () => setState(() => selectedLanguages.remove(lang)),
        onPressed: (BuildContext context) =>
            {setState(() => selectedStatus.remove(taskStatus))},
        label: 'Save',
        icon: Icons.save,
      ),
    ];

    return Slidable(
      key: const ValueKey(0),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(onDismissed: () {}),
        children: actionsStart,
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(onDismissed: () {}),
        children: actionsEnd,
      ),

      // actionPane: const SlidableBehindActionPane(),
      // actions: actions,
      // secondaryActions: actions,
      child: Container(
        alignment: Alignment.center,
        // For testing different size item. You can comment this line
        padding: EdgeInsets.zero,
        child: ListTile(
          title: Text(
            taskStatus.name,
            style: textTheme.bodyText2?.copyWith(
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            taskStatus.shortName,
            style: textTheme.bodyText1?.copyWith(
              fontSize: 15,
            ),
          ),
          leading: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                '${selectedStatus.indexOf(taskStatus) + 1}',
                style: textTheme.bodyText2?.copyWith(
                  color: theme.accentColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          trailing: const Handle(
            delay: Duration(milliseconds: 0),
            capturePointer: true,
            child: Icon(
              Icons.drag_handle,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // build List Item
  Widget _buildBoxTaskStatus(TaskStatusData item, double t) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final elevation = lerpDouble(0, 8, t)!;

    return Handle(
      delay: const Duration(milliseconds: 500),
      child: Box(
        height: _horizontalHeight,
        borderRadius: 8,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        elevation: elevation,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        margin: const EdgeInsets.only(right: 8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                item.name,
                style: textTheme.bodyText2,
              ),
              const SizedBox(height: 8),
              Text(
                item.shortName,
                style: textTheme.bodyText1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addTaskStatusDialog() {
    TextEditingController editingController = TextEditingController(text: '');
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
              title: Text('Thêm trạng thái công việc'),
              content: Container(
                height: 80,
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                child: CupertinoTextField(
                  controller: editingController,
                  autofocus: true,
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text('Cancel'),
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                    child: Text('Add'),
                    isDefaultAction: true,
                    onPressed: () {
                      if (editingController.text.isNotEmpty) {
                        // setState(() {});
                        addTaskStatus(editingController.text);
                      }
                      Navigator.of(context).pop();
                    }),
              ]);
        });
  }

  void editTaskStatusDialog(TaskStatusData taskStatusData) {
    TextEditingController editingController =
        TextEditingController(text: taskStatusData.name);
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
              title: Text('Sửa tên trạng thái'),
              content: Container(
                height: 80,
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                child: CupertinoTextField(
                  controller: editingController,
                  autofocus: true,
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text('Cancel'),
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                    child: Text('Update'),
                    isDefaultAction: true,
                    onPressed: () {
                      if (editingController.text.isNotEmpty) {
                        // setState(() {});
                        editTaskStatus(editingController.text, taskStatusData.id);
                      }
                      Navigator.of(context).pop();
                    }),
              ]);
        });
  }

  // build + button
  Widget _buildFooter(BuildContext context, TextTheme textTheme) {
    return Box(
      color: Colors.white,
      onTap: () {
        // final result = await Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const DashboardPage(),
        //   ),
        // );

        // if (result != null && !selectedStatus.contains(result)) {
        //   setState(() {
        //     selectedStatus.add(result);
        //   });
        // }
        addTaskStatusDialog();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const SizedBox(
              height: 36,
              width: 36,
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.grey,
                ),
              ),
            ),
            title: Text(
              'Thêm trạng thái',
              style: textTheme.bodyText1?.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 0),
        ],
      ),
    );
  }
}
