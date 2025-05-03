import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodel/process_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';

class DashboardWidget extends StatelessWidget {
  final ProcessViewModel processVM;
  final SubProcessViewModel subProcessVM;

  const DashboardWidget({
    Key? key,
    required this.processVM,
    required this.subProcessVM,
  }) : super(key: key);

  Future<Map<String, List<int>>> _loadData() async {
    // Load processes
    final procs = await processVM.getByUserId(/* current user id, replace */ 0);
    final subs = await subProcessVM.getAll();

    // Helper to count statuses
    List<int> countByStatus(List items) {
      var created = items.where((e) => e.statusId == 1).length;
      var started = items.where((e) => e.statusId == 2).length;
      var finished = items.where((e) => e.statusId == 3).length;
      return [created, started, finished];
    }

    final procCounts = countByStatus(procs);
    final subCounts = countByStatus(subs);

    return {
      'process': procCounts,
      'subprocess': subCounts,
    };
  }

  BarChartGroupData _makeGroup(int x, int y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y.toDouble(),
        width: 20,
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    ]);
  }

  BarChartData _buildBarChart(List<int> counts) {
    // counts: [created, started, finished]
    final colors = [
      Colors.lightBlueAccent,
      Colors.yellowAccent,
      Colors.lightGreenAccent,
    ];
    final groups = List.generate(counts.length,
      (i) => _makeGroup(i, counts[i], colors[i]),
    );
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: groups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const labels = ['Created', 'Started', 'Finished'];
              return Text(labels[value.toInt()]);
            },
          ),
        ),
      ),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<int>>>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Processes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          _buildBarChart(data['process']!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Sub-Processes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          _buildBarChart(data['subprocess']!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
