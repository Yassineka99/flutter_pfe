import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/process.dart';
import '../model/sub_process.dart';
import '../viewmodel/process_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';

class AssignedSubProcesses extends StatefulWidget {
  final int userId;

  const AssignedSubProcesses({super.key, required this.userId});

  @override
  State<AssignedSubProcesses> createState() => _AssignedSubProcessesState();
}

class _AssignedSubProcessesState extends State<AssignedSubProcesses> {
  final ProcessViewModel _processViewModel = ProcessViewModel();
  final SubProcessViewModel _subProcessViewModel = SubProcessViewModel();
  List<Process> _processes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Get all sub-processes assigned to the user
      final subProcesses = await _subProcessViewModel.getByUserId(widget.userId);
      
      // 2. Extract unique process IDs from sub-processes
      final processIds = subProcesses
          .map((sp) => sp.processId)
          .whereType<int>()
          .toSet();

      // 3. Get parent processes for these sub-processes
      final processes = await Future.wait(
        processIds.map((id) => _processViewModel.getbyid(id.toString())),
      );

      // 4. Filter valid processes and exclude completed ones
      setState(() {
        _processes = processes
            .whereType<Process>()
            .where((p) => p.statusId != 3)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading data: $e');
    }
  }

  Future<void> _updateProcessStatus(Process process) async {
    try {
      // 1. Get current sub-processes for this process
      final subProcesses = await _subProcessViewModel.getByUserAndProcess(
        widget.userId, 
        process.id!
      );

      // 2. Update process status based on sub-processes
      final allCompleted = subProcesses.every((sp) => sp.statusId == 3);
      process.statusId = allCompleted ? 3 : 2;
      process.finishedAt = allCompleted ? DateTime.now() : null;

      // 3. Save process and sub-processes
      await _processViewModel.update(process);
      await _loadData();
    } catch (e) {
      print('Error updating process: $e');
    }
  }

Widget _buildSubProcessItem(SubProcess sp, Process process) {
  final isCompleted = sp.statusId == 3;
  
  return CheckboxListTile(
    title: Text(sp.name ?? 'Unnamed Sub-process'),
    subtitle: sp.message?.isNotEmpty ?? false 
        ? Text(sp.message!) 
        : null,
    value: isCompleted,
    onChanged: isCompleted 
        ? null  // Disable checkbox if already completed
        : (value) => _updateSubProcessStatus(sp, value ?? false),
    activeColor: const Color(0xFF78A190), // Your brand color
    secondary: Icon(
      _getStatusIcon(sp.statusId),
      color: _getStatusColor(sp.statusId),
    ),
  );
}

Future<void> _updateSubProcessStatus(
  SubProcess sp, 
  bool value
) async {
  if (value) {  // Only handle check (true) events
    setState(() => sp.statusId = 3);
    sp.finishedAt = DateTime.now();
    
    await _subProcessViewModel.update(sp);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${sp.name} marked as completed'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
  IconData _getStatusIcon(int? status) {
    switch (status) {
      case 3:
        return Icons.check_circle;
      case 2:
        return Icons.timelapse;
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 3:
        return Colors.green;
      case 2:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

Widget _buildProcessCard(Process process) {
    return FutureBuilder<List<SubProcess>>(
      future: _subProcessViewModel.getByUserAndProcess(
        widget.userId, 
        process.id!
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final subProcesses = snapshot.data!;
        final completedCount = subProcesses.where((sp) => sp.statusId == 3).length;

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    process.name ?? 'Unnamed Process',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text('$completedCount/${subProcesses.length} completed'),
                ),
                ...subProcesses.map((sp) => _buildSubProcessItem(sp, process)),
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
        title: Center(
          child: Text(
            intl.assignedSubProcess,
            style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF28445C),
                    fontFamily: 'BrandonGrotesque')
            
            )),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _processes.isEmpty
                  ? Center(child: Text(intl.noAssignedSubProcesses))
                  : ListView.builder(
                      itemCount: _processes.length,
                      itemBuilder: (context, index) => _buildProcessCard(_processes[index]),
                    ),
            ),
    );
  }
}
