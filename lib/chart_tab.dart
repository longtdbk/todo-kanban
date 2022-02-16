import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:kanban_dashboard/chart.dart';

// import 'helper/chart_data.dart';
// import 'indicator.dart';
import 'bar_chart.dart';
import 'chart_same.dart';
import 'line_chart.dart';

class TabChartPage extends StatefulWidget {
  final String? projectId;
  final String? categoryId;
  final String? title;
  final String? year;
  const TabChartPage(
      {Key? key, this.projectId, this.categoryId, this.title, this.year})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TabChartPageState();
}

class TabChartPageState extends State<TabChartPage> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  final List<Widget> _listBody = [];

  @override
  void initState() {
    super.initState();
    createTabItem();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void createTabItem() {
    _listBody.add(ChartScreen(
        projectId: widget.projectId,
        categoryId: widget.categoryId,
        title: widget.title,
        year: widget.year));

    _listBody.add(ChartSameCodeScreen(
        projectId: widget.projectId,
        categoryId: widget.categoryId,
        title: widget.title,
        year: widget.year));

    _listBody.add(LineChartPage(
        projectId: widget.projectId,
        categoryId: widget.categoryId,
        title: widget.title,
        year: widget.year));
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);
    return Scaffold(
        // appBar: AppBar(
        //   title: const Text(
        //     'Biểu đồ',
        //   ),
        // ),
        // body: Center(
        //   child: _listBody.elementAt(_selectedIndex),
        // ),
        body: IndexedStack(index: _selectedIndex, children: _listBody),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: 'Pie Chart',
              backgroundColor: Colors.red,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_sharp),
              label: 'PieChart Same Code ',
              backgroundColor: Colors.green,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Line Chart ',
              backgroundColor: Colors.green,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ));
  }
}
