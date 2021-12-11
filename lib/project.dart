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

import 'category_list.dart';
import 'custom_field_list.dart';
import 'helper/categories_data.dart';
import 'helper/project_data.dart';
import 'project_add.dart';
import 'package:http/http.dart' as http;

import 'task_status.dart';

// muc dich la co cai co dinh, co cai thay doi ???
// class ProjectScreen extends StatelessWidget {
//   final ProjectData ?projectData;
//   const ProjectScreen({Key? key, this.projectData}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Dự án',
//         ),
//         leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black),
//             onPressed: () => Navigator.of(context).pushReplacement(
//                 MaterialPageRoute(
//                     builder: (BuildContext context) =>
//                         const ProjectListScreen()))),
//         automaticallyImplyLeading: false,
//         //title: Text('Login'),
//       ),
//       body: const ProjectSingle(projectData:projectData),
//     );
//   }
// }

class ProjectSingle extends StatefulWidget {
  final ProjectData? project;
  const ProjectSingle({Key? key, this.project}) : super(key: key);

  @override
  ProjectSingleState createState() => ProjectSingleState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class ProjectSingleState extends State<ProjectSingle> {
  var categories = [];
  bool isLoading = false;

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  List<Widget> _listBody = [];

  void createTabItem() {
    _listBody.add(ProjectCategoryScreen(project: widget.project));
    _listBody.add(TaskStatus());
    _listBody.add(CustomFieldList(project: widget.project));
  }

  @override
  void initState() {
    super.initState();
    //getProject('cai-tien');
    getProjectSimple();
    createTabItem();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dự án',
          ),
        ),
        body: Center(
          child: _listBody.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_outlined),
              label: 'Danh mục',
              backgroundColor: Colors.red,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style_sharp),
              label: 'Trạng Thái ',
              backgroundColor: Colors.green,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.control_point_duplicate_outlined),
              label: 'Trường Tự chọn',
              backgroundColor: Colors.purple,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ));
  }
}
