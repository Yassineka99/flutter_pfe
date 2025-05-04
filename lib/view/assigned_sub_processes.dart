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
    _loadProcesses();
  }

  Future<void> _loadProcesses() async {
    try {
      final processes = await _processViewModel.getByUserId(widget.userId);
      setState(() {
        _processes = processes.where((p) => p.statusId != 3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
    Future<void> _updateProcessStatus(Process process, List<SubProcess> subProcesses) async {
    try {
      // Update subprocesses
      await Future.wait(subProcesses.map((sp) => 
        _subProcessViewModel.update(sp)
      ));

      // Calculate new process status
      final allCompleted = subProcesses.every((sp) => sp.statusId == 3);
      process.statusId = allCompleted ? 3 : 2;
      
      if (allCompleted) {
        process.finishedAt = DateTime.now();
      }

      await _processViewModel.update(process);
      await _loadProcesses();
    } catch (e) {
      print('Error updating process: $e');
    }
  }

  Widget _buildSubProcessItem(SubProcess subProcess, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(subProcess.name ?? ''),
      subtitle: subProcess.message?.isNotEmpty ?? false 
          ? Text(subProcess.message!) 
          : null,
      value: subProcess.statusId == 3,
      onChanged: onChanged,
      secondary: Icon(
        _getStatusIcon(subProcess.statusId),
        color: _getStatusColor(subProcess.statusId),
      ),
    );
  }

  IconData _getStatusIcon(int? status) {
    switch (status) {
      case 3: return Icons.check_circle;
      case 2: return Icons.timelapse;
      default: return Icons.pending;
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 3: return Colors.green;
      case 2: return Colors.blue;
      default: return Colors.orange;
    }
  }
    Widget _buildProcessCard(Process process) {
    return FutureBuilder<List<SubProcess>>(
      future: _subProcessViewModel.getByUserAndProcess(widget.userId, process.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final subProcesses = snapshot.data!;
        final checkedCount = subProcesses.where((sp) => sp.statusId == 3).length;
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    process.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$checkedCount/${subProcesses.length} completed'),
                  trailing: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _updateProcessStatus(process, subProcesses),
                  ),
                ),
                ...subProcesses.map((sp) => _buildSubProcessItem(sp, (value) {
                  setState(() => sp.statusId = value == true ? 3 : 1);
                })).toList(),
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
        title: Text(intl.assignedProcesses),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _processes.isEmpty
              ? Center(child: Text(intl.noAssignedProcesses))
              : RefreshIndicator(
                  onRefresh: _loadProcesses,
                  child: ListView.builder(
                    itemCount: _processes.length,
                    itemBuilder: (context, index) => 
                      _buildProcessCard(_processes[index]),
                  ),
                ),
    );
  }
}