import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kanban_dashboard/task_add.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/categories_data.dart';
import 'helper/custom_field_data.dart';
import 'helper/project_data.dart';
import 'helper/task_comment_data.dart';
import 'helper/task_data.dart';
import 'helper/task_log_data.dart';
import 'helper/task_status_data.dart';

import 'package:http/http.dart' as http;

import 'util/bottom_picker_custom.dart';

class TaskListScreen extends StatelessWidget {
  final String? projectId;
  final String? categoryId;

  const TaskListScreen({Key? key, this.projectId, this.categoryId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản trị công việc',
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: TaskList(projectId: projectId, categoryId: categoryId),
    );
  }
}

class TaskList extends StatefulWidget {
  final String? projectId;
  final String? categoryId;
  const TaskList({Key? key, this.projectId, this.categoryId}) : super(key: key);

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
  // with SingleTickerProviderStateMixin, RestorationMixin {
  //var projects = [];
  ProjectData projectData = ProjectData();
  CategoryData categoryData = CategoryData();

  DateTime dateStart = DateTime.now();
  DateTime dateEstimate = DateTime.now();
  DateTime dateFinish = DateTime.now();

  var tasks = [];
  var taskLogs = [];
  var taskComments = [];

  List<CustomFieldData> fields = [];
  // List<String> dropdownValues = [];
  // String dropdownValue = "1";
  //var tasksMap = [];
  HashMap tasksMap = HashMap<String, List<TaskData>>();
  var taskStatuses = [];
  bool isLoading = false;

  bool isLoadingBottom = false;
  String project = '';
  String category = '';
  String statusChoice = '';
  // String project = '';
  @override
  void initState() {
    super.initState();
    project = widget.projectId!;
    category = widget.categoryId!;
    // String project = '61ab4b5084a5fa00241602dc';

    getProject();
    getCategory();
    getCustomFieldsProject();
    //getTasksProject(project);
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getProject() async {
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getProjectID/' + widget.projectId!;
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
      getTaskStatuses();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getCategory() async {
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getCategoryID/' + widget.categoryId!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        categoryData.id = dat['id'];
        categoryData.name = dat['name'];
        categoryData.code = dat['code'];
        categoryData.isParent = dat['isParent'];
        categoryData.parent = dat['parent'];
        categoryData.level = int.parse(dat['level']);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  // sau phải theo user nữa chứ ko phải chỉ thế này đâu ??
  Future<void> getTasksProject() async {
    tasks = [];

    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    //var url = 'http://www.vietinrace.com/srvTD/getTasksProject/' + project;

    var url = 'http://www.vietinrace.com/srvTD/getTasksProjectCategory/' +
        widget.projectId! +
        '/' +
        widget.categoryId!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskData task = TaskData();
        task.name = dat['name'];
        task.id = dat['id'];
        task.code = dat['code'];
        task.description = dat['description'];
        task.status = dat['status'];
        task.profit = double.parse(dat['profit']);
        task.type = dat['type'];
        task.email = dat['email'];
        task.category = dat['category'];
        task.dateStart = dat['start_date'];
        task.customFields = dat['custom_fields'];
        task.dateFinishEstimate = dat['finish_estimate_date'];
        // task.dateFinish = dat['finish_date'];
        tasks.add(task);
      }
      for (int i = 0; i < tasks.length; i++) {
        tasksMap[tasks[i].status].add(tasks[i]);
      }

      createTabItem();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  // tạm đã --> để xong phần giao diện (rồi add Task ...)
  Future<void> getTaskStatuses() async {
    taskStatuses = [];
    List<TaskStatusData> taskStatusesTmp = [];
    tasksMap = HashMap<String, List<TaskData>>();
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

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
            name: dat['name'],
            id: dat['id'],
            code: dat['code'],
            shortName: dat['code']);
        taskStatusesTmp.add(taskStatus);
      }
      //
      if (projectData.taskStatuses != "{}") {
        // chi co '1':'f334433' // todo ; vi du the -
        var projectTaskStatuses =
            jsonDecode(projectData.taskStatuses.replaceAll("'", "\""));
        for (int i = 1; i <= projectTaskStatuses.length; i++) {
          for (int j = 0; j < taskStatusesTmp.length; j++) {
            if (taskStatusesTmp[j].id == projectTaskStatuses[i.toString()]) {
              taskStatuses.add(taskStatusesTmp[j]);
              break;
            }
          }
        }
      }
      for (int i = 0; i < taskStatuses.length; i++) {
        List<TaskData> taskList = [];
        tasksMap[taskStatuses[i].id] = taskList;
      }
      getTasksProject();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  // sau phải theo user nữa chứ ko phải chỉ thế này đâu ??
  Future<void> getCustomFieldsProject() async {
    fields = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getCustomField/' + widget.projectId!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        CustomFieldData field = CustomFieldData();
        field.name = dat['name'];
        field.code = dat['name'];
        field.id = dat['id'];
        field.value = dat['value'];
        field.isUse = dat['isUse'];
        fields.add(field);
        var data = jsonDecode(field.value.replaceAll("'", "\""));
        HashMap<String, String> values = HashMap<String, String>();
        for (int i = 1; i <= data.length; i++) {
          values[i.toString()] = data[i.toString()];
        }
        field.valueFields = values;
        // dropdownValues.add("");
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> createTask(TaskData taskData) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addTaskPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': taskData.name,
          'description': taskData.description,
          'status': taskData.status,
          'profit': taskData.profit.toString(),
          'project': projectData.id,
          'email': prefs.getString('email'),
          'category': widget.categoryId!,
          'custom_fields': taskData.customFields,
          'start_date': taskData.dateStart,
          'finish_date': '',
          'finish_estimate_date': taskData.dateFinishEstimate,
          'type': ''
        });
    //getTaskStatuses();
    getProject();
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

  Future<void> updateTaskID(TaskData taskData) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/editTaskPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': taskData.name,
          'description': taskData.description,
          'task_id': taskData.id,
          'status': taskData.status,
          'profit': taskData.profit.toString(),
          'project': widget.projectId!,
          'email': prefs.getString('email'),
          'category': widget.categoryId!,
          'custom_fields': taskData.customFields,
          'start_date': taskData.dateStart,
          // 'finish_date': '',
          'finish_estimate_date': taskData.dateFinishEstimate,
          // 'type': ''
        });

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
      Navigator.pop(context);
      getProject();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getLogs(String taskId) async {
    taskLogs = [];
    setState(() {
      isLoadingBottom = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTaskLogs/' + taskId;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoadingBottom = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskLogData taskLogData = TaskLogData();
        taskLogData.id = dat['id'];
        taskLogData.content = dat['content'];
        taskLogData.date = dat['created_date'];
        taskLogData.email = dat['email'];
        taskLogs.add(taskLogData);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getComments(String taskId) async {
    taskLogs = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTaskComments/' + taskId;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskCommentData taskCommentData = TaskCommentData();
        taskCommentData.id = dat['id'];
        taskCommentData.content = dat['content'];
        taskCommentData.date = dat['date'];
        taskCommentData.email = dat['email'];
        taskComments.add(taskCommentData);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  void _routeToAddTask(String taskStatusId) {
    // Để ý là push hay push replace ment
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (BuildContext context) => TaskAdd(
                  projectId: widget.projectId!,
                  categoryId: widget.categoryId!,
                  taskStatusId: taskStatusId,
                )))
        .then(onGoBack);
  }

  void _routeToEditTask(TaskData taskData) {
    // Để ý là push hay push replace ment
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (BuildContext context) => TaskAdd(
                  projectId: widget.projectId!,
                  categoryId: widget.categoryId!,
                  taskStatusId: taskData.status,
                  taskData: taskData,
                )))
        .then(onGoBack);
  }

  int _current = 0;
  final List<String> imgList = [
    'https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80',
    'https://images.unsplash.com/photo-1522205408450-add114ad53fe?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=368f45b0888aeb0b7b08e3a1084d3ede&auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=94a1e718d89ca60a6337a6008341ca50&auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1523205771623-e0faa4d2813d?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=89719a0d55dd05e2deae4120227e6efc&auto=format&fit=crop&w=1953&q=80',
    'https://images.unsplash.com/photo-1508704019882-f9cf40e475b4?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=8c6e5e3aba713b17aa1fe71ab4f0ae5b&auto=format&fit=crop&w=1352&q=80',
    'https://images.unsplash.com/photo-1519985176271-adb1088fa94c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=a0c8d632e977f94e5d312d9893258f59&auto=format&fit=crop&w=1355&q=80'
  ];

  List<Widget> imageSliders = [];

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

  void createTabItem() {
    imageSliders = [];
    for (int i = 0; i < taskStatuses.length; i++) {
      Widget w = Container(
          margin: const EdgeInsets.all(6.0),
          // height: MediaQuery.of(context).size.height * 0.8,
          child: Column(children: [
            _buildHeadline('${taskStatuses[i].name}'),
            // const SizedBox(height: 4),
            // Container(
            // child:
            Expanded(
              child: ListView(
                  // shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  // itemCount:  taskStatuses.length,
                  // itemBuilder: (context, index) =>

                  children: [
                    // for (int index = 0; index < taskStatuses.length; index++)
                    //ProjectData project = (ProjectData)projects[i];
                    //if (tasks[index].status == taskStatuses[i].code){
                    for (int j = 0;
                        j < tasksMap[taskStatuses[i].id].length;
                        j++)
                      //if (tasks[j].status == taskStatuses[i].id ){
                      ListTile(
                          leading: ExcludeSemantics(
                            child: CircleAvatar(child: Text('${j + 1}')),
                          ),
                          title: Text(
                            tasksMap[taskStatuses[i].id][j].name,
                          ),
                          subtitle: Text(tasksMap[taskStatuses[i].id][j].email),
                          trailing:
                              _createMenuTask(tasksMap[taskStatuses[i].id][j])),
                    //   // }
                  ]),
            ),
            // )),
            // ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: null, // done luôn :))
              onPressed: () {
                // showBottomModalAdd(taskStatuses[i].id);
                //showBottomModalAdd2(i);
                _routeToAddTask(taskStatuses[i].id);
                //createModal();
              },
              tooltip: 'Tạo Công Việc mới',
              child: const Icon(Icons.add),
            ),
          ]));

      imageSliders.add(w);
    }
  }

  void _handleSubmitted(int taskStatusIndex, String name, String description,
      double profit, List<String> fieldValues) {
    //String taskStatus = widget.taskStatusId!;
    TaskData taskData = TaskData();
    taskData.status = taskStatuses[taskStatusIndex].id;
    taskData.description = description;
    taskData.name = name;
    taskData.profit = profit;
    var outputFormat = DateFormat('dd/MM/yyyy');
    // var birthDate = outputFormat.format(date);
    taskData.dateStart = outputFormat.format(dateStart);
    taskData.dateFinishEstimate = outputFormat.format(dateEstimate);

    String value = "{";
    for (int i = 0; i < fieldValues.length; i++) {
      if (fieldValues[i] != "") {
        value += "'" + fields[i].id + "':'" + fieldValues[i] + "',";
      }
    }
    value = value != "{" ? value.substring(0, value.length - 1) + "}" : "{}";
    taskData.customFields = value;

    createTask(taskData);
    //showInSnackBar("Tên:" + person.name + "SĐT:" + person.phoneNumber);
  }

  List<PopupMenuEntry<String>> creteMenuSample(int i) {
    List<PopupMenuEntry<String>> menu = [];
    var data = jsonDecode(fields[i].value.replaceAll("'", "\""));
    for (int j = 1; j <= data.length; j++) {
      var menuItem = PopupMenuItem<String>(
          value: j.toString(),
          child: ListTile(
              // leading: const Icon(Icons.visibility),
              title: Text(
            data[j.toString()],
          )));
      menu.add(menuItem);
    }
    return menu;
  }

  Widget _createMenuTask(TaskData taskData) {
    List<PopupMenuEntry<String>> menu = [];
    var menuItem = const PopupMenuItem<String>(
      value: 'edit',
      child: ListTile(
          // leading: const Icon(Icons.visibility),
          title: Text('Sửa thông tin')),
    );
    menu.add(menuItem);

    var menuItem2 = const PopupMenuItem<String>(
        value: 'change_status',
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text('Đổi trạng thái')));
    menu.add(menuItem2);

    var menuItem3 = const PopupMenuItem<String>(
        value: 'view_log',
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text('Lịch sử Thay đổi')));
    menu.add(menuItem3);

    var popUpMenu = PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (value) => {
        if (value == "edit")
          {_routeToEditTask(taskData)}
        else if (value == "view_log")
          {showBottomModalListLog(taskData.id)}
        else if (value == "change_status")
          {showBottomModalChangeStatus(taskData)}
      },
      itemBuilder: (context) => menu,
    );
    return popUpMenu;
  }

  void _showPicker({
    @required BuildContext? context,
    @required Widget? child,
  }) {
    final themeData = CupertinoTheme.of(context!);
    final dialogBody = CupertinoTheme(
      data: themeData,
      child: child!,
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => dialogBody,
    );
  }

  Widget _buildDatePicker(BuildContext context, String title, int option,
      StateSetter setStateDate) {
    DateTime date = DateTime.now();
    if (option == 1) {
      date = dateStart;
    } else if (option == 2) {
      date = dateEstimate;
    }
    return GestureDetector(
      onTap: () {
        _showPicker(
          context: context,
          child: BottomPickerCustom(
            child: CupertinoDatePicker(
              backgroundColor:
                  CupertinoColors.systemBackground.resolveFrom(context),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: date,
              onDateTimeChanged: (newDateTime) {
                setStateDate(() => {
                      if (option == 1)
                        {dateStart = newDateTime}
                      else if (option == 2)
                        {dateEstimate = newDateTime}
                    });
              },
            ),
          ),
        );
      },
      child: MenuPickerCustom(children: [
        //const Icon(Icons.access_time_outlined),
        Text(title),
        Text(
          DateFormat.yMMMMd().format(date),
          style: const TextStyle(color: CupertinoColors.inactiveGray),
        ),
      ]),
    );
  }

  void showBottomModalAdd2(int taskStatusIndex) {
    String name = "";
    String desc = "";
    double profit = 0;
    List<String> dropdownTexts = [];
    List<String> dropdownValues = [];
    for (int i = 0; i < fields.length; i++) {
      dropdownValues.add("");
      dropdownTexts.add("");
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // dropdownValues.add("");
        // dropdownValues.add("");
        // bool valueChecked = false;

        return SingleChildScrollView(child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SizedBox(
                  height: 650,
                  child: Column(children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.all(15),
                        child: TextField(
                          onChanged: (value) => {name = value},
                          //controller: editingController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Tên công việc',
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: TextField(
                        onChanged: (value) => {desc = value},
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Mô tả',
                        ),
                        maxLines: 3,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: TextField(
                        onChanged: (value) => {profit = double.parse(value)},
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Lợi ích',
                          suffixText: 'VNĐ',
                        ),
                      ),
                    ),
                    // Column(
                    //   children: createCustomFields(),
                    // ),
                    _buildDatePicker(context, 'Ngày bắt đầu', 1, setState),
                    _buildDatePicker(
                        context, 'Ngày dự kiến hoàn thành', 2, setState),
                    for (int i = 0; i < fields.length; i++)
                      Row(children: [
                        const SizedBox(width: 20),
                        Text(fields[i].name),
                        const SizedBox(width: 20),
                        Text(dropdownTexts[i]),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) => {
                            setState(() {
                              dropdownTexts[i] = fields[i].valueFields[value];
                              dropdownValues[i] = value;
                              // valueSelected = data[value];
                            }),
                            //dropdownValues[i] == data[value]
                          },
                          itemBuilder: (context) => creteMenuSample(i),
                        )
                      ]),
                    ElevatedButton(
                      child: const Text('Tạo'),
                      onPressed: () {
                        if (name != "") {
                          _handleSubmitted(taskStatusIndex, name, desc, profit,
                              dropdownValues);
                          Navigator.of(context).pop();
                        }
                      },
                    )
                  ])));
        }));
      },
    );
  }

  List<Widget> _buildListLog() {
    List<Widget> list = [];
    if (isLoadingBottom) {
      list.add(const Center(child: LinearProgressIndicator()));
    } else {
      for (int index = 0; index < taskLogs.length; index++) {
        //ProjectData project = (ProjectData)projects[i];
        ListTile item = ListTile(
            leading: ExcludeSemantics(
              child: CircleAvatar(child: Text('${index + 1}')),
            ),
            title: Text(
              taskLogs[index].date,
            ),
            subtitle: Text(taskLogs[index].content),
            onTap: () => {});

        list.add(item);
      }

      // list.add(FloatingActionButton(
      //   onPressed: () {
      //     _routeToAddProject();
      //   },
      //   tooltip: 'Tạo dự án mới',
      //   child: const Icon(Icons.add),
      // ));
    }

    return list;
  }

  void showBottomModalListLog(String taskId) async {
    await getLogs(taskId);

    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 300,
              child: ListView(
                shrinkWrap: true,
                restorationId: 'logs_list_view',
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildListLog(),
              ),
            );
          }));
        });
  }

  Widget _buildChangeStatusDropDownList(
      TaskData taskData, StateSetter setStateStatus) {
    // if (statusChoice == '') {
    //   statusChoice = taskData.status;
    // }
    List<DropdownMenuItem<String>> menu = [];
    // var dropdownValue = "";
    for (int j = 0; j < taskStatuses.length; j++) {
      var menuItem = DropdownMenuItem<String>(
        value: taskStatuses[j].id,
        child: Text(taskStatuses[j].name),
      );
      menu.add(menuItem);
    }

    return Column(children: [
      Row(children: [
        const SizedBox(width: 50),
        const Text('Trạng Thái'),
        const SizedBox(width: 50),
        //dropdownValues.add(data['1']);
        DropdownButton<String>(
            value: statusChoice,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? newValue) {
              setStateStatus(() {
                statusChoice = newValue!;
              });
            },
            items: menu)
      ]),
      isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton(
              child: const Text('Cập nhật'),
              onPressed: () {
                taskData.status = statusChoice;
                updateTaskID(taskData);
                // Navigator.of(context).pop();
              }),
    ]);

    // return dropDownItem;
  }

  void showBottomModalChangeStatus(TaskData taskData) async {
    // await getLogs(taskId);
    statusChoice = taskData.status;
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 200,
              child: _buildChangeStatusDropDownList(taskData, setState),
            );
          }));
        });
  }

  FutureOr onGoBack(dynamic value) {
    getProject();
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);
    final CarouselController _controller = CarouselController();
    // cái này là từng Item đây này :)

    return RefreshIndicator(
        onRefresh: () async {
          //Do whatever you want on refrsh.Usually update the date of the listview
          //getTaskStatuses('61ab4b5084a5fa00241602dc');
          getProject();
        },
        child: Scrollbar(
          child: isLoading
              ? const Center(child: LinearProgressIndicator())
              : Column(children: [
                  Padding(
                      padding:
                          const EdgeInsets.only(top: 600 * .025), // để lên top
                      child: CarouselSlider(
                        items: imageSliders,
                        carouselController: _controller,
                        options: CarouselOptions(
                            autoPlay: false,
                            enlargeCenterPage: true,
                            height: MediaQuery.of(context).size.height * 0.8,
                            // aspectRatio: 2.0,
                            enableInfiniteScroll:
                                false, // muốn sang trái sang phải ok
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }),
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: taskStatuses.asMap().entries.map((entry) {
                      return GestureDetector(
                        //onTap: () => _controller.animateToPage(entry.key),
                        child: Container(
                          width: 6.0,
                          height: 6.0,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                                  .withOpacity(
                                      _current == entry.key ? 0.9 : 0.4)),
                        ),
                      );
                    }).toList(),
                  ),
                ]),
        ),
        color: Colors.white,
        backgroundColor: Colors.red);
  }
}
