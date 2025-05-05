// workflowview.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/workflow.dart';
import '../model/process.dart';
import '../viewmodel/workflow_view_model.dart';
import '../viewmodel/process_view_model.dart';

class WorkflowView extends StatefulWidget {
  const WorkflowView({super.key});

  @override
  State<WorkflowView> createState() => _WorkflowViewState();
}

class _WorkflowViewState extends State<WorkflowView> {
  final WorkflowViewModel _workflowViewModel = WorkflowViewModel();
  final ProcessViewModel _processViewModel = ProcessViewModel();
  List<Workflow>? workflowsList;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
  }

  Future<void> _loadWorkflows() async {
    try {
      final workflows = await _workflowViewModel.fetchAllWorkflows();
      setState(() {
        workflowsList = workflows;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _handleWorkflowTap(int workflowId) {
    final intl = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(intl.addProcessesQuestion),
        content: Text(intl.addProcessesToWorkflow),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(intl.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddProcessesDialog(workflowId);
            },
            child: Text(intl.yes),
          ),
        ],
      ),
    );
  }

  void _showAddProcessesDialog(int workflowId) {
    showDialog(
      context: context,
      builder: (context) => AddProcessesDialog(
        workflowId: workflowId,
        processViewModel: _processViewModel,
        onProcessesAdded: () => _loadWorkflows(),
      ),
    );
  }

  void _showAddWorkflowDialog() {
    final intl = AppLocalizations.of(context)!;
    final _formKey = GlobalKey<FormState>();
    String name = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: Text(intl.addWorkflow)),
        content: Form(
          key: _formKey,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: intl.name,
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? intl.requiredField : null,
            onSaved: (value) => name = value!,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(intl.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                try {
                  await _workflowViewModel.create(
                      name, 1); // Assuming user ID 1
                  _loadWorkflows();
                  Navigator.pop(context);
                  _showResultPopup(true);
                } catch (e) {
                  _showResultPopup(false);
                }
              }
            },
            child: Text(intl.save),
          ),
        ],
      ),
    );
  }

  void _showEditWorkflowDialog(Workflow workflow) {
    final intl = AppLocalizations.of(context)!;
    final _formKey = GlobalKey<FormState>();
    String newName = workflow.name ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: Text(intl.editWorkflow)),
        content: Form(
          key: _formKey,
          child: TextFormField(
            initialValue: workflow.name,
            decoration: InputDecoration(
              labelText: intl.name,
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? intl.requiredField : null,
            onSaved: (value) => newName = value!,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(intl.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                try {
                  await _workflowViewModel.update(Workflow(
                    id: workflow.id,
                    name: newName,
                    createdBy: workflow.createdBy,
                  ));
                  _loadWorkflows();
                  Navigator.pop(context);
                  _showResultPopup(true);
                } catch (e) {
                  _showResultPopup(false);
                }
              }
            },
            child: Text(intl.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int workflowId) {
    final intl = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(intl.deleteWorkflow),
        content: Text(intl.deleteWorkflowConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(intl.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _workflowViewModel.delete(workflowId);
                _loadWorkflows();
                Navigator.pop(context);
                _showResultPopup(true);
              } catch (e) {
                _showResultPopup(false);
              }
            },
            child: Text(intl.delete),
          ),
        ],
      ),
    );
  }

  void _showResultPopup(bool success) {
    final intl = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? intl.success : intl.error),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF78A190),
        title: Center(
          child: Padding(
            padding: EdgeInsets.only(left: 46),
            child: Text(intl.workflows,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF28445C),
                    fontFamily: 'BrandonGrotesque')),
          ),
        ),
        actions: [
          IconButton(
            color: const Color(0xFF28445C).withOpacity(.40),
            icon: const Icon(Icons.add),
            onPressed: _showAddWorkflowDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (workflowsList?.isEmpty ?? true)
              ? Center(child: Text(intl.noWorkflows))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: workflowsList!.length,
                  itemBuilder: (context, index) {
                    final workflow = workflowsList![index];
                    return _WorkflowCard(
                      workflow: workflow,
                      processViewModel: _processViewModel,
                      onEdit: () => _showEditWorkflowDialog(workflow),
                      onDelete: () => _showDeleteConfirmation(workflow.id!),
                      onTap: () => _handleWorkflowTap(workflow.id!),
                    );
                  },
                ),
    );
  }
}

class _WorkflowCard extends StatefulWidget {
  final Workflow workflow;
  final ProcessViewModel processViewModel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _WorkflowCard(
      {required this.workflow,
      required this.processViewModel,
      required this.onEdit,
      required this.onDelete,
      required this.onTap});

  @override
  State<_WorkflowCard> createState() => __WorkflowCardState();
}

class __WorkflowCardState extends State<_WorkflowCard> {
  bool _isExpanded = false;
  late Future<List<Process>> _processesFuture;

  @override
  void initState() {
    super.initState();
    _processesFuture =
        widget.processViewModel.getByWorkflowId(widget.workflow.id!);
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.workflow.name ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: widget.onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              FutureBuilder<List<Process>>(
                future: _processesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text(intl.errorLoadingProcesses);
                  }

                  final processes = snapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(intl.associatedProcesses),
                          Text('${processes.length} ${intl.processes}'),
                        ],
                      ),
                      if (processes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...(_isExpanded ? processes : processes.take(2))
                            .map((process) => ListTile(
                                  title: Text(process.name ?? ''),
                                ))
                            .toList(),
                        if (processes.length > 2)
                          IconButton(
                            icon: Icon(_isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more),
                            onPressed: () =>
                                setState(() => _isExpanded = !_isExpanded),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddProcessesDialog extends StatefulWidget {
  final int workflowId;
  final ProcessViewModel processViewModel;
  final VoidCallback onProcessesAdded;

  const AddProcessesDialog({
    required this.workflowId,
    required this.processViewModel,
    required this.onProcessesAdded,
    Key? key,
  }) : super(key: key);

  @override
  _AddProcessesDialogState createState() => _AddProcessesDialogState();
}

class _AddProcessesDialogState extends State<AddProcessesDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = [];
  int _order = 1;

  @override
  void initState() {
    super.initState();
    _addProcessField();
  }

  void _addProcessField() {
    _controllers.add(TextEditingController());
    setState(() {});
  }

  Future<void> _saveProcesses() async {
    final intl = AppLocalizations.of(context)!;

    for (var controller in _controllers) {
      if (controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(intl.processNameRequired)),
        );
        return;
      }
    }

    try {
      for (var controller in _controllers) {
        await widget.processViewModel.create(
          controller.text,
          widget.workflowId,
          1, // Default status
          _order++,
          1, // Created by user ID
        );
      }
      widget.onProcessesAdded();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(intl.processesAddedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(intl.error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Center(child: Text(intl.addProcesses)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ..._controllers.map((controller) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: intl.processName,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _addProcessField,
                tooltip: intl.addAnotherProcess,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(intl.cancel),
        ),
        ElevatedButton(
          onPressed: _saveProcesses,
          child: Text(intl.saveAllProcesses),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
