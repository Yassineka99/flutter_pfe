import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/workflow.dart';
import '../model/process.dart';
import '../model/sub_process.dart';
import '../viewmodel/workflow_view_model.dart';
import '../viewmodel/process_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final WorkflowViewModel _workflowVM = WorkflowViewModel();
  final ProcessViewModel _processVM = ProcessViewModel();
  final SubProcessViewModel _subProcessVM = SubProcessViewModel();
  List<Workflow> _workflows = [];
  bool _isPieChart = true;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

    void _toggleChartType() {
    setState(() {
      _isPieChart = !_isPieChart;
    });
  }
  Future<Map<String, Map<int, int>>> _loadWorkflowData(Workflow workflow) async {
    try {
      // 1. Get processes for this workflow
      final processes = await _processVM.getByWorkflowId(workflow.id!);
      
      // 2. Get sub-processes for each process
      final allSubs = await Future.wait(
        processes.map((p) => _subProcessVM.getByProcessId(p.id!))
      );

      // 3. Combine sub-processes
    final subProcesses = allSubs.expand((s) => s).toList();


    return {
      'process': _getStatusCounts(processes, (p) => p.statusId),
      'subProcess': _getStatusCounts(subProcesses, (sp) => sp.statusId),
    };
    } catch (e) {
      print('Error loading workflow data: $e');
      return {'process': {}, 'subProcess': {}};
    }
  }
    Map<int, int> _getStatusCounts<T>(List<T> items, int? Function(T) getStatus) {
    return {
      1: items.where((i) => getStatus(i) == 1).length,
      2: items.where((i) => getStatus(i) == 2).length,
      3: items.where((i) => getStatus(i) == 3).length,
    };
  }
  Future<void> _loadData() async {
    try {
      final workflows = await _workflowVM.fetchAllWorkflows();
      if (mounted) {
        setState(() {
          _workflows = workflows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading data: $e');
    }
  }
  Color _getStatusColor(int status) {
    switch (status) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(int status, BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    switch (status) {
      case 1: return intl.created;
      case 2: return intl.started;
      case 3: return intl.finished;
      default: return intl.unknown;
    }
  }

  Widget _buildChart(Map<int, int> statusCounts, String title, BuildContext context) {
    if (_isPieChart) {
      return _buildPieChart(statusCounts, title, context);
    } else {
      return _buildBarChart(statusCounts, title, context);
    }
  }
  
  Widget _buildPieChart(Map<int, int> statusCounts, String title, BuildContext context) {
    final hasData = statusCounts.values.any((v) => v > 0);
    final sections = statusCounts.entries.map((entry) {
      return PieChartSectionData(
        color: _getStatusColor(entry.key),
        value: entry.value.toDouble(),
        title: hasData ? '${entry.value}' : '',
        radius: 30,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: hasData 
              ? PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 0,
                    startDegreeOffset: 180,
                  ),
                )
              : Center(child: Text(AppLocalizations.of(context)!.error)),
        ),
      ],
    );
  }

Widget _buildBarChart(Map<int, int> statusCounts, String title, BuildContext context) {
  // Create separate bars for each status
  final List<BarChartGroupData> barGroups = [
    BarChartGroupData(
      x: 0,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: statusCounts[1]?.toDouble() ?? 0,
          color: _getStatusColor(1),
          width: 20,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: statusCounts.values.fold(0, (a, b) => a > b ? a : b).toDouble(),
            color: Colors.grey[200],
          ),
        ),
      ],
    ),
    BarChartGroupData(
      x: 1,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: statusCounts[2]?.toDouble() ?? 0,
          color: _getStatusColor(2),
          width: 20,
        ),
      ],
    ),
    BarChartGroupData(
      x: 2,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: statusCounts[3]?.toDouble() ?? 0,
          color: _getStatusColor(3),
          width: 20,
        ),
      ],
    ),
  ];

  return Column(
    children: [
      Text(title, style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      )),
      const SizedBox(height: 8),
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: statusCounts.values.fold(0, (a, b) => a > b ? a : b).toDouble(),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final status = value.toInt() + 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _getStatusLabel(status, context),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
      const SizedBox(height: 8),
      _buildValueLabels(statusCounts, context),
    ],
  );
}

Widget _buildValueLabels(Map<int, int> counts, BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [1, 2, 3].map((status) {
      final value = counts[status] ?? 0;
      return Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStatusLabel(status, context),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }).toList(),
  );
}

// 1. Update the _buildWorkflowCharts method
Widget _buildWorkflowCharts(Workflow workflow, BuildContext context) {
  final intl = AppLocalizations.of(context)!;
  
  return FutureBuilder(
    future: _loadWorkflowData(workflow),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Text(intl.error);
      }

      // Get the pre-calculated counts from the future
      final processCounts = snapshot.data?['process'] ?? {};
      final subProcessCounts = snapshot.data?['subProcess'] ?? {};
      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(workflow.name ?? '', 
                  style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 16),
  Row(
    children: [
      Expanded(
        child: _buildChart(
          processCounts, 
          intl.processes, 
          context
        ),
      ),
      Expanded(
        child: _buildChart(
          subProcessCounts,
          intl.subProcesses,
          context
        ),
      ),
    ],
  ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [1, 2, 3].map((status) => Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _getStatusColor(status)),
                    const SizedBox(width: 4),
                    Text(_getStatusLabel(status, context)),
                  ],
                )).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding:EdgeInsets.only(left: 50),
          child: Text(
          intl.dashboard
          )
          ),
          actions: [
            IconButton(
            icon: Icon(_isPieChart ? Icons.bar_chart : Icons.pie_chart),
            onPressed: _toggleChartType,
          ),
          ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _workflows.isEmpty
                  ? Center(child: Text(intl.noWorkflows))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _workflows.length,
                      itemBuilder: (context, index) => 
                        _buildWorkflowCharts(_workflows[index], context),
                    ),
            ),
    );
  }
}