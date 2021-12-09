import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:kanban_dashboard/category_list.dart';
import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/project_data.dart';
import 'project.dart';
import 'project_add.dart';
import 'register.dart';
import 'package:http/http.dart' as http;

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản trị dự án',
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (BuildContext context) => const DashboardPage()))),
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: const ProjectList(),
    );
  }
}

class ProjectList extends StatefulWidget {
  const ProjectList({Key? key}) : super(key: key);

  @override
  ProjectListState createState() => ProjectListState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class ProjectListState extends State<ProjectList> {
  var projects = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getAllProjects();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getAllProjects() async {
    projects = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getProjects/' +
        prefs.getString('email')!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        ProjectData project = ProjectData();
        project.name = dat['name'];
        project.id = dat['id'];
        project.level = int.parse(dat['level']);
        project.code = dat['code'];
        projects.add(project);
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

  void _routeToAddProject() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const ProjectAddScreen()));
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);

    return RefreshIndicator(
        onRefresh: () async {
          //Do whatever you want on refrsh.Usually update the date of the listview
          getAllProjects();
        },
        child: Scrollbar(
          child: ListView(
            restorationId: 'project_list_view',
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (int index = 0; index < projects.length; index++)
                //ProjectData project = (ProjectData)projects[i];
                ListTile(
                    leading: ExcludeSemantics(
                      child: CircleAvatar(child: Text('${index + 1}')),
                    ),
                    title: Text(
                      projects[index].name,
                    ),
                    subtitle: const Text('Dự án'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryListScreen(project: projects[index]),
                        ),
                      );
                    }),
              FloatingActionButton(
                onPressed: () {
                  _routeToAddProject();
                },
                tooltip: 'Tạo dự án mới',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        color: Colors.white,
        backgroundColor: Colors.red);
  }
}
