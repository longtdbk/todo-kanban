import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'category_add.dart';
import 'helper/categories_data.dart';
import 'register.dart';
import 'package:http/http.dart' as http;

import 'util/states.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

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
      body: MyHomePage(title: 'TreeViewExample'),
    );
  }
}

class CategoryList extends StatefulWidget {
  const CategoryList({Key? key}) : super(key: key);

  @override
  CategoryListState createState() => CategoryListState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class CategoryListState extends State<CategoryList> {
  var categories = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getAllCategorys();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getAllCategorys() async {
    categories = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getCategories/' +
        prefs.getString('email')!;
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

  void _routeToAddCategory() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const CategoryAddScreen()));
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);

    return RefreshIndicator(
        onRefresh: () async {
          //Do whatever you want on refrsh.Usually update the date of the listview
          getAllCategorys();
        },
        child: Scrollbar(
          child: ListView(
            restorationId: 'Category_list_view',
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
                ),
              FloatingActionButton(
                onPressed: () {
                  _routeToAddCategory();
                },
                tooltip: 'Tạo danh mục mới',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        color: Colors.white,
        backgroundColor: Colors.purple);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CategoriesData> categories = [];
  bool isLoading = false;

  String _selectedNode = 'khoi-van-hanh';
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
    ExpanderType.caret: Icon(
      Icons.arrow_drop_down,
      size: 28,
    ),
    ExpanderType.arrow: Icon(Icons.arrow_downward),
    ExpanderType.chevron: Icon(Icons.expand_more),
    ExpanderType.plusMinus: Icon(Icons.add),
  };
  final Map<ExpanderModifier, Widget> expansionModifierOptions = {
    ExpanderModifier.none: ModContainer(ExpanderModifier.none),
    ExpanderModifier.circleFilled: ModContainer(ExpanderModifier.circleFilled),
    ExpanderModifier.circleOutlined:
        ModContainer(ExpanderModifier.circleOutlined),
    ExpanderModifier.squareFilled: ModContainer(ExpanderModifier.squareFilled),
    ExpanderModifier.squareOutlined:
        ModContainer(ExpanderModifier.squareOutlined),
  };
  ExpanderPosition _expanderPosition = ExpanderPosition.start;
  ExpanderType _expanderType = ExpanderType.caret;
  ExpanderModifier _expanderModifier = ExpanderModifier.none;
  bool _allowParentSelect = false;
  bool _supportParentDoubleTap = false;

  @override
  void initState() {
//     _nodes = [
//       Node(
//         label: 'documents',
//         key: 'docs',
//         expanded: docsOpen,
//         icon: docsOpen ? Icons.folder_open : Icons.folder,
//         children: [
//           Node(
//             label: 'personal',
//             key: 'd3',
//             icon: Icons.input,
//             iconColor: Colors.red,
//             children: [
//               Node(
//                 label: 'Poems.docx',
//                 key: 'pd1',
//                 icon: Icons.insert_drive_file,
//               ),
//               Node(
//                 label: 'Job Hunt',
//                 key: 'jh1',
//                 icon: Icons.input,
//                 children: [
//                   Node(
//                     label: 'Resume.docx',
//                     key: 'jh1a',
//                     icon: Icons.insert_drive_file,
//                   ),
//                   Node(
//                     label: 'Cover Letter.docx',
//                     key: 'jh1b',
//                     icon: Icons.insert_drive_file,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           Node(
//             label: 'Inspection.docx',
//             key: 'd1',
// //          icon: Icons.insert_drive_file),
//           ),
//           Node(label: 'Invoice.docx', key: 'd2', icon: Icons.insert_drive_file),
//         ],
//       ),
//       Node(
//           label: 'MeetingReport.xls',
//           key: 'mrxls',
//           icon: Icons.insert_drive_file),
//       Node(
//           label: 'MeetingReport.pdf',
//           key: 'mrpdf',
//           iconColor: Colors.green.shade300,
//           selectedIconColor: Colors.white,
//           icon: Icons.insert_drive_file),
//       Node(label: 'Demo.zip', key: 'demo', icon: Icons.archive),
//       Node(
//         label: 'empty folder',
//         key: 'empty',
//         parent: true,
//       ),
//     ];
    getAllCategorys();
    super.initState();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getAllCategorys() async {
    categories = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getCategories/' +
        prefs.getString('email')!;
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
            code: dat['code'],
            key: dat['key'],
            level: int.parse(dat['level']),
            parent: dat['parent'],
            isParent: true);
        categories.add(category);
      }

      List<Node> _nodeTrees = _setNodesTree(2, categories);
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

    for (int i = 0; i < categories.length; i++) {
      if (categories[i].level == 0) {
        _nodes.add(hashMap['0'][categories[i].key]);
      }
    }
    return _nodes;
  }

  // void setNodeLevel(HashMap<String, HashMap<String, Node>> hashMap, int level,
  //     int projectLevel, List<CategoryData> categories) {
  //   // nếu là node lá;
  //   if (level == projectLevel) {
  //     for (int k = 0; k < categories.length; k++) {
  //       // đây là node nhé
  //       if (categories[k].level == projectLevel) {
  //         hashMap[projectLevel.toString()][categories[k].key] =
  //             Node(label: categories[k].name, key: categories[k].key);
  //       }
  //     }
  //   } else {
  //     for (int k = 0; k < categories.length; k++) {
  //       // đây là node nhé
  //       if (categories[k].level == level) {
  //         List<Node> nodeChild = [];
  //         int childLevel = level - 1;
  //         for (int d = 0; d < categories.length; d++) {
  //           if ((categories[d].level == childLevel) &&
  //               (categories[d].parent == categories[k].key)) {
  //             nodeChild.add(hashMap[childLevel.toString()][categories[d].key]!);
  //           }
  //         }
  //         hashMap[project_level.toString()][categories[k].key] = Node(
  //           label: categories[k].name,
  //           key: categories[k].key,
  //         );
  //       }
  //     }
  //   }
  // }

  ListTile _makeExpanderPosition() {
    return ListTile(
      title: Text('Expander Position'),
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
      title: Text('Allow Parent Select'),
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
      title: Text('Support Parent Double Tap'),
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
      title: Text('Expander Style'),
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
      title: Text('Expander Modifier'),
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

  @override
  Widget build(BuildContext context) {
    TreeViewTheme _treeViewTheme = TreeViewTheme(
      expanderTheme: ExpanderThemeData(
          type: _expanderType,
          modifier: _expanderModifier,
          position: _expanderPosition,
          // color: Colors.grey.shade800,
          size: 20,
          color: Colors.blue),
      labelStyle: TextStyle(
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
          padding: EdgeInsets.all(20),
          height: double.infinity,
          child: Column(
            children: <Widget>[
//               Container(
//                 height: 160,
//                 child: Column(
//                   children: <Widget>[
//                     // _makeExpanderPosition(),
//                     // _makeExpanderType(),
//                     // _makeExpanderModifier(),
// //                    _makeAllowParentSelect(),
// //                    _makeSupportParentDoubleTap(),
//                   ],
//                 ),
//               ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(10),
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
                        _treeViewController =
                            _treeViewController.copyWith(selectedKey: key);
                      });
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
                  padding: EdgeInsets.only(top: 20),
                  alignment: Alignment.center,
                  child: Text(_treeViewController.getNode(_selectedNode) == null
                      ? ''
                      : _treeViewController.getNode(_selectedNode)!.label),
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
          children: <Widget>[
            CupertinoButton(
              child: Text('Node'),
              onPressed: () {
                setState(() {
                  _treeViewController = _treeViewController.copyWith(
                    children: _nodes,
                  );
                });
              },
            ),
            CupertinoButton(
              child: Text('JSON'),
              onPressed: () {
                setState(() {
                  _treeViewController =
                      _treeViewController.loadJSON(json: US_STATES_JSON);
                });
              },
            ),
//            CupertinoButton(
//              child: Text('Toggle'),
//              onPressed: _treeViewController.selectedNode != null &&
//                      _treeViewController.selectedNode.isParent
//                  ? () {
//                      setState(() {
//                        _treeViewController = _treeViewController
//                            .withToggleNode(_treeViewController.selectedKey);
//                      });
//                    }
//                  : null,
//            ),
            CupertinoButton(
              child: Text('Deep'),
              onPressed: () {
                String deepKey = 'jh1b';
                setState(() {
                  if (deepExpanded == false) {
                    List<Node> newdata =
                        _treeViewController.expandToNode(deepKey);
                    _treeViewController =
                        _treeViewController.copyWith(children: newdata);
                    deepExpanded = true;
                  } else {
                    _treeViewController =
                        _treeViewController.withCollapseToNode(deepKey);
                    deepExpanded = false;
                  }
                });
              },
            ),
            CupertinoButton(
              child: Text('Edit'),
              onPressed: () {
                TextEditingController editingController = TextEditingController(
                    text: _treeViewController.selectedNode!.label);
                showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: Text('Edit Label'),
                        content: Container(
                          height: 80,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(10),
                          child: CupertinoTextField(
                            controller: editingController,
                            autofocus: true,
                          ),
                        ),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            child: Text('Cancel'),
                            isDestructiveAction: true,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          CupertinoDialogAction(
                            child: Text('Update'),
                            isDefaultAction: true,
                            onPressed: () {
                              if (editingController.text.isNotEmpty) {
                                setState(() {
                                  Node _node =
                                      _treeViewController.selectedNode!;
                                  _treeViewController =
                                      _treeViewController.withUpdateNode(
                                          _treeViewController.selectedKey!,
                                          _node.copyWith(
                                              label: editingController.text));
                                });
                                debugPrint(editingController.text);
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ],
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
