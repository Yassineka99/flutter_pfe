// workflowview.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/user.dart';
import '../model/workflow.dart';
import '../model/process.dart';
import '../viewmodel/notification_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';
import '../viewmodel/user_view_model.dart';
import '../viewmodel/workflow_view_model.dart';
import '../viewmodel/process_view_model.dart';
import '../services/ai_assistant_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

const _dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20.0)),
);

const _headerStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  color: Color(0xFF28445C),
  fontFamily: 'BrandonGrotesque',
);

const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide(color: Color(0xFF78A190)),
);

final _buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: Color(0xFF78A190),
  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

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
  late AIAssistantService _aiAssistant;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _aiCommand = '';
  String _aiResponse = '';
  bool _showAiAssistant = false;
  @override
  void initState() {
    super.initState();
    _loadWorkflows();
    _aiAssistant = AIAssistantService(
      workflowViewModel: _workflowViewModel,
      processViewModel: _processViewModel,
      subProcessViewModel: SubProcessViewModel(),
    );
  }

// Add this method to handle voice input
  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) => setState(() {
            _aiCommand = result.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
      _submitAiCommand();
    }
  }

// Add this method to submit commands
  Future<void> _submitAiCommand() async {
    if (_aiCommand.trim().isEmpty) return;

    setState(() => _aiResponse = 'Processing...');
    final response = await _aiAssistant.handleCommand(_aiCommand, context);
    setState(() {
      _aiResponse = response;
      _loadWorkflows(); // Refresh the list after any changes
    });
  }

  Widget _buildAiAssistantButton() {
    return FloatingActionButton(
      backgroundColor: Color(0xFF78A190),
      onPressed: () => setState(() => _showAiAssistant = !_showAiAssistant),
      child: Icon(Icons.assistant, color: Colors.white),
    );
  }

// Add this widget to show the AI assistant panel
  Widget _buildAiAssistantPanel() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _showAiAssistant ? 300 : 0,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: _showAiAssistant
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: TextEditingController(text: _aiCommand),
                        onChanged: (value) => _aiCommand = value,
                        decoration: InputDecoration(
                          hintText: 'Tell me what to do...',
                          suffixIcon: IconButton(
                            icon:
                                Icon(_isListening ? Icons.mic : Icons.mic_none),
                            onPressed: _listen,
                          ),
                        ),
                      )),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: _buttonStyle,
                        onPressed: _submitAiCommand,
                        child: Text('Send'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(_aiResponse),
                    ),
                  ),
                ],
              )
            : SizedBox.shrink(),
      
    );
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
      builder: (context) => Dialog(
        shape: _dialogShape,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                  intl.doYouwantToAddAProcess, Icons.help_outline),
              const SizedBox(height: 24),
              _buildDialogActionButtons(
                onCancel: () => Navigator.pop(context),
                onConfirm: () {
                  Navigator.pop(context);
                  _showAddProcessesDialog(workflowId);
                },
                confirmText: intl.yes,
              ),
            ],
          ),
        ),
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
      builder: (context) => Dialog(
        shape: _dialogShape,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(intl.addWorkflow, Icons.work_outline),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
                  style: TextStyle(fontFamily: 'BrandonGrotesque'),
                  decoration: InputDecoration(
                    labelText: intl.name,
                    labelStyle: TextStyle(color: Color(0xFF28445C)),
                    border: _inputBorder,
                    focusedBorder: _inputBorder,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? intl.requiredField : null,
                  onSaved: (value) => name = value!,
                ),
              ),
              SizedBox(height: 24),
              _buildDialogActionButtons(
                onCancel: () => Navigator.pop(context),
                onConfirm: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    try {
                      await _workflowViewModel.create(name, 1);
                      _loadWorkflows();
                      Navigator.pop(context);
                      _showResultPopup(true);
                    } catch (e) {
                      _showResultPopup(false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditWorkflowDialog(Workflow workflow) {
    final intl = AppLocalizations.of(context)!;
    final _formKey = GlobalKey<FormState>();
    String newName = workflow.name ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: _dialogShape,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(intl.editWorkflow, Icons.edit_note),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
                  initialValue: workflow.name,
                  style: TextStyle(fontFamily: 'BrandonGrotesque'),
                  decoration: InputDecoration(
                    labelText: intl.name,
                    labelStyle: TextStyle(color: Color(0xFF28445C)),
                    border: _inputBorder,
                    focusedBorder: _inputBorder,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? intl.requiredField : null,
                  onSaved: (value) => newName = value!,
                ),
              ),
              SizedBox(height: 24),
              _buildDialogActionButtons(
                onCancel: () => Navigator.pop(context),
                onConfirm: () async {
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF78A190).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Color(0xFF28445C)),
        ),
        SizedBox(height: 16),
        Text(title, style: _headerStyle),
      ],
    );
  }

  Widget _buildDialogActionButtons({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    Color confirmColor = const Color(0xFF78A190),
    String confirmText = 'Save',
  }) {
    final intl = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(intl.cancel,
              style: TextStyle(
                  color: Color(0xFF28445C), fontFamily: 'BrandonGrotesque')),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          style: _buttonStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll(confirmColor)),
          onPressed: onConfirm,
          child: Text(confirmText,
              style: TextStyle(fontFamily: 'BrandonGrotesque')),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(int workflowId) {
    final intl = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: _dialogShape,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(
                  intl.deleteWorkflow, Icons.warning_amber_rounded),
              const SizedBox(height: 16),
              Text(
                intl.deleteWorkflowConfirmation,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildDialogActionButtons(
                onCancel: () => Navigator.pop(context),
                onConfirm: () async {
                  try {
                    await _workflowViewModel.delete(workflowId);
                    _loadWorkflows();
                    Navigator.pop(context);
                    _showResultPopup(true);
                  } catch (e) {
                    _showResultPopup(false);
                  }
                },
                confirmColor: Colors.red,
                confirmText: intl.delete,
              ),
            ],
          ),
        ),
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
      body: Stack(
        children: [isLoading
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
          Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildAiAssistantPanel(),
        ),
      ]
      ),
      floatingActionButton: _buildAiAssistantButton(),
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

  void _showAddSubProcessDialog(int processId) {
    showDialog(
      context: context,
      builder: (context) => AddSubProcessesDialog(
        processId: processId,
        subProcessViewModel: SubProcessViewModel(),
        userViewModel: UserViewModel(),
        notificationViewModel: NotificationViewModel(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onTap,
              child: Row(
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
                                onTap: () =>
                                    _showAddSubProcessDialog(process.id!),
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

  Widget _buildDialogHeader(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF78A190).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Color(0xFF28445C)),
        ),
        SizedBox(height: 16),
        Text(title, style: _headerStyle),
      ],
    );
  }

  Widget _buildDialogActionButtons({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    Color confirmColor = const Color(0xFF78A190),
    String confirmText = 'Save',
  }) {
    final intl = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(intl.cancel,
              style: TextStyle(
                  color: Color(0xFF28445C), fontFamily: 'BrandonGrotesque')),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          style: _buttonStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll(confirmColor)),
          onPressed: onConfirm,
          child: Text(confirmText,
              style: TextStyle(fontFamily: 'BrandonGrotesque')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return Dialog(
      shape: _dialogShape,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(intl.addProcesses, Icons.add_task),
            SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ..._controllers.map((controller) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: controller,
                            style: TextStyle(fontFamily: 'BrandonGrotesque'),
                            decoration: InputDecoration(
                              labelText: intl.processName,
                              labelStyle: TextStyle(color: Color(0xFF28445C)),
                              border: _inputBorder,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        )),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Color(0xFF78A190)),
                      onPressed: _addProcessField,
                      tooltip: intl.addAnotherProcess,
                    ),
                  ],
                ),
              ),
            ),
            _buildDialogActionButtons(
              onCancel: () => Navigator.pop(context),
              onConfirm: _saveProcesses,
              confirmText: intl.saveAllProcesses,
            ),
          ],
        ),
      ),
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

class AddSubProcessesDialog extends StatefulWidget {
  final int processId;
  final SubProcessViewModel subProcessViewModel;
  final UserViewModel userViewModel;
  final NotificationViewModel notificationViewModel;

  const AddSubProcessesDialog({
    required this.processId,
    required this.subProcessViewModel,
    required this.userViewModel,
    required this.notificationViewModel,
    Key? key,
  }) : super(key: key);

  @override
  _AddSubProcessesDialogState createState() => _AddSubProcessesDialogState();
}

class _AddSubProcessesDialogState extends State<AddSubProcessesDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<User> _users = [];
  Map<int, bool> _selectedUsers = {};
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.userViewModel.getUsersByRoleId(3);
      setState(() {
        _users = users;
        _selectedUsers = {for (var user in users) user.id!: false};
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _saveSubProcess() async {
    if (!_formKey.currentState!.validate()) return;

    final intl = AppLocalizations.of(context)!;
    final selectedUserIds = _selectedUsers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(intl.selectAtLeastOneUser)),
      );
      return;
    }

    try {
      // Create sub-process
      await widget.subProcessViewModel.create(
        _nameController.text,
        widget.processId,
        1, // Default status
        _messageController.text,
        selectedUserIds.first, // Assuming single selection
        1, // Created by admin
      );

      // Send notifications to all selected users
      for (final userId in selectedUserIds) {
        await widget.notificationViewModel.create(
          _messageController.text,
          userId,
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(intl.subProcessCreated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(intl.errorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDialogHeader(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF78A190).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Color(0xFF28445C)),
        ),
        SizedBox(height: 16),
        Text(title, style: _headerStyle),
      ],
    );
  }

  Widget _buildDialogActionButtons({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    Color confirmColor = const Color(0xFF78A190),
    String confirmText = 'Save',
  }) {
    final intl = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(intl.cancel,
              style: TextStyle(
                  color: Color(0xFF28445C), fontFamily: 'BrandonGrotesque')),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          style: _buttonStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll(confirmColor)),
          onPressed: onConfirm,
          child: Text(confirmText,
              style: TextStyle(fontFamily: 'BrandonGrotesque')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return Dialog(
      shape: _dialogShape,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(intl.addSubProcess, Icons.grain),
            SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontFamily: 'BrandonGrotesque'),
                        decoration: InputDecoration(
                          labelText: intl.subProcessName,
                          labelStyle: TextStyle(color: Color(0xFF28445C)),
                          border: _inputBorder,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? intl.requiredField : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        style: TextStyle(fontFamily: 'BrandonGrotesque'),
                        decoration: InputDecoration(
                          labelText: intl.message,
                          labelStyle: TextStyle(color: Color(0xFF28445C)),
                          border: _inputBorder,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value?.isEmpty ?? true ? intl.requiredField : null,
                      ),
                      SizedBox(height: 16),
                      _buildUserSelectionList(),
                    ],
                  ),
                ),
              ),
            ),
            _buildDialogActionButtons(
              onCancel: () => Navigator.pop(context),
              onConfirm: _saveSubProcess,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSelectionList() {
    final intl = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF78A190).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(intl.selectUsers,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF28445C),
                  fontFamily: 'BrandonGrotesque')),
          SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(user.name ?? '',
                        style: TextStyle(
                            fontSize: 14, fontFamily: 'BrandonGrotesque')),
                    value: _selectedUsers[user.id] ?? false,
                    onChanged: (value) => setState(() {
                      _selectedUsers[user.id!] = value ?? false;
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
