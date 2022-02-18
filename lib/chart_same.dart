import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'chart_tab.dart';
import 'helper/categories_data.dart';
import 'helper/chart_data.dart';
import 'helper/custom_field_data.dart';
import 'helper/task_status_data.dart';
import 'indicator.dart';
import 'util/bottom_picker_custom.dart';

class ChartSameCodeScreen extends StatefulWidget {
  final String? projectId;
  final String? title;
  final String? categoryId;
  final String? year;
  const ChartSameCodeScreen(
      {Key? key, this.projectId, this.categoryId, this.title, this.year})
      : super(key: key);

  @override
  // _DashboardPageState2 createState() => _DashboardPageState2();
  _ChartSameCodeScreenState createState() => _ChartSameCodeScreenState();
}

class _ChartSameCodeScreenState extends State<ChartSameCodeScreen>
    with AutomaticKeepAliveClientMixin {
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

  DateTime dateFrom = DateTime.now();
  DateTime dateTo = DateTime.now();

  @override
  void initState() {
    super.initState();

    String dateStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String year = dateStr.split("-")[0];
    String beginYearDateString = year + "-" + "01-01";
    String endYearDateString = year + "-" + "12-31";
    dateFrom = DateFormat("yyyy-MM-dd").parse(beginYearDateString);
    dateTo = DateFormat("yyyy-MM-dd").parse(endYearDateString);

    if (taskStatuses.isEmpty) {
      getTaskStatus();
    }
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
        getAllCategoriesSameNameProject(widget.projectId!, 1);
      } else {
        getAllCategoriesChild(widget.projectId!, widget.categoryId!);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getAllCategoriesSameNameProject(
      String project, int level) async {
    chartDatas = [];
    setState(() {
      isLoading = true;
    });
    var outputFormat = DateFormat('yyyy-MM-dd');
    var dateToStr = outputFormat.format(dateTo);
    var dateFromStr = outputFormat.format(dateFrom);

    // final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getCalculateTasksCategoriesSameName/' +
            project +
            "/" +
            level.toString() +
            "/" +
            statuses +
            "/" +
            dateFromStr +
            "/" +
            dateToStr;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      int totalHasProfit = 0;
      for (var dat in data) {
        ChartData chartData = ChartData();
        chartData.name = dat['name'];
        chartData.id = dat['id'];
        chartData.total = int.parse(dat['total']);
        chartData.profit = int.parse(dat['profit']);
        chartData.totalHasProfit = int.parse(dat['total_profit']);
        totalProfit += chartData.profit;
        totalTasks += chartData.total;
        totalHasProfit += chartData.totalHasProfit;
        chartDatas.add(chartData);
      }
      for (int i = 0; i < chartDatas.length; i++) {
        chartDatas[i].percentTotal = chartDatas[i].total / totalTasks;
        chartDatas[i].percentProfit = chartDatas[i].profit / totalProfit;
        chartDatas[i].percentTotalHasProfit =
            chartDatas[i].totalHasProfit / totalHasProfit;
      }
      chartColors = getColors(chartDatas.length);

      await getCustomFieldsProject(project, "");
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getAllCategoriesChild(String project, String category) async {
    chartDatas = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();
    var outputFormat = DateFormat('yyyy-MM-dd');
    var dateToStr = outputFormat.format(dateTo);
    var dateFromStr = outputFormat.format(dateFrom);

    var url =
        'http://www.vietinrace.com/srvTD/getCalculateTasksCategoriesChildSameName/' +
            project +
            "/" +
            category +
            "/" +
            statuses +
            "/" +
            dateFromStr +
            "/" +
            dateToStr;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      int totalHasProfit = 0;
      for (var dat in data) {
        ChartData chartData = ChartData();
        chartData.name = dat['name'];
        chartData.id = dat['id'];
        chartData.total = int.parse(dat['total']);
        chartData.profit = int.parse(dat['profit']);
        chartData.totalHasProfit = int.parse(dat['total_profit']);
        totalProfit += chartData.profit;
        totalTasks += chartData.total;
        totalHasProfit += chartData.totalHasProfit;
        chartDatas.add(chartData);
      }
      for (int i = 0; i < chartDatas.length; i++) {
        chartDatas[i].percentTotal = chartDatas[i].total / totalTasks;
        chartDatas[i].percentProfit = chartDatas[i].profit / totalProfit;
        chartDatas[i].percentTotalHasProfit =
            chartDatas[i].totalHasProfit / totalHasProfit;
      }
      chartColors = getColors(chartDatas.length);
      await getCustomFieldsProject(project, category);
    } else {
      showInSnackBar(
          "Có lỗi xảy ra , có thể do kết nối mạng phần dữ liệu chính!");
    }
  }

  Future<void> getCustomFieldsProject(
      String project, String parentCategory) async {
    fields = [];
    fieldsNumber = [];
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

    var outputFormat = DateFormat('yyyy-MM-dd');
    var dateToStr = outputFormat.format(dateTo);
    var dateFromStr = outputFormat.format(dateFrom);

    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();
    var url = "";
    if (parentCategory != "") {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTasksCategoryCustomFieldListSameCode/' +
              project +
              "/" +
              parentCategory +
              "/" +
              customField +
              "/" +
              statuses +
              "/" +
              dateFromStr +
              "/" +
              dateToStr;
    } else {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTaskCustomFieldListSameCode/' +
              project +
              '/1/' +
              customField +
              "/" +
              statuses +
              "/" +
              dateFromStr +
              "/" +
              dateToStr;
    }
    final responseCF = await http.get(Uri.parse(url));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    if (responseCF.statusCode == 200) {
      var jsonCF = jsonDecode(responseCF.body);
      var dataCustomField = jsonCF['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      for (var datCF in dataCustomField) {
        ChartData chartData = ChartData();
        chartData.name = datCF['name'];
        chartData.id = datCF['id'];
        chartData.total = int.parse(datCF['total']);
        chartData.profit =
            datCF['profit'] == 'undefined' ? 0 : int.parse(datCF['profit']);
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
      showInSnackBar(
          "Có lỗi xảy ra , có thể do kết nối mạng phần dữ liệu tùy biến !");
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
    var outputFormat = DateFormat('yyyy-MM-dd');
    var dateToStr = outputFormat.format(dateTo);
    var dateFromStr = outputFormat.format(dateFrom);
    var url = "";
    if (parentCategory != "") {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTasksCategoryCustomFieldNumberSameCode/' +
              project +
              "/" +
              parentCategory +
              "/" +
              customField +
              "/" +
              statuses +
              "/" +
              dateFromStr +
              "/" +
              dateToStr;
    } else {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTaskCustomFieldNumberSameCode/' +
              project +
              '/1/' +
              customField +
              "/" +
              statuses +
              "/" +
              dateFromStr +
              "/" +
              dateToStr;
    }
    final responseNb = await http.get(Uri.parse(url));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    if (responseNb.statusCode == 200) {
      var jsonNb = jsonDecode(responseNb.body);
      var dataNumber = jsonNb['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      for (var datNb in dataNumber) {
        ChartData chartData = ChartData();
        chartData.name = datNb['name'];
        chartData.id = datNb['id'];
        chartData.total = int.parse(datNb['total']);
        chartData.profit = datNb[customField] == 'undefined'
            ? 0
            : int.parse(datNb[customField]);
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
      showInSnackBar(
          "Có lỗi xảy ra , có thể do kết nối mạng phần lấy dữ liệu trường số !");
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

  Widget _buildHeadline(String headline, Color color) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    Widget buildDivider() => Container(
          height: 2,
          //color: Colors.grey.shade300, Colors.lightBlue
          color: color,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        buildDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
              child: Text(
            headline,
            // textAlign: TextAlign.center,
            style: textTheme.bodyText1?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )),
        ),
        buildDivider(),
        const SizedBox(height: 16),
      ],
    );
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
      case 7:
        color = const Color(0xffdd6b66);
        break;
      case 8:
        color = const Color(0xff759aa0);
        break;
      case 9:
        color = const Color(0xffe69d87);
        break;
      case 10:
        color = const Color(0xff8dc1a9);
        break;
      case 11:
        color = const Color(0xffea7e53);
        break;
      case 12:
        color = const Color(0xffeedd78);
        break;
      case 13:
        color = const Color(0xff73a373);
        break;
      case 14:
        color = const Color(0xff73b9bc);
        break;
      case 15:
        color = const Color(0xff7289ab);
        break;

      default:
        color = const Color(0xff91ca8c);
    }
    return color;
  }

  Widget _buildChart(int option) {
    List<PieChartSectionData> listPies = showingSectionsChart(option);
    return listPies.isEmpty
        ? const SizedBox(
            height: 5,
          )
        : Card(
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
                          pieTouchData: PieTouchData(touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
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
                                categoryChooseName =
                                    chartDatas[touchedIndex].name;
                                categoryChooseId = chartDatas[touchedIndex].id;
                              }
                            });
                          }),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          sectionsSpace: 0,
                          centerSpaceRadius: 30,
                          sections: showingSectionsChart(option)),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // cho vào vòng lặp được này
                  children: showingIndicators(option),
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

      listChartCustom.add(_buildHeadline(fields[i].name, Colors.lightBlue));
      // listChartCustom.add(Text(fields[i].name));
      listChartCustom.add(const SizedBox(height: 10));

      listChartCustom.add(const SizedBox(height: 10));
      listChartCustom.add(const Text('Số Công Việc'));
      listChartCustom.add(_buildChartCustomItem(1, customField));

      listChartCustom.add(const SizedBox(height: 10));
      listChartCustom.add(const Text('Lợi Ích (Triệu Đồng)'));
      listChartCustom.add(_buildChartCustomItem(0, customField));
    }
    return Column(children: listChartCustom);
  }

  Widget _buildChartCustomItem(int option, String customField) {
    List<PieChartSectionData> listPies =
        showingSectionsChartCustomField(option, customField);
    return listPies.isEmpty
        ? const SizedBox(
            height: 5,
          )
        :
        // Widget card = Card(
        Card(
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
                          pieTouchData: PieTouchData(touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                mapTouchedIndexCustom[customField] = -1;
                                return;
                              }
                              mapTouchedIndexCustom[customField] =
                                  pieTouchResponse
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
                          sections: showingSectionsChartCustomField(
                              option, customField)),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // cho vào vòng lặp được này
                  children: showingIndicatorsCustomField(option, customField),
                ),
                const SizedBox(
                  width: 28,
                ),
              ],
            ),
          );

    // return card;
  }

  Widget _buildChartCustomNumber() {
    List<Widget> listChartCustomNumber = [];
    for (int i = 0; i < fieldsNumber.length; i++) {
      String customField = fieldsNumber[i].id;
      // listChartCustomNumber.add(Text(fieldsNumber[i].name));
      listChartCustomNumber
          .add(_buildHeadline(fieldsNumber[i].name, Colors.lightBlue));
      listChartCustomNumber.add(const SizedBox(height: 10));

      // listChartCustomNumber.add(const SizedBox(height: 10));
      listChartCustomNumber.add(_buildHeadline('Số Công Việc', Colors.lime));

      // listChartCustomNumber.add(const Text('Số Công Việc'));
      listChartCustomNumber.add(_buildChartCustomItemNumber(1, customField));

      listChartCustomNumber.add(const SizedBox(height: 10));
      listChartCustomNumber.add(Text(fieldsNumber[i].name));
      listChartCustomNumber.add(_buildChartCustomItemNumber(0, customField));
    }
    return Column(children: listChartCustomNumber);
  }

  Widget _buildChartCustomItemNumber(int option, String customField) {
    List<PieChartSectionData> listPies =
        showingSectionsChartCustomFieldNumber(option, customField);
    return listPies.isEmpty
        ? const SizedBox(
            height: 5,
          )
        :
        // Widget card = Card(
        Card(
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
                          pieTouchData: PieTouchData(touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
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
                              if (mapTouchedIndexCustomNumber[customField]! >=
                                  0) {
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
                          centerSpaceRadius: 30,
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
                  children:
                      showingIndicatorsCustomFieldNumber(option, customField),
                ),
                const SizedBox(
                  width: 28,
                ),
              ],
            ),
          );

    // return card;
  }

  void _goToChildren() {
    //showInSnackBar(categoryChooseId);
    // if (mapCategories[categoryChooseId]!.isParent == true) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TabChartPage(
              projectId: widget.projectId!,
              categoryId: categoryChooseId,
              title: categoryChooseName,
              year: widget.year!,
              indexTab: 1),
        ));
    // } else {
    showInSnackBar("Không có danh mục con");
    // }
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

  Widget _chooseDateTime() {
    List<Widget> listDateTimes = [];
    listDateTimes.add(_buildDatePicker(context, 'Từ Ngày', 1));
    listDateTimes.add(_buildDatePicker(context, 'Đến Ngày', 2));
    listDateTimes.add(isLoading
        ? const LinearProgressIndicator()
        : ElevatedButton(
            onPressed: getAllCategories,
            child: const Text('Làm mới dữ liệu'),
          ));
    return Column(children: listDateTimes);
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
        _chooseDateTime(),
        // categoryChooseName != "" ? Text(categoryChooseName) : Text(''),
        // mapCategories[categoryChooseId]!.isParent == true
        categoryChooseId != ""
            ? ElevatedButton(
                onPressed: _goToChildren,
                child: Text('Xem danh mục con $categoryChooseName'),
              )
            : const Text(''),
        const SizedBox(height: 10),
        const Text('Số lượng công việc'),
        _buildChart(1),

        const SizedBox(height: 10),
        const Text('Số lượng công việc có Lợi ích'),
        _buildChart(2),
        // SizedBox(height: 10),

        const SizedBox(height: 10),
        const Text('Lợi ích (Triệu Đồng)'),
        _buildChart(0),
        _buildChartCustomNumber(),
        // const Text('Custom Field'),
        _buildChartCustom(),
      ])),
    );
  }

  List<Widget> showingIndicators(int option) {
    List<Widget> indicators = [];
    for (int i = 0; i < chartDatas.length; i++) {
      if ((option == 0 && chartDatas[i].percentProfit > 0) ||
          (option == 1 && chartDatas[i].percentTotal > 0) ||
          ((option == 2 && chartDatas[i].percentTotalHasProfit > 0))) {
        indicators.add(Indicator(
          color: chooseColor(i),
          text: chartDatas[i].name.length > 25
              ? chartDatas[i].name.substring(0, 25)
              : chartDatas[i].name,
          isSquare: true,
        ));

        indicators.add(const SizedBox(
          height: 4,
        ));
      }
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
      } else if (option == 1) {
        valuePercent = chartDatas[i].percentTotal;
        nameItem = chartDatas[i].total.toString();
      } else if (option == 2) {
        valuePercent = chartDatas[i].percentTotalHasProfit;
        nameItem = chartDatas[i].totalHasProfit.toString();
      }

      if (nameItem.length >= 4 && nameItem.length <= 6) {
        nameItem = (double.parse(nameItem) / 1000).toStringAsFixed(2) + "K";
      } else if (nameItem.length > 6) {
        nameItem = (double.parse(nameItem) / 1000000).toStringAsFixed(2) + "M";
      }
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 13.0;
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
      if (nameItem != '0') {
        listPies.add(sectionData);
      }
    }
    return listPies;
  }

  List<Widget> showingIndicatorsCustomField(int option, String customField) {
    List<Widget> indicatorsCustomField = [];

    for (int i = 0; i < mapDatasCustomField[customField]!.length; i++) {
      if ((option == 0 &&
              mapDatasCustomField[customField]![i].percentProfit > 0) ||
          (option == 1 &&
              mapDatasCustomField[customField]![i].percentTotal > 0)) {
        indicatorsCustomField.add(Indicator(
          color: chooseColor(i),
          text: mapDatasCustomField[customField]![i].name.length > 25
              ? mapDatasCustomField[customField]![i].name.substring(0, 25)
              : mapDatasCustomField[customField]![i].name,
          isSquare: true,
        ));

        indicatorsCustomField.add(const SizedBox(
          height: 4,
        ));
      }
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

      if (nameItem.length >= 4 && nameItem.length <= 6) {
        nameItem = (double.parse(nameItem) / 1000).toStringAsFixed(2) + "K";
      } else if (nameItem.length > 6) {
        nameItem = (double.parse(nameItem) / 1000000).toStringAsFixed(2) + "M";
      }

      final isTouched = i == mapTouchedIndexCustom[customField];
      final fontSize = isTouched ? 25.0 : 13.0;
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
      if (nameItem != "0") {
        listPies.add(sectionData);
      }
    }

    return listPies;
  }

  List<Widget> showingIndicatorsCustomFieldNumber(
      int option, String customField) {
    List<Widget> indicatorsCustomFieldNumber = [];
    for (int i = 0; i < mapDatasCustomFieldNumber[customField]!.length; i++) {
      if ((option == 0 &&
              mapDatasCustomFieldNumber[customField]![i].percentProfit > 0) ||
          (option == 1 &&
              mapDatasCustomFieldNumber[customField]![i].percentTotal > 0)) {
        indicatorsCustomFieldNumber.add(Indicator(
          color: chooseColor(i),
          text: mapDatasCustomFieldNumber[customField]![i].name.length > 25
              ? mapDatasCustomFieldNumber[customField]![i].name.substring(0, 25)
              : mapDatasCustomFieldNumber[customField]![i].name,
          isSquare: true,
        ));

        indicatorsCustomFieldNumber.add(const SizedBox(
          height: 4,
        ));
      }
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
      if (nameItem.length >= 4 && nameItem.length <= 6) {
        nameItem = (double.parse(nameItem) / 1000).toStringAsFixed(2) + "K";
      } else if (nameItem.length > 6) {
        nameItem = (double.parse(nameItem) / 1000000).toStringAsFixed(2) + "M";
      }

      final isTouched = i == mapTouchedIndexCustomNumber[customField];
      final fontSize = isTouched ? 25.0 : 13.0;
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
      if (nameItem != "0") {
        listPies.add(sectionData);
      }
    }
    return listPies;
  }

  void _showPicker({
    @required BuildContext? context,
    @required Widget? child,
  }) {
    final themeData = CupertinoTheme.of(context!);
    final dialogBody = CupertinoTheme(
      data: themeData,
      child: child!,
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => dialogBody,
    );
  }

  Widget _buildDatePicker(BuildContext context, String title, int option) {
    DateTime date = DateTime.now();

    // var outputFormat = DateFormat('dd/MM/yyyy');
    //taskData.dateStart = outputFormat.format(dateStart);

    if (option == 1) {
      date = dateFrom;
    } else if (option == 2) {
      date = dateTo;
    }
    // if (dateText != "") {
    //   date = DateTime.parse(dateText);
    // }

    return GestureDetector(
      onTap: () {
        _showPicker(
          context: context,
          child: BottomPickerCustom(
            child: CupertinoDatePicker(
              backgroundColor:
                  CupertinoColors.systemBackground.resolveFrom(context),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: date,
              onDateTimeChanged: (newDateTime) {
                setState(() => {
                      if (option == 1)
                        {dateFrom = newDateTime}
                      else if (option == 2)
                        {dateTo = newDateTime}
                    });
              },
            ),
          ),
        );
      },
      child: MenuPickerCustom(children: [
        //const Icon(Icons.access_time_outlined),
        Text(title),
        Text(
          DateFormat.yMMMMd().format(date),
          style: const TextStyle(color: CupertinoColors.inactiveGray),
        ),
      ]),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
