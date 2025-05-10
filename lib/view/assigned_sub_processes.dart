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
      final subProcesses = await _subProcessViewModel.getByUserId(widget.userId);
      final processIds = subProcesses.map((sp) => sp.processId).whereType<int>().toSet();
      final processes = await Future.wait(processIds.map((id) => _processViewModel.getbyid(id.toString())));

      setState(() {
        _processes = processes.whereType<Process>().where((p) => p.statusId != 3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading data: $e');
    }
  }

  Widget _buildSubProcessItem(SubProcess sp, Process process) {
    final isCompleted = sp.statusId == 3;
    final intl = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF4e3a31).withOpacity(0.1)))),
      child: CheckboxListTile(
        title: Text(
          sp.name ?? intl.noAssignedSubProcesses,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF4e3a31),
            fontFamily: 'BrandonGrotesque',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: sp.message?.isNotEmpty ?? false 
            ? Text(
                sp.message!,
                style: TextStyle(
                  color: Color(0xFF4e3a31).withOpacity(0.6),
                  fontFamily: 'BrandonGrotesque',
                ),
              )
            : null,
        value: isCompleted,
        onChanged: isCompleted ? null : (value) => _updateSubProcessStatus(sp, value ?? false),
        activeColor: Color(0xFFB5927F),
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        secondary: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getStatusColor(sp.statusId).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStatusIcon(sp.statusId),
            color: _getStatusColor(sp.statusId),
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _updateSubProcessStatus(SubProcess sp, bool value) async {
  if (value) {
    setState(() => sp.statusId = 3);
    sp.finishedAt = DateTime.now();
    await _subProcessViewModel.update(sp);
final intl = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      
      SnackBar(
        content: Text('${sp.name} ${intl.markedAsCompleted}'),
        backgroundColor: Color(0xFFB5927F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // 🔄 Reload the data to reflect the changes
    await _loadData();
  }
}


  Widget _buildProcessCard(Process process) {
    final intl = AppLocalizations.of(context)!;

    return FutureBuilder<List<SubProcess>>(
      future: _subProcessViewModel.getByUserAndProcess(widget.userId, process.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        final subProcesses = snapshot.data!;
        final completedCount = subProcesses.where((sp) => sp.statusId == 3).length;
        final progress = completedCount / subProcesses.length;

        return Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDF8F4), Color(0xFFFBEFE8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4e3a31).withOpacity(0.05),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFB5927F).withOpacity(0.1)))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              process.name ?? intl.noAssignedProcesses,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4e3a31),
                                fontFamily: 'BrandonGrotesque',
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Color(0xFFB5927F).withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB5927F)),
                                    minHeight: 6,
                                    
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4e3a31),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
        backgroundColor: Color(0xFFB5927F),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF4e3a31)),
        title: Text(
          intl.assignedSubProcess,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4e3a31).withOpacity(0.7),
            fontFamily: 'BrandonGrotesque',
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4e3a31),
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              color: Color(0xFF4e3a31),
              onRefresh: _loadData,
              child: _processes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 48,
                            color: Color(0xFFB5927F).withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            intl.noAssignedSubProcesses,
                            style: TextStyle(
                              color: Color(0xFF4e3a31).withOpacity(0.4),
                              fontFamily: 'BrandonGrotesque',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: 24),
                      itemCount: _processes.length,
                      itemBuilder: (context, index) => _buildProcessCard(_processes[index]),
                    ),
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
      case 3: return Color(0xFF78A190);
      case 2: return Color(0xFF4e3a31);
      default: return Colors.orange;
    }
  }
}