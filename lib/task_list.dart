import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
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
import 'helper/task_data.dart';
import 'helper/task_status_data.dart';
import 'project.dart';
import 'project_add.dart';
import 'register.dart';
import 'package:http/http.dart' as http;

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản trị công việc',
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (BuildContext context) => const DashboardPage()))),
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: const TaskList(),
    );
  }
}

class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
  // with SingleTickerProviderStateMixin, RestorationMixin {
  var projects = [];
  var tasks = [];
  var taskStatuses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getTasksProject('61ab4b5084a5fa00241602dc');
    getTaskStatuses('61ab4b5084a5fa00241602dc');
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  // sau phải theo user nữa chứ ko phải chỉ thế này đâu ??
  Future<void> getTasksProject(String project) async {
    tasks = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTasksProject/' + project;
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
        task.code = dat['code'];
        task.description = dat['description'];
        task.status = dat['status'];
        task.type = dat['type'];
        task.category = dat['category'];
        tasks.add(task);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  // tạm đã --> để xong phần giao diện (rồi add Task ...)
  Future<void> getTaskStatuses(String project) async {
    projects = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTaskStatus/' + project;
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
            id: '1',
            code: dat['code'],
            shortName: dat['code']);
        taskStatuses.add(taskStatus);
      }
      createTabItem();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  void _routeToAddProject() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const ProjectAddScreen()));
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
    for (int i = 0; i < taskStatuses.length; i++) {
      Widget w = Container(
          margin: EdgeInsets.all(6.0),
          child: Column(children: [
            _buildHeadline('${taskStatuses[i].name}'),
            // Flexible(
            // child:
            // Container(
            //     height: 600.0,
            //     width: MediaQuery.of(context).size.width,
            //     decoration: BoxDecoration(
            //       color: Colors.green[50],
            //     ),
            //     child: Scrollbar(
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (int index = 0; index < 10; index++)
                      //ProjectData project = (ProjectData)projects[i];
                      //if (tasks[index].status == taskStatuses[i].code){
                      ListTile(
                        leading: ExcludeSemantics(
                          child: CircleAvatar(child: Text('${index + 1}')),
                        ),
                        title: Text(
                          'Thử nghiệm',
                        ),
                        subtitle: Text('Thử nghiệm'),
                      ),
                  ]),
            ),
            // )),
            // ),
            SizedBox(height: 10),
            FloatingActionButton(
              onPressed: () {
                // _routeToAddCategory();
                //createModal();
              },
              tooltip: 'Tạo Công Việc mới',
              child: const Icon(Icons.add),
            ),
          ]));

      imageSliders.add(w);
    }
  }

  void createTabItem2() {
    for (int i = 0; i < taskStatuses.length; i++) {
      Widget w = Container(
        child: Container(
          margin: EdgeInsets.all(5.0),
          child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              // ô, hay thật, cái này là hiển thị phía trên :)
              child: Stack(
                children: <Widget>[
                  Image.network(imgList[i],
                      fit: BoxFit.cover, width: 1000.0, height: 600),
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(200, 0, 0, 0),
                            Color.fromARGB(0, 0, 0, 0)
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                      child: Text(
                        'No. ${taskStatuses[i].name} image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )),
        ),
      );
      imageSliders.add(w);
    }
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
          getTaskStatuses('61ab4b5084a5fa00241602dc');
        },
        child: Column(children: [
          Padding(
              padding: EdgeInsets.only(top: 600 * .025), // để lên top
              child: CarouselSlider(
                items: imageSliders,
                carouselController: _controller,
                options: CarouselOptions(
                    autoPlay: false,
                    enlargeCenterPage: true,
                    height: MediaQuery.of(context).size.height * 0.8,
                    // aspectRatio: 2.0,
                    enableInfiniteScroll: false, // muốn sang trái sang phải ok
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
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(_current == entry.key ? 0.9 : 0.4)),
                ),
              );
            }).toList(),
          ),
        ]),
        color: Colors.white,
        backgroundColor: Colors.red);
  }
}
