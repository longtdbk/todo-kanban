import 'dart:async';
import 'dart:convert';
import 'dart:ui';

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
  const TaskStatus({Key? key}) : super(key: key);

  @override
  TaskStatusState createState() => TaskStatusState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class TaskStatusState extends State<TaskStatus> {
  var categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    //getProject('cai-tien');
    // getTaskStatusSimple();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getTaskStatus(String code) async {
    categories = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getProject/' + code;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        CategoryData category = CategoryData();
        category.name = dat['name'];
        category.code = dat['code'];
        categories.add(category);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  void getTaskStatusSimple() {
    CategoryData category = CategoryData();
    category.name = 'Khối vận hành';
    category.code = 'khoi-van-hanh';
    categories.add(category);
  }

  void _routeToAddProject() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const ProjectAddScreen()));
  }

  static const double _horizontalHeight = 96;
  static const List<String> options = [
    'Shuffle',
    'Test',
  ];

  final List<TaskStatusData> selectedStatus = [
    const TaskStatusData(
        name: "To do", id: "1", shortName: "to do", code: "to-do"),
    const TaskStatusData(
        name: "Doing", id: "2", shortName: "doing", code: "doing"),
    const TaskStatusData(
        name: "Block", id: "3", shortName: "block", code: "block"),
    const TaskStatusData(
        name: "Block2", id: "4", shortName: "block2", code: "block2"),
    const TaskStatusData(
        name: "Block3", id: "5", shortName: "block3", code: "block3"),
    const TaskStatusData(
        name: "Block4", id: "6", shortName: "block4", code: "block4"),
    const TaskStatusData(
        name: "Block5", id: "7", shortName: "block5", code: "block5"),
    const TaskStatusData(
        name: "Block6", id: "8", shortName: "block6", code: "block6"),
    const TaskStatusData(
        name: "Block7", id: "9", shortName: "block7", code: "block7"),
    const TaskStatusData(
        name: "Block8", id: "10", shortName: "block8", code: "block8"),
    const TaskStatusData(
        name: "Block9", id: "11", shortName: "block9", code: "block9"),
  ];

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
        child: ListView(
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
        onPressed: (BuildContext context) =>
            {setState(() => selectedStatus.remove(taskStatus))},
        label: 'Archive',
        icon: Icons.archive,
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

  // build + button
  Widget _buildFooter(BuildContext context, TextTheme textTheme) {
    return Box(
      color: Colors.white,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(),
          ),
        );

        if (result != null && !selectedStatus.contains(result)) {
          setState(() {
            selectedStatus.add(result);
          });
        }
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
