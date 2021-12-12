import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kanban_dashboard/category_list.dart';
import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/categories_data.dart';
import 'helper/custom_field_data.dart';
import 'helper/project_data.dart';
import 'helper/task_data.dart';
import 'helper/task_status_data.dart';
import 'project.dart';
import 'project_add.dart';
import 'register.dart';
import 'package:http/http.dart' as http;

import 'task_add.dart';

class TaskListScreen extends StatelessWidget {
  final ProjectData? project;
  final CategoryData? category;

  const TaskListScreen({Key? key, this.project, this.category})
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
      body: TaskList(project: project, category: category),
    );
  }
}

class TaskList extends StatefulWidget {
  final ProjectData? project;
  final CategoryData? category;
  const TaskList({Key? key, this.project, this.category}) : super(key: key);

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
  // with SingleTickerProviderStateMixin, RestorationMixin {
  var projects = [];
  var tasks = [];
  List<CustomFieldData> fields = [];
  // List<String> dropdownValues = [];
  // String dropdownValue = "1";
  //var tasksMap = [];
  HashMap tasksMap = HashMap<String, List<TaskData>>();
  var taskStatuses = [];
  bool isLoading = false;
  String project = '';
  String category = '';
  // String project = '';
  @override
  void initState() {
    super.initState();
    project = widget.project!.id;
    category = widget.category!.id;
    // String project = '61ab4b5084a5fa00241602dc';

    getTaskStatuses(project, category);
    getCustomFieldsProject(project);
    //getTasksProject(project);
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  // sau phải theo user nữa chứ ko phải chỉ thế này đâu ??
  Future<void> getTasksProject(String project, String category) async {
    tasks = [];

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    //var url = 'http://www.vietinrace.com/srvTD/getTasksProject/' + project;

    var url = 'http://www.vietinrace.com/srvTD/getTasksProjectCategory/' +
        project +
        '/' +
        category;
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
      for (int i = 0; i < tasks.length; i++) {
        tasksMap[tasks[i].status].add(tasks[i]);
      }

      createTabItem();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  // tạm đã --> để xong phần giao diện (rồi add Task ...)
  Future<void> getTaskStatuses(String project, String category) async {
    taskStatuses = [];
    tasksMap = HashMap<String, List<TaskData>>();
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
            id: dat['id'],
            code: dat['code'],
            shortName: dat['code']);
        taskStatuses.add(taskStatus);
      }

      for (int i = 0; i < taskStatuses.length; i++) {
        List<TaskData> taskList = [];
        tasksMap[taskStatuses[i].id] = taskList;
      }
      getTasksProject(project, category);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  // sau phải theo user nữa chứ ko phải chỉ thế này đâu ??
  Future<void> getCustomFieldsProject(String project) async {
    fields = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getCustomField/' + project;
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
          'project': widget.project!.id,
          'email': prefs.getString('email'),
          'category': widget.category!.id,
          'custom_fields': taskData.customFields,
          'type': ''
        });
    getTaskStatuses(project, category);
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
    imageSliders = [];
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
                        subtitle:
                            Text(tasksMap[taskStatuses[i].id][j].description),
                      ),
                    // }
                  ]),
            ),
            // )),
            // ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: null, // done luôn :))
              onPressed: () {
                // showBottomModalAdd(taskStatuses[i].id);
                showBottomModalAdd2(i);
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

  // void createTabItem2() {
  //   for (int i = 0; i < taskStatuses.length; i++) {
  //     Widget w = Container(
  //       child: Container(
  //         margin: EdgeInsets.all(5.0),
  //         child: ClipRRect(
  //             borderRadius: BorderRadius.all(Radius.circular(5.0)),
  //             // ô, hay thật, cái này là hiển thị phía trên :)
  //             child: Stack(
  //               children: <Widget>[
  //                 Image.network(imgList[i],
  //                     fit: BoxFit.cover, width: 1000.0, height: 600),
  //                 Positioned(
  //                   bottom: 0.0,
  //                   left: 0.0,
  //                   right: 0.0,
  //                   child: Container(
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         colors: [
  //                           Color.fromARGB(200, 0, 0, 0),
  //                           Color.fromARGB(0, 0, 0, 0)
  //                         ],
  //                         begin: Alignment.bottomCenter,
  //                         end: Alignment.topCenter,
  //                       ),
  //                     ),
  //                     padding: EdgeInsets.symmetric(
  //                         vertical: 10.0, horizontal: 20.0),
  //                     child: Text(
  //                       'No. ${taskStatuses[i].name} image',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 20.0,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             )),
  //       ),
  //     );
  //     imageSliders.add(w);
  //   }
  // }

  void showBottomModalAdd(String id) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return TaskAdd(
            taskStatusId: id,
            category: widget.category,
            fields: fields,
            project: widget.project!);
      },
    );
  }

  void _handleSubmitted(int taskStatusIndex, String name, String description,
      double profit, List<String> fieldValues) {
    //String taskStatus = widget.taskStatusId!;
    TaskData taskData = TaskData();
    taskData.status = taskStatuses[taskStatusIndex].id;
    taskData.description = description;
    taskData.name = name;
    taskData.profit = profit;

    String value = "{";
    for (int i = 0; i < fieldValues.length; i++) {
      if (fieldValues[i] != "") {
        value += "'" + fields[i].name + "':'" + fieldValues[i] + "',";
      }
    }
    value = value != "{" ? value.substring(0, value.length - 1) + "}" : "{}";
    taskData.customFields = value;

    createTask(taskData);
    //showInSnackBar("Tên:" + person.name + "SĐT:" + person.phoneNumber);
  }

  // List<Widget> createCustomFields() {
  //   // tao cac truong
  //   List<Widget> _customFields = [];

  //   for (int i = 0; i < fields.length; i++) {
  //     List<Widget> _rowsItem = [];
  //     _rowsItem.add(const SizedBox(width: 20));
  //     _rowsItem.add(Text(fields[i].name));
  //     _rowsItem.add(const SizedBox(width: 20));
  //     _rowsItem.add(Text(dropdownValue));
  //     var data = jsonDecode(fields[i].value.replaceAll("'", "\""));
  //     List<PopupMenuItem<String>> menu = [];
  //     for (int j = 1; j <= data.length; j++) {
  //       var menuItem = PopupMenuItem<String>(
  //           value: j.toString(),
  //           child: ListTile(
  //               // leading: const Icon(Icons.visibility),
  //               title: Text(
  //             data[j.toString()],
  //           )));
  //       menu.add(menuItem);
  //     }

  //     PopupMenuButton<String> popupMenu = PopupMenuButton<String>(
  //       padding: EdgeInsets.zero,
  //       onSelected: (value) => {
  //         setState(() {
  //           dropdownValue = data[value];
  //           // valueSelected = data[value];
  //         }),
  //         dropdownValues[i] == data[value]
  //       },
  //       itemBuilder: (context) => menu,
  //     );

  //     _rowsItem.add(popupMenu);
  //     _customFields.add(Row(children: _rowsItem));
  //   }
  //   return _customFields;
  // }

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

  // List<Widget> createCustomFields2() {
  //   // tao cac truong
  //   List<Widget> _customFields = [];

  //   for (int i = 0; i < fields.length; i++) {
  //     List<Widget> _rowsItem = [];

  //     _rowsItem.add(Text(fields[i].name));

  //     var data = jsonDecode(fields[i].value.replaceAll("'", "\""));
  //     List<DropdownMenuItem<String>> menu = [];
  //     // var dropdownValue = "";

  //     if (data.length > 0) {
  //       for (int j = 1; j <= data.length; j++) {
  //         var menuItem = DropdownMenuItem<String>(
  //           value: j.toString(),
  //           child: Text(data[j.toString()]),
  //         );
  //         menu.add(menuItem);
  //       }
  //       dropdownValues[i] = '1';
  //       //dropdownValues.add(data['1']);
  //       DropdownButton<String> dropDownItem = DropdownButton<String>(
  //           value: dropdownValue,
  //           icon: const Icon(Icons.arrow_downward),
  //           elevation: 16,
  //           style: const TextStyle(color: Colors.deepPurple),
  //           underline: Container(
  //             height: 2,
  //             color: Colors.deepPurpleAccent,
  //           ),
  //           onChanged: (String? newValue) {
  //             setState(() {
  //               dropdownValue = newValue!;
  //             });
  //           },
  //           items: menu);

  //       _rowsItem.add(dropDownItem);
  //       _customFields.add(Row(children: _rowsItem));
  //     }
  //   }
  //   return _customFields;
  // }

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

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SizedBox(
                  height: 450,
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
        });
      },
    );
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
          getTaskStatuses(project, category);
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
