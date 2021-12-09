import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kanban_dashboard/task_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'project_list.dart';
import 'category_list.dart';
import 'indicator.dart';
import 'login.dart';
import 'register.dart';
import 'splashscreen.dart';
import 'task_list.dart';
import 'task_type_list.dart';
// import 'package:graphic/graphic.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/kanban': (context) => const DashboardPage2(),
        '/list_project': (context) => const ProjectListScreen(),
        '/list_category': (context) => const CategoryListScreen(),
        '/list_task_type': (context) => const TaskTypeListScreen(),
        '/task_status': (context) => const TaskStatusScreen(),
        '/list_task': (context) => const TaskListScreen(),
      },

      //home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  // _DashboardPageState2 createState() => _DashboardPageState2();
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Index 0: Home',
      style: optionStyle,
    ),
    Text(
      'Index 1: Business',
      style: optionStyle,
    ),
    Text(
      'Index 2: School',
      style: optionStyle,
    ),
    Text(
      'Index 3: Settings',
      style: optionStyle,
    ),
  ];

  late SharedPreferences prefs;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    getSharedPreference();
  }

  void getSharedPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    final drawerHeader = UserAccountsDrawerHeader(
      accountName: Text(
        'User Name',
      ),
      accountEmail: Text(
        'longtdbk@gmail.com',
      ),
      currentAccountPicture: CircleAvatar(
        child: FlutterLogo(size: 42.0),
      ),
    );
    final drawerItems = ListView(
      children: [
        drawerHeader,
        ListTile(
          title: const Text(
            'Item One',
          ),
          leading: const Icon(Icons.favorite),
          onTap: () {
            //Navigator.pop(context);
            Navigator.pushNamed(context, '/kanban');
          },
        ),
        // ListTile(
        //   title: const Text(
        //     'Item Two',
        //   ),
        //   leading: const Icon(Icons.comment),
        //   onTap: () {
        //     Navigator.pop(context); //trả về như cũ nhé
        //   },
        // ),
        ListTile(
          title: const Text(
            'Quản lý Dự án',
          ),
          leading: const Icon(Icons.pan_tool),
          onTap: () {
            //Navigator.pop(context);
            Navigator.pushNamed(context, '/list_project');
          },
        ),
        ListTile(
          title: const Text(
            'Quản trị Danh Mục',
          ),
          leading: const Icon(Icons.pan_tool),
          onTap: () {
            //Navigator.pop(context);
            Navigator.pushNamed(context, '/list_category');
          },
        ),
        ListTile(
          title: const Text(
            'Quản trị Loại CV',
          ),
          leading: const Icon(Icons.pan_tool),
          onTap: () {
            //Navigator.pop(context);
            Navigator.pushNamed(context, '/list_task_type');
          },
        ),
        ListTile(
          title: const Text(
            'Quản trị Trạng Thái',
          ),
          leading: const Icon(Icons.pan_tool),
          onTap: () {
            //Navigator.pop(context);
            Navigator.pushNamed(context, '/task_status');
          },
        ),
        ListTile(
          title: const Text(
            'Quản trị công việc',
          ),
          leading: const Icon(Icons.work),
          onTap: () {
            //Navigator.pop(context);
            Navigator.pushNamed(context, '/list_task');
          },
        ),
        ListTile(
          title: const Text(
            'Thoát',
          ),
          leading: const Icon(Icons.exit_to_app),
          onTap: () {
            //Navigator.pop(context);
            prefs.remove('email');
            Navigator.pushNamed(context, '/login');
          },
        ),
      ],
    );

    // const data = [
    //   {'category': 'Shirts', 'sales': 5},
    //   {'category': 'Cardigans', 'sales': 20},
    //   {'category': 'Chiffons', 'sales': 36},
    //   {'category': 'Pants', 'sales': 10},
    //   {'category': 'Heels', 'sales': 10},
    //   {'category': 'Socks', 'sales': 20},
    // ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
        ),
      ),
      body:
          /*
      const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Text(
            'Thử xem ra gì nào',
          ),
        ),
      ),
      */
          //     Scrollbar(
          //   child: ListView(
          //     restorationId: 'list_demo_list_view',
          //     padding: const EdgeInsets.symmetric(vertical: 8),
          //     children: [
          //       for (int index = 1; index < 21; index++)
          //         ListTile(
          //           leading: ExcludeSemantics(
          //             child: CircleAvatar(child: Text('$index')),
          //           ),
          //           title: Text(
          //             'Item',
          //           ),
          //           subtitle: Text('Secondary text'),
          //         ),
          //     ],
          //   ),
          // ),
          Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Business',
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'School',
            backgroundColor: Colors.purple,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
            backgroundColor: Colors.pink,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),

      // so simple , drawers is
      drawer: Drawer(
        child: drawerItems,
      ),
    );
  }
}

class DashboardPage2 extends StatefulWidget {
  const DashboardPage2({Key? key}) : super(key: key);

  @override
  // _DashboardPageState2 createState() => _DashboardPageState2();
  _DashboardPageState2 createState() => _DashboardPageState2();
}

class _DashboardPageState2 extends State {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kanban',
        ),
      ),
      body: AspectRatio(
        aspectRatio: 1.3,
        child: Card(
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
                          });
                        }),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: showingSections()),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                // cho vào vòng lặp được này
                children: const <Widget>[
                  Indicator(
                    color: Color(0xff0293ee),
                    text: 'First',
                    isSquare: true,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Indicator(
                    color: Color(0xfff8b250),
                    text: 'Second',
                    isSquare: true,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Indicator(
                    color: Color(0xff845bef),
                    text: 'Third',
                    isSquare: true,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Indicator(
                    color: Color(0xff13d38e),
                    text: 'Fourth',
                    isSquare: true,
                  ),
                  SizedBox(
                    height: 18,
                  ),
                ],
              ),
              const SizedBox(
                width: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xff0293ee),
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xfff8b250),
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xff845bef),
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        case 3:
          return PieChartSectionData(
            color: const Color(0xff13d38e),
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        default:
          throw Error();
      }
    });
  }
}
