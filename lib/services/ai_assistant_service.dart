import 'package:flutter/material.dart';
import '../model/workflow.dart';
import '../model/process.dart';
import '../viewmodel/workflow_view_model.dart';
import '../viewmodel/process_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';

class AIAssistantService {
  final WorkflowViewModel workflowViewModel;
  final ProcessViewModel processViewModel;
  final SubProcessViewModel subProcessViewModel;

  AIAssistantService({
    required this.workflowViewModel,
    required this.processViewModel,
    required this.subProcessViewModel,
  });

  // Main method to handle AI commands
  Future<String> handleCommand(String command, BuildContext context) async {
    try {
      command = command.toLowerCase().trim();
      
      // Create workflow command
      if (command.startsWith('create workflow') || 
          command.startsWith('add workflow') ||
          command.startsWith('new workflow')) {
        final name = command.replaceAll('create workflow', '')
            .replaceAll('add workflow', '')
            .replaceAll('new workflow', '')
            .trim();
        return await _createWorkflow(name, context);
      }
      
      // Edit workflow command
      else if (command.startsWith('edit workflow') || 
               command.startsWith('update workflow') ||
               command.startsWith('change workflow')) {
        return await _editWorkflow(command, context);
      }
      
      // Delete workflow command
      else if (command.startsWith('delete workflow') || 
               command.startsWith('remove workflow')) {
        return await _deleteWorkflow(command, context);
      }
      
      // Add process command
      else if (command.startsWith('add process') || 
               command.startsWith('create process') ||
               command.startsWith('new process')) {
        return await _addProcess(command, context);
      }
      
      // Add sub-process command
      else if (command.startsWith('add sub-process') || 
               command.startsWith('create sub-process') ||
               command.startsWith('new sub-process')) {
        return await _addSubProcess(command, context);
      }
      
      // Help command
      else if (command.contains('help') || command.contains('what can you do')) {
        return _showHelp();
      }
      
      return "I didn't understand that command. Try saying 'help' to see what I can do.";
    } catch (e) {
      return "Sorry, I encountered an error processing your request: ${e.toString()}";
    }
  }

  Future<String> _createWorkflow(String name, BuildContext context) async {
    if (name.isEmpty) {
      return "Please specify a workflow name. Example: 'Create workflow Order Processing'";
    }
    
    try {
      await workflowViewModel.create(name, 1); // Assuming 1 is the admin user
      return "Successfully created workflow '$name'";
    } catch (e) {
      return "Failed to create workflow: ${e.toString()}";
    }
  }

  Future<String> _editWorkflow(String command, BuildContext context) async {
    final parts = command.split(' to ');
    if (parts.length != 2) {
      return "Please specify which workflow to edit and its new name. Example: 'Edit workflow Order Processing to Order Management'";
    }
    
    final workflowName = parts[0]
        .replaceAll('edit workflow', '')
        .replaceAll('update workflow', '')
        .replaceAll('change workflow', '')
        .trim();
    
    final newName = parts[1].trim();
    
    try {
      // Get all workflows to find the one to edit
      final workflows = await workflowViewModel.fetchAllWorkflows();
      final workflow = workflows.firstWhere(
        (w) => w.name?.toLowerCase() == workflowName.toLowerCase(),
        orElse: () => Workflow(),
      );
      
      if (workflow.id == null) {
        return "Could not find workflow '$workflowName'";
      }
      
      await workflowViewModel.update(Workflow(
        id: workflow.id,
        name: newName,
        createdBy: workflow.createdBy,
      ));
      
      return "Successfully updated workflow '$workflowName' to '$newName'";
    } catch (e) {
      return "Failed to edit workflow: ${e.toString()}";
    }
  }

  Future<String> _deleteWorkflow(String command, BuildContext context) async {
    final workflowName = command
        .replaceAll('delete workflow', '')
        .replaceAll('remove workflow', '')
        .trim();
    
    if (workflowName.isEmpty) {
      return "Please specify which workflow to delete. Example: 'Delete workflow Order Processing'";
    }
    
    try {
      final workflows = await workflowViewModel.fetchAllWorkflows();
      final workflow = workflows.firstWhere(
        (w) => w.name?.toLowerCase() == workflowName.toLowerCase(),
        orElse: () => Workflow(),
      );
      
      if (workflow.id == null) {
        return "Could not find workflow '$workflowName'";
      }
      
      await workflowViewModel.delete(workflow.id!);
      return "Successfully deleted workflow '$workflowName'";
    } catch (e) {
      return "Failed to delete workflow: ${e.toString()}";
    }
  }

  Future<String> _addProcess(String command, BuildContext context) async {
    // Example command: "Add process Payment to workflow Order Processing"
    final parts = command.split(' to workflow ');
    if (parts.length != 2) {
      return "Please specify the process name and which workflow to add it to. Example: 'Add process Payment to workflow Order Processing'";
    }
    
    final processName = parts[0]
        .replaceAll('add process', '')
        .replaceAll('create process', '')
        .replaceAll('new process', '')
        .trim();
    
    final workflowName = parts[1].trim();
    
    try {
      final workflows = await workflowViewModel.fetchAllWorkflows();
      final workflow = workflows.firstWhere(
        (w) => w.name?.toLowerCase() == workflowName.toLowerCase(),
        orElse: () => Workflow(),
      );
      
      if (workflow.id == null) {
        return "Could not find workflow '$workflowName'";
      }
      
      await processViewModel.create(
        processName,
        workflow.id!,
        1, // Default status
        1, // Order
        1, // Created by admin
      );
      
      return "Successfully added process '$processName' to workflow '$workflowName'";
    } catch (e) {
      return "Failed to add process: ${e.toString()}";
    }
  }

  Future<String> _addSubProcess(String command, BuildContext context) async {
    // Example command: "Add sub-process Credit Check to process Payment with message 'Verify customer credit'"
    final processPart = command.split(' to process ')[0]
        .replaceAll('add sub-process', '')
        .replaceAll('create sub-process', '')
        .replaceAll('new sub-process', '')
        .trim();
    
    final subProcessName = processPart.split(' with message ')[0].trim();
    final message = processPart.contains(' with message ') 
        ? processPart.split(' with message ')[1].trim()
        : 'New sub-process created';
    
    final processName = command.split(' to process ')[1]
        .split(' with message ')[0]
        .trim();
    
    try {
      // In a real app, you'd need to get the process ID from the name
      // This is simplified - you might need to adjust based on your data model
      final processes = await processViewModel.getByWorkflowId(1); // This needs adjustment
      final process = processes.firstWhere(
        (p) => p.name?.toLowerCase() == processName.toLowerCase(),
        orElse: () => Process(),
      );
      
      if (process.id == null) {
        return "Could not find process '$processName'";
      }
      
      await subProcessViewModel.create(
        subProcessName,
        process.id!,
        1, // Default status
        message,
        1, // Assigned to (would need user selection in real implementation)
        1, // Created by admin
      );
      
      return "Successfully added sub-process '$subProcessName' to process '$processName'";
    } catch (e) {
      return "Failed to add sub-process: ${e.toString()}";
    }
  }

  String _showHelp() {
    return """
Here's what I can help you with:

- Create workflow [name]: Create a new workflow
- Edit workflow [current name] to [new name]: Rename a workflow
- Delete workflow [name]: Remove a workflow
- Add process [name] to workflow [workflow name]: Add a process to a workflow
- Add sub-process [name] to process [process name] with message [message]: Add a sub-process

Examples:
- 'Create workflow Order Processing'
- 'Edit workflow Order Processing to Order Management'
- 'Add process Payment to workflow Order Processing'
- 'Add sub-process Credit Check to process Payment with message Verify customer credit'
""";
  }
}