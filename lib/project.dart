import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:kanban_dashboard/dashboard.dart';
import 'package:kanban_dashboard/project_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/categories_data.dart';
import 'helper/project_data.dart';
import 'project_add.dart';
import 'register.dart';
import 'package:http/http.dart' as http;

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({Key? key}) : super(key: key);
  // {
  //   this.code = code;
  // };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dự án',
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
      body: const ProjectSingle(),
    );
  }
}

class ProjectSingle extends StatefulWidget {
  const ProjectSingle({Key? key}) : super(key: key);

  @override
  ProjectSingleState createState() => ProjectSingleState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class ProjectSingleState extends State<ProjectSingle> {
  var categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    //getProject('cai-tien');
    getProjectSimple();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getProject(String code) async {
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

  void getProjectSimple() {
    CategoryData category = CategoryData();
    category.name = 'Khối vận hành';
    category.code = 'khoi-van-hanh';
    categories.add(category);
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
          //getProject('cai-tien');
        },
        child: Scrollbar(
          child: ListView(
            restorationId: 'project_list_view',
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (int index = 0; index < categories.length; index++)
                //ProjectData project = (ProjectData)projects[i];
                ListTile(
                    leading: ExcludeSemantics(
                      child: CircleAvatar(child: Text('$index')),
                    ),
                    title: Text(
                      categories[index].name,
                    ),
                    subtitle: Text('Danh mục'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardPage(),
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
