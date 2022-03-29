class ChartData {
  String name = '';
  String id = '';
  int total = 0;
  double percentTotal = 0;
  int profit = 0;
  double percentProfit = 0;
  int totalHasProfit = 0;
  double percentTotalHasProfit = 0;
  //CategoriesData();
}

class ChartDataMonth {
  List<ChartData> chartDatas = [];
  String month = '';
  int total = 0;
  //double percentTotal = 0;
  int profit = 0;
  //double percentProfit = 0;
}

class UserProjectsInfoData {
  int tasks = 0;
  int tasksShare = 0;
  int projects = 0;
  int projectsShare = 0;
  int users = 0;
}
