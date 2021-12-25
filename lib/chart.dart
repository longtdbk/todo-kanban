import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'chart_tab.dart';
import 'helper/categories_data.dart';
import 'helper/chart_data.dart';
import 'helper/custom_field_data.dart';
import 'helper/task_status_data.dart';
import 'indicator.dart';

class ChartScreen extends StatefulWidget {
  final String? projectId;
  final String? title;
  final String? categoryId;
  final String? year;
  const ChartScreen(
      {Key? key, this.projectId, this.categoryId, this.title, this.year})
      : super(key: key);

  @override
  // _DashboardPageState2 createState() => _DashboardPageState2();
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int touchedIndex = -1; // giá trị để làm việc đây :)
  String categoryChooseName = ""; // category goc :)
  String categoryChooseId = "";
  var chartDatas = [];

  List<TaskStatusData> taskStatuses = [];
  String statuses = '';
  List<bool> checkStatuses = [];
  // for customField
  var fields = [];
  var fieldsNumber = [];
  HashMap<String, List<ChartData>> mapDatasCustomField =
      HashMap<String, List<ChartData>>();
  HashMap<String, int> mapTouchedIndexCustom = HashMap<String, int>();
  HashMap<String, String> mapIndexCustomName = HashMap<String, String>();

  HashMap<String, List<ChartData>> mapDatasCustomFieldNumber =
      HashMap<String, List<ChartData>>();
  HashMap<String, int> mapTouchedIndexCustomNumber = HashMap<String, int>();
  HashMap<String, String> mapIndexCustomNumberName = HashMap<String, String>();

  HashMap<String, CategoriesData> mapCategories =
      HashMap<String, CategoriesData>();
  List<Color> chartColors = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    getTaskStatus();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getTaskStatus() async {
    taskStatuses = [];
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
            id: dat['id'],
            name: dat['name'],
            shortName: dat['name'],
            code: dat['code']);
        taskStatuses.add(taskStatus);
        statuses += taskStatus.id + "-";
        checkStatuses.add(true);
      }
      statuses = statuses.substring(0, statuses.length - 1);
      getAllCategories();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getAllCategories() async {
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
        mapCategories[dat['id']] = category;
      }

      if (widget.categoryId!.isEmpty) {
        getAllCategoriesProject(widget.projectId!, 0);
      } else {
        getAllCategoriesChild(widget.projectId!, widget.categoryId!);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getAllCategoriesProject(String project, int level) async {
    chartDatas = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getCalculateTasksCategories/' +
        project +
        "/" +
        level.toString() +
        "/" +
        statuses;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      for (var dat in data) {
        ChartData chartData = ChartData();
        chartData.name = dat['name'];
        chartData.id = dat['id'];
        chartData.total = int.parse(dat['total']);
        chartData.profit = int.parse(dat['profit']);
        totalProfit += chartData.profit;
        totalTasks += chartData.total;
        chartDatas.add(chartData);
      }
      for (int i = 0; i < chartDatas.length; i++) {
        chartDatas[i].percentTotal = chartDatas[i].total / totalTasks;
        chartDatas[i].percentProfit = chartDatas[i].profit / totalProfit;
      }
      chartColors = getColors(chartDatas.length);

      getCustomFieldsProject(project, "");
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getAllCategoriesChild(
      String project, String parentCategory) async {
    chartDatas = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getCalculateTasksCategoriesChild/' +
            project +
            "/" +
            parentCategory;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      for (var dat in data) {
        ChartData chartData = ChartData();
        chartData.name = dat['name'];
        chartData.id = dat['id'];
        chartData.total = int.parse(dat['total']);
        chartData.profit = int.parse(dat['profit']);
        totalProfit += chartData.profit;
        totalTasks += chartData.total;
        chartDatas.add(chartData);
      }
      for (int i = 0; i < chartDatas.length; i++) {
        chartDatas[i].percentTotal = chartDatas[i].total / totalTasks;
        chartDatas[i].percentProfit = chartDatas[i].profit / totalProfit;
      }
      chartColors = getColors(chartDatas.length);
      getCustomFieldsProject(project, parentCategory);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getCustomFieldsProject(
      String project, String parentCategory) async {
    fields = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

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
        field.type = dat['type'];

        if (field.type == "list") {
          mapDatasCustomField[field.id] = [];
          mapIndexCustomName[field.id] = "";
          mapTouchedIndexCustom[field.id] = -1;
          fields.add(field);
        } else if (field.type == "number") {
          mapDatasCustomFieldNumber[field.id] = [];
          mapIndexCustomNumberName[field.id] = "";
          mapTouchedIndexCustomNumber[field.id] = -1;
          fieldsNumber.add(field);
        }
      }
      if (fields.isNotEmpty) {
        await getCalculateCustomFieldChild(project, parentCategory, 0);
      }
      if (fieldsNumber.isNotEmpty) {
        await getCalculateCustomFieldNumberChild(project, parentCategory, 0);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

// cái này cũng 2 phần : tasks, profits ??? -->
// hiển thị 1 màn hình thôi :), chuẩn luôn.
// KPI, KPI2
// KPI --> 2 biểu đồ
// KPI2 --> 2 biểu đồ
  /// .... --> ok đấy (đầy đủ)

  Future<void> getCalculateCustomFieldChild(
      String project, String parentCategory, int fieldIndex) async {
    List<ChartData> chartDatasCustomField = [];
    String customField = fields[fieldIndex].id;
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();
    var url = "";
    if (parentCategory != "") {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTasksCategoryCustomField/' +
              project +
              "/" +
              parentCategory +
              "/" +
              customField;
    } else {
      url = 'http://www.vietinrace.com/srvTD/getCalculateTasksCustomField/' +
          project +
          "/" +
          customField;
    }
    final response = await http.get(Uri.parse(url));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      for (var dat in data) {
        ChartData chartData = ChartData();
        chartData.name = dat['name'];
        chartData.id = dat['id'];
        chartData.total = int.parse(dat['total']);
        chartData.profit = int.parse(dat['profit']);
        totalProfit += chartData.profit;
        totalTasks += chartData.total;
        chartDatasCustomField.add(chartData);
      }

      // cai nay bi lech ????
      for (int i = 0; i < chartDatasCustomField.length; i++) {
        if (totalTasks == 0) {
          chartDatasCustomField[i].percentTotal = 0;
        } else {
          chartDatasCustomField[i].percentTotal =
              chartDatasCustomField[i].total / totalTasks;
        }
        if (totalProfit == 0) {
          chartDatasCustomField[i].percentProfit = 0;
        } else {
          chartDatasCustomField[i].percentProfit =
              chartDatasCustomField[i].profit / totalProfit;
        }
      }
      mapDatasCustomField[customField] = chartDatasCustomField;
      //chartColors = getColors(chartDatas.length);
      // làm cái này để phải chờ xong mới gọi tiếp ??? --> for thì hay hơn, dễ hiểu
      if (fieldIndex < fields.length - 1) {
        getCalculateCustomFieldChild(project, parentCategory, fieldIndex + 1);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getCalculateCustomFieldNumberChild(
      String project, String parentCategory, int fieldIndex) async {
    List<ChartData> chartDatasCustomFieldNumber = [];
    String customField = fieldsNumber[fieldIndex].id;
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();
    var url = "";
    if (parentCategory != "") {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTasksCategoryCustomFieldNumber/' +
              project +
              "/" +
              parentCategory +
              "/" +
              customField;
      // + "/" + statuses;
    } else {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTaskCustomFieldNumber/' +
              project +
              '/0/' +
              customField +
              "/" +
              statuses;
    }
    final response = await http.get(Uri.parse(url));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      for (var dat in data) {
        ChartData chartData = ChartData();
        chartData.name = dat['name'];
        chartData.id = dat['id'];
        chartData.total = int.parse(dat['total']);
        chartData.profit = int.parse(dat[customField]);
        totalProfit += chartData.profit;
        totalTasks += chartData.total;
        chartDatasCustomFieldNumber.add(chartData);
      }

      // cai nay bi lech ????
      for (int i = 0; i < chartDatasCustomFieldNumber.length; i++) {
        chartDatasCustomFieldNumber[i].percentTotal = totalTasks == 0
            ? 0
            : chartDatasCustomFieldNumber[i].total / totalTasks;
        chartDatasCustomFieldNumber[i].percentProfit = totalProfit == 0
            ? 0
            : chartDatasCustomFieldNumber[i].profit / totalProfit;
      }

      mapDatasCustomFieldNumber[customField] = chartDatasCustomFieldNumber;
      //chartColors = getColors(chartDatas.length);
      if (fieldIndex < fieldsNumber.length - 1) {
        getCalculateCustomFieldNumberChild(
            project, parentCategory, fieldIndex + 1);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  double hue2rgb(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }

  List<int> hslToRgb(double h, double s, double l) {
    h /= 360;
    s /= 100;
    l /= 100;
    double r, g, b;

    if (s == 0) {
      r = g = b = l; // achromatic
    } else {
      double q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      var p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    return [(r * 255).round(), (g * 255).round(), (b * 255).round()];
  }

  String toHex(int x) {
    String hex = (x * 255).round().toRadixString(16);
    return hex.length == 1 ? '0' + hex : hex;
  }

  List<Color> getColors(int num) {
    int initialColor = Random().nextInt(360);
    int increment = 360 ~/ num;
    List<Color> hsls = [];
    // Color color = const Color(0x00000119); //AARRGGBB
    for (int i = 0; i < num; i++) {
      double number = double.parse(
          (initialColor + (i * increment) % 360).round().toString());
      List<int> rgbs = hslToRgb(number, 100, 50);
      String sColorNumber =
          '0xff' + toHex(rgbs[0]) + toHex(rgbs[1]) + toHex(rgbs[2]);
      hsls.add(Color(int.parse(sColorNumber)));
      //Color(0xff)
      // hsls.add(Color(number));
    }
    return hsls;
  }

  Color chooseColor(int i) {
    Color color = const Color(0xff0293ee);
    switch (i) {
      case 0:
        color = const Color(0xff0293ee);
        break;
      case 1:
        color = const Color(0xfff8b250);
        break;
      case 2:
        color = const Color(0xff845bef);
        break;
      case 3:
        color = const Color(0xff13d38e);
        break;
      case 4:
        color = const Color(0xffeb4034);
        break;
      case 5:
        color = const Color(0xffbaeb34);
        break;
      case 6:
        color = const Color(0xffdc34eb);
        break;
      default:
        color = const Color(0xff34c3eb);
    }
    return color;
  }

  Widget _buildChart(int option) {
    return Card(
      color: Colors.white,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                    pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                        if (touchedIndex >= 0) {
                          categoryChooseName = chartDatas[touchedIndex].name;
                          categoryChooseId = chartDatas[touchedIndex].id;
                        }
                      });
                    }),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: showingSectionsChart(option)),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            // cho vào vòng lặp được này
            children: showingIndicators(),
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCustom() {
    List<Widget> listChartCustom = [];
    for (int i = 0; i < fields.length; i++) {
      String customField = fields[i].id;
      listChartCustom.add(Text(fields[i].name));
      listChartCustom.add(const SizedBox(height: 10));

      listChartCustom.add(const SizedBox(height: 10));
      listChartCustom.add(const Text('Lợi Ích (Triệu Đồng)'));
      listChartCustom.add(_buildChartCustomItem(0, customField));

      listChartCustom.add(const SizedBox(height: 10));
      listChartCustom.add(const Text('Số Công Việc'));
      listChartCustom.add(_buildChartCustomItem(1, customField));
    }
    return Column(children: listChartCustom);
  }

  Widget _buildChartCustomItem(int option, String customField) {
    Widget card = Card(
      color: Colors.white,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                    pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          mapTouchedIndexCustom[customField] = -1;
                          return;
                        }
                        mapTouchedIndexCustom[customField] = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                        if (mapTouchedIndexCustom[customField]! >= 0) {
                          // showInSnackBar(
                          //     mapTouchedIndexCustom[customField].toString());
                          // categoryChooseName = chartDatas[touchedIndex].name;
                          // categoryChooseId = chartDatas[touchedIndex].id;
                        }
                      });
                    }),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections:
                        showingSectionsChartCustomField(option, customField)),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            // cho vào vòng lặp được này
            children: showingIndicatorsCustomField(customField),
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );

    return card;
  }

  Widget _buildChartCustomNumber() {
    List<Widget> listChartCustomNumber = [];
    for (int i = 0; i < fieldsNumber.length; i++) {
      String customField = fieldsNumber[i].id;
      listChartCustomNumber.add(Text(fieldsNumber[i].name));
      listChartCustomNumber.add(const SizedBox(height: 10));

      listChartCustomNumber.add(const SizedBox(height: 10));
      listChartCustomNumber.add(Text(fieldsNumber[i].name));
      listChartCustomNumber.add(_buildChartCustomItemNumber(0, customField));

      listChartCustomNumber.add(const SizedBox(height: 10));
      listChartCustomNumber.add(const Text('Số Công Việc'));
      listChartCustomNumber.add(_buildChartCustomItemNumber(1, customField));
    }
    return Column(children: listChartCustomNumber);
  }

  Widget _buildChartCustomItemNumber(int option, String customField) {
    Widget card = Card(
      color: Colors.white,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                    pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          mapTouchedIndexCustomNumber[customField] = -1;
                          return;
                        }
                        mapTouchedIndexCustomNumber[customField] =
                            pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                        if (mapTouchedIndexCustomNumber[customField]! >= 0) {
                          // showInSnackBar(
                          //     mapTouchedIndexCustom[customField].toString());
                          // categoryChooseName = chartDatas[touchedIndex].name;
                          // categoryChooseId = chartDatas[touchedIndex].id;
                        }
                      });
                    }),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: showingSectionsChartCustomFieldNumber(
                        option, customField)),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            // cho vào vòng lặp được này
            children: showingIndicatorsCustomFieldNumber(customField),
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );

    return card;
  }

  void _goToChildren() {
    //showInSnackBar(categoryChooseId);
    if (mapCategories[categoryChooseId]!.isParent == true) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TabChartPage(
                projectId: widget.projectId!,
                categoryId: categoryChooseId,
                title: categoryChooseName,
                year: widget.year!),
          ));
    } else {
      showInSnackBar("Không có danh mục con");
    }
  }

  Widget _chooseStatus() {
    List<Widget> listStatuses = [];

    if (taskStatuses.length > 4) {
      int rows = taskStatuses.length ~/ 4 + 1;
      for (int i = 0; i < rows; i++) {
        List<Widget> listStatusesRow = [];
        for (int j = 4 * i; j < 4 + 4 * i; j++) {
          Checkbox checkBox = Checkbox(
              value: checkStatuses[j],
              onChanged: (value) {
                setState(() {
                  checkStatuses[j] = value!;
                  if (checkStatuses[j]) {
                    statuses = statuses + "-" + taskStatuses[j].id;
                  } else {
                    statuses = statuses.replaceAll(taskStatuses[j].id, "");
                  }
                  statuses = statuses.replaceAll("--", "-");
                  getAllCategories();
                });
              });
          listStatusesRow.add(checkBox);
          listStatusesRow.add(Text(taskStatuses[i].name));
          listStatusesRow.add(const SizedBox(width: 10));
        }
        Row row = Row(children: listStatusesRow);
        listStatuses.add(row);
        //listStatuses.add(const SizedBox(height: 10));
      }
      return Column(children: listStatuses);
    } else {
      for (int i = 0; i < taskStatuses.length; i++) {
        Checkbox checkBox = Checkbox(
            value: checkStatuses[i],
            onChanged: (value) {
              setState(() {
                checkStatuses[i] = value!;
                if (checkStatuses[i]) {
                  statuses = statuses + "-" + taskStatuses[i].id;
                } else {
                  statuses = statuses.replaceAll(taskStatuses[i].id, "");
                }
                statuses = statuses.replaceAll("--", "-");
                getAllCategories();
              });
            });
        listStatuses.add(checkBox);
        listStatuses.add(Text(taskStatuses[i].name));
        listStatuses.add(const SizedBox(width: 10));
      }
      Row row = Row(children: listStatuses);
      return row;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title!,
        ),
      ),
      // resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
          //aspectRatio: 1.3,
          child: Column(children: [
        _chooseStatus(),
        // categoryChooseName != "" ? Text(categoryChooseName) : Text(''),
        // mapCategories[categoryChooseId]!.isParent == true
        categoryChooseId != ""
            ? ElevatedButton(
                onPressed: _goToChildren,
                child: Text('Xem danh mục con $categoryChooseName'),
              )
            : const Text(''),
        const SizedBox(height: 10),
        const Text('Lợi Ích (Triệu Đồng)'),
        // SizedBox(height: 10),
        _buildChart(0),
        const SizedBox(height: 10),
        const Text('Số Công Việc'),
        _buildChart(1),
        _buildChartCustomNumber(),
        const Text('Custom Field'),
        _buildChartCustom(),
      ])),
    );
  }

  List<Widget> showingIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < chartDatas.length; i++) {
      indicators.add(Indicator(
        color: chooseColor(i),
        text: chartDatas[i].name,
        isSquare: true,
      ));

      indicators.add(const SizedBox(
        height: 4,
      ));
    }
    return indicators;
  }

  List<PieChartSectionData> showingSectionsChart(int option) {
    List<PieChartSectionData> listPies = [];
    double valuePercent = 0;
    String nameItem = "";

    for (int i = 0; i < chartDatas.length; i++) {
      if (option == 0) {
        valuePercent = chartDatas[i].percentProfit;
        nameItem = chartDatas[i].profit.toString();
      } else {
        valuePercent = chartDatas[i].percentTotal;
        nameItem = chartDatas[i].total.toString();
      }
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      Color color = chooseColor(i);
      PieChartSectionData sectionData = PieChartSectionData(
        color: color,
        value: valuePercent,
        title: nameItem,
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff)),
      );
      listPies.add(sectionData);
    }
    return listPies;
  }

  List<Widget> showingIndicatorsCustomField(String customField) {
    List<Widget> indicatorsCustomField = [];
    for (int i = 0; i < mapDatasCustomField[customField]!.length; i++) {
      indicatorsCustomField.add(Indicator(
        color: chooseColor(i),
        text: mapDatasCustomField[customField]![i].name,
        isSquare: true,
      ));

      indicatorsCustomField.add(const SizedBox(
        height: 4,
      ));
    }
    return indicatorsCustomField;
  }

  List<PieChartSectionData> showingSectionsChartCustomField(
      int option, String customField) {
    List<PieChartSectionData> listPies = [];
    double valuePercent = 0;
    String nameItem = "";

    for (int i = 0; i < mapDatasCustomField[customField]!.length; i++) {
      if (option == 0) {
        valuePercent = mapDatasCustomField[customField]![i].percentProfit;
        nameItem = mapDatasCustomField[customField]![i].profit.toString();
      } else {
        valuePercent = mapDatasCustomField[customField]![i].percentTotal;
        nameItem = mapDatasCustomField[customField]![i].total.toString();
      }
      final isTouched = i == mapTouchedIndexCustom[customField];
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      Color color = chooseColor(i);
      PieChartSectionData sectionData = PieChartSectionData(
        color: color,
        value: valuePercent,
        title: nameItem,
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff)),
      );
      listPies.add(sectionData);
    }
    return listPies;
  }

  List<Widget> showingIndicatorsCustomFieldNumber(String customField) {
    List<Widget> indicatorsCustomFieldNumber = [];
    for (int i = 0; i < mapDatasCustomFieldNumber[customField]!.length; i++) {
      indicatorsCustomFieldNumber.add(Indicator(
        color: chooseColor(i),
        text: mapDatasCustomFieldNumber[customField]![i].name,
        isSquare: true,
      ));

      indicatorsCustomFieldNumber.add(const SizedBox(
        height: 4,
      ));
    }
    return indicatorsCustomFieldNumber;
  }

  List<PieChartSectionData> showingSectionsChartCustomFieldNumber(
      int option, String customField) {
    List<PieChartSectionData> listPies = [];
    double valuePercent = 0;
    String nameItem = "";

    for (int i = 0; i < mapDatasCustomFieldNumber[customField]!.length; i++) {
      if (option == 0) {
        valuePercent = mapDatasCustomFieldNumber[customField]![i].percentProfit;
        nameItem = mapDatasCustomFieldNumber[customField]![i].profit.toString();
      } else {
        valuePercent = mapDatasCustomFieldNumber[customField]![i].percentTotal;
        nameItem = mapDatasCustomFieldNumber[customField]![i].total.toString();
      }
      final isTouched = i == mapTouchedIndexCustomNumber[customField];
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      Color color = chooseColor(i);
      PieChartSectionData sectionData = PieChartSectionData(
        color: color,
        value: valuePercent,
        title: nameItem,
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff)),
      );
      listPies.add(sectionData);
    }
    return listPies;
  }
}
