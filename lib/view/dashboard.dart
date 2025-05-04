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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _workflows = await _workflowVM.fetchAllWorkflows();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<int, int> _getProcessStatusCounts(List<Process> processes) {
    return {
      1: processes.where((p) => p.statusId == 1).length,
      2: processes.where((p) => p.statusId == 2).length,
      3: processes.where((p) => p.statusId == 3).length,
    };
  }

  Map<int, int> _getSubProcessStatusCounts(List<SubProcess> subProcesses) {
    return {
      1: subProcesses.where((sp) => sp.statusId == 1).length,
      2: subProcesses.where((sp) => sp.statusId == 2).length,
      3: subProcesses.where((sp) => sp.statusId == 3).length,
    };
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
    Widget _buildProcessPieChart(Map<int, int> statusCounts, BuildContext context) {
    final List<PieChartSectionData> sections = statusCounts.entries.map((entry) {
      return PieChartSectionData(
        color: _getStatusColor(entry.key),
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildSubProcessBarChart(Map<int, int> statusCounts, BuildContext context) {
    final List<BarChartGroupData> barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: statusCounts[1]?.toDouble() ?? 0,
            color: _getStatusColor(1),
            width: 20,
          ),
          BarChartRodData(
            toY: statusCounts[2]?.toDouble() ?? 0,
            color: _getStatusColor(2),
            width: 20,
          ),
          BarChartRodData(
            toY: statusCounts[3]?.toDouble() ?? 0,
            color: _getStatusColor(3),
            width: 20,
          ),
        ],
        showingTooltipIndicators: [0, 1, 2],
      ),
    ];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  _getStatusLabel(value.toInt(), context),
                ),
              ),
            ),
          ),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }
    Widget _buildWorkflowCharts(Workflow workflow, BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _processVM.getByWorkflowId(workflow.id!),
        _subProcessVM.getByProcessId(workflow.id!),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final processes = snapshot.data![0] as List<Process>;
        final subProcesses = snapshot.data![1] as List<SubProcess>;
        
        final processStatusCounts = _getProcessStatusCounts(processes);
        final subProcessStatusCounts = _getSubProcessStatusCounts(subProcesses);

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workflow.name ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildProcessPieChart(processStatusCounts, context)),
                    Expanded(child: _buildSubProcessBarChart(subProcessStatusCounts, context)),
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
      appBar: AppBar(title: Text(intl.dashboard)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _workflows.length,
                itemBuilder: (context, index) => 
                  _buildWorkflowCharts(_workflows[index], context),
              ),
            ),
    );
  }
}