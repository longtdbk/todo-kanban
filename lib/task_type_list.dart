import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/task_type_data.dart';
import 'task_type_add.dart';
import 'package:http/http.dart' as http;

class TaskTypeListScreen extends StatelessWidget {
  const TaskTypeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản trị Loại Công Việc',
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (BuildContext context) => const DashboardPage()))),
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: const TaskTypeList(),
    );
  }
}

class TaskTypeList extends StatefulWidget {
  const TaskTypeList({Key? key}) : super(key: key);

  @override
  TaskTypeListState createState() => TaskTypeListState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class TaskTypeListState extends State<TaskTypeList> {
  var tasktypes = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getAllTaskTypes();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getAllTaskTypes() async {
    tasktypes = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTaskTypes/' +
        prefs.getString('email')!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskTypeData taskType = TaskTypeData();
        taskType.name = dat['name'];
        taskType.code = dat['code'];
        tasktypes.add(taskType);
      }
      // showInSnackBar(msg);
      // if (status == "true") {
      //   Timer(
      //       Duration(seconds: 2),
      //       () => Navigator.of(context).pushReplacement(MaterialPageRoute(
      //           builder: (BuildContext context) => DashboardPage())));
      // }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  void _routeToAddTaskType() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const TaskTypeAddScreen()));
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);

    return RefreshIndicator(
        onRefresh: () async {
          //Do whatever you want on refrsh.Usually update the date of the listview
          getAllTaskTypes();
        },
        child: Scrollbar(
          child: ListView(
            restorationId: 'task_type_list_view',
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (int index = 0; index < tasktypes.length; index++)
                //ProjectData project = (ProjectData)projects[i];

                ListTile(
                  leading: ExcludeSemantics(
                    child: CircleAvatar(child: Text('$index')),
                  ),
                  title: Text(
                    tasktypes[index].name,
                  ),
                  subtitle: const Text('Loại CV'),
                ),
              FloatingActionButton(
                onPressed: () {
                  _routeToAddTaskType();
                },
                tooltip: 'Tạo Loại CV Mới',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        color: Colors.white,
        backgroundColor: Colors.purple);
  }
}
