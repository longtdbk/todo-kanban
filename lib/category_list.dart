import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;

import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/categories_data.dart';
import 'helper/project_data.dart';

import 'package:http/http.dart' as http;

import 'task_list.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

class CategoryListScreen extends StatelessWidget {
  final String? projectId;
  final String? categoryId;
  const CategoryListScreen({Key? key, this.projectId, this.categoryId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản trị Danh mục',
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (BuildContext context) => const DashboardPage()))),
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: ProjectCategoryScreen(
          //title: 'TreeViewExample',
          projectId: projectId,
          categoryId: categoryId),
    );
  }
}

class ProjectCategoryScreen extends StatefulWidget {
  final String? projectId;
  final String? categoryId;
  const ProjectCategoryScreen({Key? key, this.projectId, this.categoryId})
      : super(key: key);
  //final String? title;

  @override
  _ProjectCategoryScreenState createState() => _ProjectCategoryScreenState();
}

class _ProjectCategoryScreenState extends State<ProjectCategoryScreen> {
  List<CategoriesData> categories = [];
  List<ProjectShareData> projectShares = [];
  CategoryData categoryPermission = CategoryData();
  bool isLoading = false;
  bool isLoadingBottom = false;

  ProjectData projectData = ProjectData();
  String userEmail = '';
  String _selectedNode = '';

  String emailShare = '';
  String sharePermission = 'view';

  List<Node> _nodes = [];
  TreeViewController _treeViewController = TreeViewController();
  bool docsOpen = true;
  bool deepExpanded = true;
  final Map<ExpanderPosition, Widget> expansionPositionOptions = const {
    ExpanderPosition.start: Text('Start'),
    ExpanderPosition.end: Text('End'),
  };
  final Map<ExpanderType, Widget> expansionTypeOptions = {
    ExpanderType.none: Container(),
    ExpanderType.caret: const Icon(
      Icons.arrow_drop_down,
      size: 28,
    ),
    ExpanderType.arrow: const Icon(Icons.arrow_downward),
    ExpanderType.chevron: const Icon(Icons.expand_more),
    ExpanderType.plusMinus: const Icon(Icons.add),
  };
  final Map<ExpanderModifier, Widget> expansionModifierOptions = {
    ExpanderModifier.none: const ModContainer(ExpanderModifier.none),
    ExpanderModifier.circleFilled:
        const ModContainer(ExpanderModifier.circleFilled),
    ExpanderModifier.circleOutlined:
        const ModContainer(ExpanderModifier.circleOutlined),
    ExpanderModifier.squareFilled:
        const ModContainer(ExpanderModifier.squareFilled),
    ExpanderModifier.squareOutlined:
        const ModContainer(ExpanderModifier.squareOutlined),
  };
  ExpanderPosition _expanderPosition = ExpanderPosition.start;
  ExpanderType _expanderType = ExpanderType.caret;
  ExpanderModifier _expanderModifier = ExpanderModifier.none;
  bool _allowParentSelect = true;
  bool _supportParentDoubleTap = false;
  int projectLevel = 0;

  @override
  void initState() {
    getProject();
    super.initState();
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
    final prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString("email")!;

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
        projectData.level = int.parse(dat['level']);
      }
      getAllCategorys();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> updateProjectLevel(int level) async {
    if (level <= projectData.level) {
      getProject();
    } else {
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
            'id': widget.projectId,
            'value': level.toString(),
            'option': '3',
          });
      setState(() {
        isLoading = false;
      });
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        var status = json['data'][0]['status'];
        var msg = json['data'][0]['msg'];
        if (status == "true") {
          getProject();
        }
        showInSnackBar(msg);
      } else {
        showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
      }
    }
    //Navigator.pop(context);
  }

  Future<void> addProjectShare(String email, String permission) async {
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
          'category': _selectedNode,
          'project': widget.projectId,
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

  Future<void> getProjectShare() async {
    projectShares = [];
    setState(() {
      isLoadingBottom = true;
    });

    var url = 'http://www.vietinrace.com/srvTD/getProjectShareByID/' +
        widget.projectId! +
        "/" +
        _selectedNode;
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

  Future<void> getAllCategorys() async {
    categories = [];
    setState(() {
      isLoading = true;
    });

    var url = 'http://www.vietinrace.com/srvTD/getCategoriesProject/' +
        widget.projectId!;
    //prefs.getString('email')!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        CategoriesData category = CategoriesData(
            name: dat['name'],
            id: dat['id'],
            code: dat['code'],
            key: dat['id'],
            level: int.parse(dat['level']),
            parent: dat['parent'],
            isParent: dat['is_parent'] == "true" ? true : false);
        categories.add(category);
        if (widget.categoryId != '' && category.id == widget.categoryId!) {
          categoryPermission.level = category.level;
          categoryPermission.id = category.id;
          categoryPermission.isParent = category.isParent;
          categoryPermission.key = category.key;
        }
      }
      if (categories.isNotEmpty) {
        _selectedNode = categories[0].id;
      }

      List<Node> _nodeTrees = _setNodesTree(projectData.level, categories);

      _nodes = [];
      for (int i = 0; i < _nodeTrees.length; i++) {
        _nodes.add(_nodeTrees[i]);
      }

      _treeViewController = TreeViewController(
        children: _nodes,
        selectedKey: _selectedNode,
      );
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> editCategory(String name, String categoryId) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/editCategoryPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': name,
          'id': categoryId,
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
        getProject();
      }
      // add vao cuoi thoi :)
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    //Navigator.pop(context);
  }

  Future<void> addCategoryChild(String name, String parentCategoryId) async {
    setState(() {
      isLoading = true;
    });

    // CategoriesData categoryParent;
    CategoryData categoryData = CategoryData();
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].id == parentCategoryId) {
        // categoryParent = categories[i];
        categoryData.level = categories[i].level + 1;
        categoryData.parent = categories[i].id;
      }
    }

    // final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addCategoryPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': name,
          'category_parent': parentCategoryId,
          'level': categoryData.level.toString(),
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
        updateProjectLevel(categoryData.level);
        //getProject();
      }
      // add vao cuoi thoi :)
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    //Navigator.pop(context);
  }

  // có thể viết theo qui nạp ??? nhưng mà thường lâu
  List<Node> _setNodesTree(int projectLevel, List<CategoriesData> categories) {
    List<Node> _nodes = [];
    HashMap hashMap = HashMap<String, HashMap<String, Node>>();
    // if (projectLevel > 0) {
    // Khởi tạo tree;
    for (int i = 0; i <= projectLevel; i++) {
      HashMap hashMapLevel = HashMap<String, Node>();
      hashMap[i.toString()] = hashMapLevel;
    }

    for (int level = projectLevel; level >= 0; level--) {
      // setNodeLevel(hashMap, i, projectLevel, categories);
      if (level == projectLevel) {
        for (int k = 0; k < categories.length; k++) {
          // đây là node nhé

          if (categories[k].level == projectLevel) {
            hashMap[level.toString()][categories[k].key] =
                Node(label: categories[k].name, key: categories[k].key);
          }
        }
      } else {
        for (int k = 0; k < categories.length; k++) {
          // đây là node nhé
          if (categories[k].level == level) {
            List<Node> nodeChild = [];
            int childLevel = level + 1;
            for (int d = 0; d < categories.length; d++) {
              if ((categories[d].level == childLevel) &&
                  (categories[d].parent == categories[k].key)) {
                nodeChild
                    .add(hashMap[childLevel.toString()][categories[d].key]!);
              }
            }
            hashMap[level.toString()][categories[k].key] = Node(
                label: categories[k].name,
                key: categories[k].key,
                children: nodeChild);
          }
        }
      }
    }
    // }
    if (widget.categoryId == '') {
      for (int i = 0; i < categories.length; i++) {
        if (categories[i].level == 0) {
          _nodes.add(hashMap['0'][categories[i].key]);
        }
      }
    } else {
      _nodes.add(
          hashMap[categoryPermission.level.toString()][categoryPermission.key]);
    }
    return _nodes;
  }

  ListTile _makeExpanderPosition() {
    return ListTile(
      title: const Text('Expander Position'),
      dense: true,
      trailing: CupertinoSlidingSegmentedControl(
        children: expansionPositionOptions,
        groupValue: _expanderPosition,
        onValueChanged: (ExpanderPosition? newValue) {
          setState(() {
            _expanderPosition = newValue!;
          });
        },
      ),
    );
  }

  SwitchListTile _makeAllowParentSelect() {
    return SwitchListTile.adaptive(
      title: const Text('Allow Parent Select'),
      dense: true,
      value: _allowParentSelect,
      onChanged: (v) {
        setState(() {
          _allowParentSelect = v;
        });
      },
    );
  }

  SwitchListTile _makeSupportParentDoubleTap() {
    return SwitchListTile.adaptive(
      title: const Text('Support Parent Double Tap'),
      dense: true,
      value: _supportParentDoubleTap,
      onChanged: (v) {
        setState(() {
          _supportParentDoubleTap = v;
        });
      },
    );
  }

  ListTile _makeExpanderType() {
    return ListTile(
      title: const Text('Expander Style'),
      dense: true,
      trailing: CupertinoSlidingSegmentedControl(
        children: expansionTypeOptions,
        groupValue: _expanderType,
        onValueChanged: (ExpanderType? newValue) {
          setState(() {
            _expanderType = newValue!;
          });
        },
      ),
    );
  }

  ListTile _makeExpanderModifier() {
    return ListTile(
      title: const Text('Expander Modifier'),
      dense: true,
      trailing: CupertinoSlidingSegmentedControl(
        children: expansionModifierOptions,
        groupValue: _expanderModifier,
        onValueChanged: (ExpanderModifier? newValue) {
          setState(() {
            _expanderModifier = newValue!;
          });
        },
      ),
    );
  }

  void showAddChildren(int option) {
    String categoryParent = '';
    if (option > 0) {
      categoryParent = _treeViewController.selectedNode!.key;
    }
    TextEditingController editingController = TextEditingController(text: '');
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
              title: const Text('Thêm Danh Mục Con'),
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
                  child: const Text('Add'),
                  isDefaultAction: true,
                  onPressed: () {
                    if (editingController.text.isNotEmpty) {
                      addCategoryChild(editingController.text, categoryParent);
                      // setState(() {
                      //   Node _node =
                      //       _treeViewController.selectedNode!;
                      //   _treeViewController =
                      //       _treeViewController.withUpdateNode(
                      //           _treeViewController.selectedKey!,
                      //           _node.copyWith(
                      //               label: editingController.text));
                      // });
                      //debugPrint(editingController.text);

                    }
                    Navigator.of(context).pop();
                  },
                )
              ]);
        });
  }

  void _routeToTaskList(String key) {
    CategoryData category = CategoryData();
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].key == key) {
        category.code = categories[i].code;
        category.name = categories[i].name;
        category.id = categories[i].id;
        category.key = categories[i].key;
        category.isParent = categories[i].isParent;
      }
    }
    if (category.isParent == false) {
      // _routeToTaskList(category.id);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(
                projectId: widget.projectId, categoryId: category.id),
          ));
    }
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

  Future<void> _showListShare() async {
    await getProjectShare();
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
                      _showAddShare(_selectedNode);
                    },
                    tooltip: 'Chia sẻ',
                    child: const Icon(Icons.add),
                  )
                ]));
          }));
        });
  }

  void _showAddShare(String key) {
    CategoryData category = CategoryData();
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].key == key) {
        category.code = categories[i].code;
        category.name = categories[i].name;
        category.id = categories[i].id;
        category.key = categories[i].key;
        category.isParent = categories[i].isParent;
      }
    }

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
                  onPressed: addShareProject,
                  child: const Text('Thêm'),
                )
              ])),
            );
          });
        });
  }

  Future<void> addShareProject() async {
    addProjectShare(emailShare, sharePermission);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  List<Widget> createButtonItem() {
    List<Widget> listButton = [];
    CupertinoButton button = CupertinoButton(
        child: const Text('Xem Công việc'),
        onPressed: () {
          _routeToTaskList(_selectedNode);
        });
    listButton.add(button);
    if (widget.categoryId == '') {
      CupertinoButton button5 = CupertinoButton(
        child: const Text('Thêm danh mục gốc'),
        onPressed: () {
          showAddChildren(0);
        },
      );
      listButton.add(button5);

      CupertinoButton button2 = CupertinoButton(
        child: const Text('Thêm danh mục con'),
        onPressed: () {
          showAddChildren(1);
        },
      );
      listButton.add(button2);

      CupertinoButton button3 = CupertinoButton(
          child: const Text('Phân quyền'),
          onPressed: () {
            _showListShare();
          });
      listButton.add(button3);
      CupertinoButton button4 = CupertinoButton(
        child: const Text('Sửa tên'),
        onPressed: () {
          TextEditingController editingController = TextEditingController(
              text: _treeViewController.selectedNode!.label);
          showCupertinoDialog(
              context: context,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: const Text('Sửa tên Danh Mục'),
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
                          // setState(() {
                          //   Node _node =
                          //       _treeViewController.selectedNode!;
                          //   _treeViewController =
                          //       _treeViewController.withUpdateNode(
                          //           _treeViewController.selectedKey!,
                          //           _node.copyWith(
                          //               label: editingController.text));
                          // });
                          //debugPrint(editingController.text);
                          editCategory(editingController.text,
                              _treeViewController.selectedNode!.key);
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        },
      );
      listButton.add(button4);
    }
    return listButton;
  }

  //tao cay :)
  @override
  Widget build(BuildContext context) {
    TreeViewTheme _treeViewTheme = TreeViewTheme(
      expanderTheme: ExpanderThemeData(
        type: _expanderType,
        modifier: _expanderModifier,
        position: _expanderPosition,
        color: Colors.grey.shade800,
        //color: Colors.blue,
        size: 30,
      ),
      labelStyle: const TextStyle(
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      parentLabelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w800,
        color: Colors.blue.shade700,
      ),
      iconTheme: IconThemeData(
        size: 18,
        color: Colors.grey.shade800,
      ),
      colorScheme: Theme.of(context).colorScheme,
    );
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title!),
      //   elevation: 0,
      // ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          height: double.infinity,
          child: isLoading
              ? const LinearProgressIndicator()
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: TreeView(
                          controller: _treeViewController,
                          allowParentSelect: _allowParentSelect,
                          supportParentDoubleTap: _supportParentDoubleTap,
                          onExpansionChanged: (key, expanded) =>
                              _expandNode(key, expanded),
                          onNodeTap: (key) {
                            debugPrint('Selected: $key');

                            setState(() {
                              _selectedNode = key;
                              _treeViewController = _treeViewController
                                  .copyWith(selectedKey: key);
                            });
                          },
                          onNodeDoubleTap: (key) {
                            // CategoryData category = CategoryData();
                            // for (int i = 0; i < categories.length; i++) {
                            //   if (categories[i].key == key) {
                            //     category.code = categories[i].code;
                            //     category.name = categories[i].name;
                            //     category.id = categories[i].id;
                            //     category.key = categories[i].key;
                            //     category.isParent = categories[i].isParent;
                            //   }
                            // }
                            // if (category.isParent == false) {
                            _routeToTaskList(key);
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => TaskListScreen(
                            //         projectId: widget.projectId,
                            //         categoryId: category.id),
                            //   ),
                            // );
                            // }
                          },
                          theme: _treeViewTheme,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        debugPrint('Close Keyboard');
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                        padding: const EdgeInsets.only(top: 20),
                        alignment: Alignment.center,
                        child: Text(
                            _treeViewController.getNode(_selectedNode) == null
                                ? ''
                                : _treeViewController
                                    .getNode(_selectedNode)!
                                    .label),
                      ),
                    )
                  ],
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ButtonBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: createButtonItem(),
          // children: <Widget>[
          //   CupertinoButton(
          //       child: const Text('Xem Công việc'),
          //       onPressed: () {
          //         _routeToTaskList(_selectedNode);
          //       }),
          //   CupertinoButton(
          //     child: const Text('Thêm danh mục con'),
          //     onPressed: () {
          //       showAddChildren();
          //     },
          //   ),
          //   CupertinoButton(
          //       child: const Text('Phân quyền'),
          //       onPressed: () {
          //         _showListShare();
          //       }),
          //   CupertinoButton(
          //     child: const Text('Sửa tên'),
          //     onPressed: () {
          //       TextEditingController editingController = TextEditingController(
          //           text: _treeViewController.selectedNode!.label);
          //       showCupertinoDialog(
          //           context: context,
          //           builder: (context) {
          //             return CupertinoAlertDialog(
          //               title: const Text('Sửa tên Danh Mục'),
          //               content: Container(
          //                 height: 80,
          //                 alignment: Alignment.center,
          //                 padding: const EdgeInsets.all(10),
          //                 child: CupertinoTextField(
          //                   controller: editingController,
          //                   autofocus: true,
          //                 ),
          //               ),
          //               actions: <Widget>[
          //                 CupertinoDialogAction(
          //                   child: const Text('Cancel'),
          //                   isDestructiveAction: true,
          //                   onPressed: () => Navigator.of(context).pop(),
          //                 ),
          //                 CupertinoDialogAction(
          //                   child: const Text('Update'),
          //                   isDefaultAction: true,
          //                   onPressed: () {
          //                     if (editingController.text.isNotEmpty) {
          //                       // setState(() {
          //                       //   Node _node =
          //                       //       _treeViewController.selectedNode!;
          //                       //   _treeViewController =
          //                       //       _treeViewController.withUpdateNode(
          //                       //           _treeViewController.selectedKey!,
          //                       //           _node.copyWith(
          //                       //               label: editingController.text));
          //                       // });
          //                       //debugPrint(editingController.text);
          //                       editCategory(editingController.text,
          //                           _treeViewController.selectedNode!.key);
          //                     }
          //                     Navigator.of(context).pop();
          //                   },
          //                 ),
          //               ],
          //             );
          //           });
          //     },
          //   ),
          // ],
        ),
      ),
    );
  }

  _expandNode(String key, bool expanded) {
    String msg = '${expanded ? "Expanded" : "Collapsed"}: $key';
    debugPrint(msg);
    Node node = _treeViewController.getNode(key)!;
    if (node != null) {
      List<Node> updated;
      if (key == 'docs') {
        updated = _treeViewController.updateNode(
            key,
            node.copyWith(
              expanded: expanded,
              icon: expanded ? Icons.folder_open : Icons.folder,
            ));
      } else {
        updated = _treeViewController.updateNode(
            key, node.copyWith(expanded: expanded));
      }
      setState(() {
        if (key == 'docs') docsOpen = expanded;
        _treeViewController = _treeViewController.copyWith(children: updated);
      });
    }
  }
}

class ModContainer extends StatelessWidget {
  final ExpanderModifier modifier;

  const ModContainer(this.modifier, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _borderWidth = 0;
    BoxShape _shapeBorder = BoxShape.rectangle;
    Color _backColor = Colors.transparent;
    Color _backAltColor = Colors.grey.shade700;
    switch (modifier) {
      case ExpanderModifier.none:
        break;
      case ExpanderModifier.circleFilled:
        _shapeBorder = BoxShape.circle;
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.circleOutlined:
        _borderWidth = 1;
        _shapeBorder = BoxShape.circle;
        break;
      case ExpanderModifier.squareFilled:
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.squareOutlined:
        _borderWidth = 1;
        break;
    }
    return Container(
      decoration: BoxDecoration(
        shape: _shapeBorder,
        border: _borderWidth == 0
            ? null
            : Border.all(
                width: _borderWidth,
                color: _backAltColor,
              ),
        color: _backColor,
      ),
      width: 15,
      height: 15,
    );
  }
}
