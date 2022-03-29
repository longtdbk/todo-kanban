import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;

import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'category_list.dart';
import 'chart_tab.dart';
import 'helper/project_data.dart';
import 'helper/user_data.dart';
import 'line_chart.dart';
import 'project.dart';
import 'project_add.dart';
import 'package:http/http.dart' as http;

import 'task_list.dart';

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
  var prefs;
  List<ProjectShareData> projectShares = [];
  UserData userData = UserData();
  bool isLoading = false;

  bool isLoadingBottom = false;
  String userEmail = '';

  String emailShare = '';
  String sharePermission = 'view';

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

  Future<void> getUserProjectShared() async {
    setState(() {
      isLoading = true;
    });

    var url = 'http://www.vietinrace.com/srvTD/getUserInfo/' +
        prefs.getString('email')!;
    // 'longtdbk2@gmail.com';

    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        userData.id = dat['id'];
        userData.description = dat['description'];
        userData.phone = dat['phone'];
        userData.image = dat['image'];
        userData.name = dat['name'];
        userData.projectShare = dat['project_share'];

        var projectsShare =
            jsonDecode(userData.projectShare.replaceAll("'", "\""));
        // if (projectsShare.length > 0) {
        for (int i = 0; i < projectsShare.length; i++) {
          ProjectData projectData = ProjectData();
          projectData.id = projectsShare[i]['project'];
          projectData.name = projectsShare[i]['project'];
          projectData.isShared = true;
          projectData.categoryShare = projectsShare[i]['category'];
          projectData.permissionShare = projectsShare[i]['permission'];
          projects.add(projectData);
        }
      }

      // } else {
      //showInSnackBar("Không tìm thấy user ");
      // }
      //var msg = json['data']['msg'];

    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> updateProjectName(String projectId, String name) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/updateProjectPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'id': projectId,
          'value': name,
          'option': '2',
        });
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      if (status == "true") {
        getAllProjects();
      }
      Navigator.pop(context);
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  // lay tat ca project Shared = Post // hieu
  Future<void> getAllProjectsShared() async {
    setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getSharedProject/' +
        prefs.getString('email')!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        ProjectData projectData = ProjectData();
        projectData.categoryShare = dat['category'];
        projectData.categoryShareName = dat['category_name'];
        projectData.categoryIsParent =
            dat['category_is_parent'] == "true" ? true : false;
        projectData.categoryShareLevel = int.parse(dat['category_level']);
        projectData.id = dat['project'];
        projectData.name = dat['project_name'];
        projectData.permissionShare = dat['permission'];
        projectData.isShared = true;
        projects.add(projectData);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getAllProjects() async {
    projects = [];
    setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

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
        project.taskStatuses = dat['task_statuses'];
        projects.add(project);
      }
      getAllProjectsShared();
      //getUserProjectShared();

    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> addProjectShare(
      int index, String email, String permission) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addProjectSharePost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'email': email,
          'category': '',
          'project': projects[index].id,
          'permission': permission
        });
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      if (status == "true") {
        //getProject();
      }
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getProjectShare(int index) async {
    projectShares = [];
    setState(() {
      isLoadingBottom = true;
    });

    var url = 'http://www.vietinrace.com/srvTD/getProjectShareByID/' +
        projects[index].id +
        "/" +
        '0';
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoadingBottom = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];

      for (var dat in data) {
        ProjectShareData projectShareData = ProjectShareData();
        projectShareData.id = dat['id'];
        projectShareData.category = dat['category'];
        projectShareData.email = dat['email'];
        projectShareData.permission = dat['permission'];
        projectShares.add(projectShareData);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> removeProjectShare(String projectShareId) async {
    projectShares = [];
    setState(() {
      isLoadingBottom = true;
    });

    var url =
        'http://www.vietinrace.com/srvTD/removeProjectShare/' + projectShareId;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoadingBottom = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      var msg = data[0]['msg'];
      showInSnackBar(msg);
      Navigator.pop(context);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  void _routeToAddProject() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const ProjectAdd()));
  }

  void _routeToManageTask(int index) {
    if (!projects[index].isShared) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProjectSingle(project: projects[index], categoryId: ''),
        ),
      );
    } else {
      if (projects[index].permissionShare == "edit") {
        if (projects[index].categoryIsParent) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectSingle(
                    project: projects[index],
                    categoryId: projects[index].categoryShare),
              ));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskListScreen(
                    projectId: projects[index].id,
                    categoryId: projects[index].categoryShare),
              ));
        }
      }
    }
  }

  void showEditProjectName(String projectId, String oldName) {
    TextEditingController editingController =
        TextEditingController(text: oldName);
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
              title: const Text('Sửa tên'),
              content: Container(
                height: 80,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: CupertinoTextField(
                  controller: editingController,
                  autofocus: true,
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                  child: const Text('Update'),
                  isDefaultAction: true,
                  onPressed: () {
                    if (editingController.text.isNotEmpty) {
                      updateProjectName(projectId, editingController.text);
                    }
                    Navigator.of(context).pop();
                  },
                )
              ]);
        });
  }

  void _routeToChart(int index) {
    if (!projects[index].isShared) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => TabChartPage(
              projectId: projects[index].id,
              categoryId: '',
              title: 'Thống Kê Chung',
              year: '2021')));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => TabChartPage(
              projectId: projects[index].id,
              categoryId: projects[index].categoryShare,
              title: 'Thống Kê',
              year: '2021')));
    }
  }

  List<Widget> _buildListShare() {
    List<Widget> list = [];
    if (isLoadingBottom) {
      list.add(const Center(child: LinearProgressIndicator()));
    } else {
      for (int index = 0; index < projectShares.length; index++) {
        //ProjectData project = (ProjectData)projects[i];
        ListTile item = ListTile(
          leading: ExcludeSemantics(
            child: CircleAvatar(child: Text('${index + 1}')),
          ),
          title: Text(
            projectShares[index].email,
          ),
          subtitle: Text(projectShares[index].permission),
          trailing: _createMenuProjectShare(index),
        );
        list.add(item);
      }
    }

    return list;
  }

  Future<void> _showListShare(int index) async {
    await getProjectShare(index);
    await Future.delayed(Duration.zero);
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
                height: 500,
                child: Column(children: [
                  SizedBox(
                    height: 300,
                    child: ListView(
                      shrinkWrap: true,
                      restorationId: 'logs_list_view',
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: _buildListShare(),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      //_routeToAddProject();
                      _showAddShare(index, '');
                    },
                    tooltip: 'Chia sẻ',
                    child: const Icon(Icons.add),
                  )
                ]));
          }));
        });
  }

  Future<void> addShareProject(int index) async {
    addProjectShare(index, emailShare, sharePermission);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  void _showAddShare(int index, String key) {
    List<DropdownMenuItem<String>> menu = [];

    var menuItem = const DropdownMenuItem<String>(
      value: "view",
      child: Text("Quyền Xem"),
    );
    menu.add(menuItem);

    var menuItem2 = const DropdownMenuItem<String>(
      value: "edit",
      child: Text("Quyền Sửa"),
    );
    menu.add(menuItem2);
    //String statusChoice = "view";

    // Column column = Column(children: [

    // ],)

    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 500,
              child: SingleChildScrollView(
                  child: Column(children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      onChanged: (value) => {emailShare = value},
                      //controller: editingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nhập email ',
                      ),
                    )),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const Text("Chọn mức phân quyền"),
                    const SizedBox(width: 20),
                    DropdownButton<String>(
                        value: sharePermission,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          //statusChoice = newValue!;
                          setState(() {
                            sharePermission = newValue!;
                          });
                        },
                        items: menu),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => addShareProject(index),
                  child: const Text('Thêm'),
                )
              ])),
            );
          });
        });
  }

  Widget _createMenuProject(int index) {
    List<PopupMenuEntry<String>> menu = [];
    if (!projects[index].isShared) {
      var menuItem = const PopupMenuItem<String>(
        value: 'edit',
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text('Sửa tên')),
      );
      menu.add(menuItem);

      var menuItem2 = const PopupMenuItem<String>(
          value: 'task_list',
          child: ListTile(
              // leading: const Icon(Icons.visibility),
              title: Text('Quản trị Công việc')));
      menu.add(menuItem2);

      var menuItem4 = const PopupMenuItem<String>(
          value: 'assign_project',
          child: ListTile(
              // leading: const Icon(Icons.visibility),
              title: Text('Phân quyền dự án')));
      menu.add(menuItem4);
    } else if (projects[index].permissionShare == 'edit') {
      var menuItem2 = const PopupMenuItem<String>(
          value: 'task_list',
          child: ListTile(
              // leading: const Icon(Icons.visibility),
              title: Text('Quản trị Công việc')));
      menu.add(menuItem2);
    }

    var menuItem3 = const PopupMenuItem<String>(
        value: 'view_chart',
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text('Biểu đồ')));
    menu.add(menuItem3);

    var popUpMenu = PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (value) => {
        if (value == "edit")
          {showEditProjectName(projects[index].id, projects[index].name)}
        else if (value == "task_list")
          {_routeToManageTask(index)}
        else if (value == "view_chart")
          {_routeToChart(index)}
        else if (value == "assign_project")
          {_showListShare(index)}
      },
      itemBuilder: (context) => menu,
    );
    return popUpMenu;
  }

  Widget _createMenuProjectShare(int index) {
    List<PopupMenuEntry<String>> menu = [];
    var menuItem = const PopupMenuItem<String>(
      value: 'edit',
      child: ListTile(
          // leading: const Icon(Icons.visibility),
          title: Text('Sửa')),
    );
    menu.add(menuItem);

    var menuItem2 = const PopupMenuItem<String>(
        value: 'remove',
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text('Xóa')));
    menu.add(menuItem2);

    var popUpMenu = PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (value) => {
        if (value == "edit")
          {}
        else if (value == "remove")
          {removeProjectShare(projectShares[index].id)}
      },
      itemBuilder: (context) => menu,
    );
    return popUpMenu;
  }

  List<Widget> buildList() {
    List<Widget> list = [];
    if (isLoading) {
      list.add(const Center(child: LinearProgressIndicator()));
    } else {
      for (int index = 0; index < projects.length; index++) {
        //ProjectData project = (ProjectData)projects[i];
        ListTile item = ListTile(
          // tileColor: Colors.blue[100],
          leading: ExcludeSemantics(
            child: CircleAvatar(child: Text('${index + 1}')),
          ),
          title: Text(
            projects[index].name,
          ),
          subtitle: projects[index].isShared == true
              ? const Text('Dự án được chia sẻ')
              : const Text('Dự án quản lý'),
          trailing: _createMenuProject(index),
        );

        list.add(item);
      }

      list.add(FloatingActionButton(
        onPressed: () {
          _routeToAddProject();
        },
        tooltip: 'Tạo dự án mới',
        child: const Icon(Icons.add),
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);
    Image imgInside = Image.asset('assets/images/inside.png',
        width: MediaQuery.of(context).size.width * 0.96,
        height: MediaQuery.of(context).size.height * 0.5,
        fit: BoxFit.fitHeight);
    Column col = Column(children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
      Center(child: imgInside)
    ]);
    return RefreshIndicator(
        onRefresh: () async {
          //Do whatever you want on refrsh.Usually update the date of the listview
          getAllProjects();
        },
        child: Scrollbar(
            child: Stack(
          children: [
            col,
            ListView(
              restorationId: 'project_list_view',
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: buildList(),
            ),
          ],
        )),
        color: Colors.white,
        backgroundColor: Colors.red);
  }
}
