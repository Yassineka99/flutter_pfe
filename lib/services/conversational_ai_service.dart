import 'package:flutter/material.dart';
import '../model/workflow.dart';
import '../model/process.dart';
import '../viewmodel/workflow_view_model.dart';
import '../viewmodel/process_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class ConversationalAIService {
  final WorkflowViewModel workflowViewModel;
  final ProcessViewModel processViewModel;
  final SubProcessViewModel subProcessViewModel;
  final AppLocalizations intl;
  

  ConversationalAIService({
    required this.workflowViewModel,
    required this.processViewModel,
    required this.subProcessViewModel,
    required this.intl
  });

 Future<String> handleMessage(String message, BuildContext context) async {
  message = message.toLowerCase().trim();
  
  // Check for greetings
  if (_isGreeting(message)) {
    return _respondToGreeting();
  }
  
  // Check for thanks
  if (_isThanks(message)) {
    return _respondToThanks();
  }
  
  // Check for workflow listing
  if (_shouldListWorkflows(message)) {
    return await _listExistingWorkflows();
  }
  
  // Check for workflow-related commands
  if (_isWorkflowCommand(message)) {
    return await _handleWorkflowCommand(message, context);
  }
  
  // Check for process-related commands
  if (_isProcessCommand(message)) {
    return await _handleProcessCommand(message, context);
  }
  
  // Default conversational response
  return _generateConversationalResponse(message);
}

bool _shouldListWorkflows(String message) {
  final listKeywords = [
    intl.showAllWorkflows,
    intl.listWorkflows,
    intl.whatWorkflows,
    intl.viewWorkflows,
    intl.displayWorkflows,
    intl.seeWorkflows,
    intl.existingWorkflows
  ];
  
  return listKeywords.any((keyword) => message.contains(keyword));
}

  bool _isGreeting(String message) {
    final greetings = [intl.hi, intl.hello, intl.hey, intl.goodMorning, intl.goodAfternoon, intl.goodEvening];
    return greetings.any((greeting) => message.contains(greeting));
  }

  String _respondToGreeting() {
    final hour = DateTime.now().hour;
    String timeBasedGreeting;
    
    if (hour < 12) {
      timeBasedGreeting = intl.goodMorning;
    } else if (hour < 17) {
      timeBasedGreeting = intl.goodAfternoon;
    } else {
      timeBasedGreeting = intl.goodEvening;
    }

    final responses = [
      "$timeBasedGreeting! ${intl.howCanIassistWithYourWorflowsToday}",
      intl.hellowThereWhatWorkflowTasksShallWeTackleTogether,
      intl.hiReadytostreamlineyourprocessesWhatsonyourmind,
      "$timeBasedGreeting! ${intl.imheretohelpwithyourworkflowneeds}",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  bool _isThanks(String message) {
    final thanksWords = [intl.thanks, intl.thankyou, intl.appreciate, intl.grateful];
    return thanksWords.any((word) => message.contains(word));
  }

  String _respondToThanks() {
    final responses = [
      intl.yourareverywelcome,
      intl.myPlesure,
      intl.noProblem,
      intl.gladicouldhelp,
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  bool _isWorkflowCommand(String message) {
  if (_shouldListWorkflows(message)) return false;
  
  final workflowKeywords = [
    intl.workflow, intl.create, intl.edit, intl.delete, 
    intl.remove, intl.update, intl.rename, intl.add
  ];
  return workflowKeywords.any((word) => message.contains(word));
}

  bool _isProcessCommand(String message) {
    final processKeywords = [intl.process, intl.subprocess, intl.add, intl.news, intl.step, intl.task];
    return processKeywords.any((word) => message.contains(word));
  }

  Future<String> _handleWorkflowCommand(String message, BuildContext context) async {
    try {
      // Create workflow
      if (message.contains(intl.create) || message.contains(intl.news) || message.contains(intl.add)) {
        final name = _extractNameAfterKeyword(message, [intl.create, intl.news, intl.add]);
        if (name.isEmpty) {
          return intl.createWorkflowPrompt;
        }
        
        await workflowViewModel.create(name, 1);
        return intl.workflowCreated(name);
      }
      
      // Edit workflow
      if (message.contains(intl.edit) || message.contains(intl.update) || message.contains(intl.rename)) {
        final parts = _extractEditParts(message);
        if (parts == null) {
          return intl.renameWorkflowPrompt;
        }
        
        final (oldName, newName) = parts;
        final workflows = await workflowViewModel.fetchAllWorkflows();
        final workflow = workflows.firstWhere(
          (w) => w.name?.toLowerCase() == oldName.toLowerCase(),
          orElse: () => Workflow(),
        );
        
        if (workflow.id == null) {
          return intl.workflowNotFound(oldName);
        }
        
        await workflowViewModel.update(Workflow(
          id: workflow.id,
          name: newName,
          createdBy: workflow.createdBy,
        ));
        
        return intl.workflowRenamed(oldName,newName);
      }
      
      // Delete workflow
      if (message.contains(intl.delete) || message.contains(intl.remove)) {
        final name = _extractNameAfterKeyword(message, [intl.delete, intl.remove]);
        if (name.isEmpty) {
          return intl.deleteWorkflowPrompt;
        }
        
        final workflows = await workflowViewModel.fetchAllWorkflows();
        final workflow = workflows.firstWhere(
          (w) => w.name?.toLowerCase() == name.toLowerCase(),
          orElse: () => Workflow(),
        );
        
        if (workflow.id == null) {
          return intl.workflowDeleteNotFound(name);
        }
        
        await workflowViewModel.delete(workflow.id!);
        return intl.workflowDeleted(name);
      }
      
      return intl.workflowTaskComplete;
    } catch (e) {
      return intl.workflowError(e.toString());
    }
  }

Future<String> _handleProcessCommand(String message, BuildContext context) async {
  try {
    // Add process to workflow
    if (message.contains(intl.add) || message.contains(intl.news) || message.contains(intl.create) || message.contains(intl.name) ) {
      // Extract process name
      final processName = _extractNameAfterKeyword(message, [intl.add, intl.news, intl.create, intl.name]);
      if (processName.isEmpty) {
        return intl.addProcessPrompt;
      }
      
      // Extract workflow name (more robust extraction)
      final workflowName = _extractWorkflowName(message);
      if (workflowName.isEmpty) {
        return intl.whichWorkflowPrompt;
      }
      
      // Get all workflows to find the correct one
      final workflows = await workflowViewModel.fetchAllWorkflows();
      final matchingWorkflows = workflows.where(
        (w) => w.name?.toLowerCase().contains(workflowName.toLowerCase()) ?? false
      ).toList();
      
      if (matchingWorkflows.isEmpty) {
        return "${intl.workflowMatchNotFound(workflowName)}"
            "${workflows.map((w) => w.name).join(', ')}";
      }
      
      if (matchingWorkflows.length > 1) {
        return "${intl.multipleWorkflowsFound(workflowName)}"
            "${intl.matchingWorkflows(matchingWorkflows.map((w) => w.name).join(', '))}";
      }
      
      final workflow = matchingWorkflows.first;
      
      // Check if process already exists
      final existingProcesses = await processViewModel.getByWorkflowId(workflow.id!);
      if (existingProcesses.any((p) => p.name?.toLowerCase() == processName.toLowerCase())) {
        return "${intl.processExists(processName,workflowName)}";
      }
      
      // Create the process
      await processViewModel.create(
        processName,
        workflow.id!,
        1, // Default status
        1, // Order
        1, // Created by admin
      );
      
      return intl.processAdded(processName,workflowName);
    }
    
    return intl.processTaskComplete;
  } catch (e) {
    return intl.processError(e.toString());
  }
}

// Update the _extractWorkflowName method to be more robust
String _extractWorkflowName(String message) {
  final patterns = [
    RegExp(r'to workflow (.+)'),
    RegExp(r'in workflow (.+)'),
    RegExp(r'to (.+) workflow'),
    RegExp(r'workflow (.+)'),
    RegExp(r'for workflow (.+)'),
  ];
  
  for (final pattern in patterns) {
    final match = pattern.firstMatch(message.toLowerCase());
    if (match != null && match.groupCount >= 1) {
      // Get the matched text and clean it up
      String extracted = match.group(1)!
          .replaceAll(intl.named, '')
          .replaceAll(intl.called, '')
          .replaceAll(intl.withname, '')
          .trim();
      
      // Remove any trailing punctuation or words
      extracted = extracted.split(RegExp(r'[.,;!?]')).first.trim();
      extracted = extracted.split(intl.and).first.trim();
      
      return extracted;
    }
  }
  
  return '';
}

  String _generateConversationalResponse(String message) {
    // Personal questions
    if (message.contains(intl.howAreYou)) {
      return intl.howAreYouResponse;
    }
    
    if (message.contains(intl.yourname)) {
      return intl.assistantName;
    }
    
    if (message.contains(intl.whomadeyou) || message.contains(intl.whocreatedyou)) {
      return intl.creatorResponse;
    }
    
    // Help requests
    if (message.contains(intl.help) || message.contains(intl.whatcanyoudo)) {
      return _showHelp();
    }
    
    if (message.contains(intl.workflow) || message.contains(intl.process)) {
      return intl.capabilitiesResponse;
    }
    
    // Default responses
    final unknownResponses = [
      intl.imnotintierlysure,
      intl.thatsinteresting,
      intl.imstilllearningcasualconversation,
      intl.letmethinkaboutthat,
      intl.imnotcertainiunderstood,
    ];
    
    return unknownResponses[DateTime.now().millisecond % unknownResponses.length];
  }

  String _showHelp() {
    return intl.helpMessage;
  }

  // Helper methods
 String _extractNameAfterKeyword(String message, List<String> keywords) {
  // First try to find the most specific pattern
  for (final keyword in keywords) {
    final pattern = RegExp('$keyword (?:named|called)? ?([\\w\\s]+) (?:to|in|for) workflow');
    final match = pattern.firstMatch(message.toLowerCase());
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
  }
  
  // Fallback to simple extraction
  for (final keyword in keywords) {
    if (message.toLowerCase().contains(keyword)) {
      // Get everything after the keyword
      String afterKeyword = message.substring(message.toLowerCase().indexOf(keyword) + keyword.length).trim();
      
      // Remove any trailing workflow-related phrases
      afterKeyword = afterKeyword.split(RegExp(r' (to|in|for) workflow')).first.trim();
      afterKeyword = afterKeyword.split(RegExp(r'[.,;!?]')).first.trim();
      
      return afterKeyword;
    }
  }
  
  return '';
}
Future<String> _listExistingWorkflows() async {
  try {
    final workflows = await workflowViewModel.fetchAllWorkflows();
    
    if (workflows.isEmpty) {
      return intl.noWorkflowsYet;
    }
    
    final workflowList = workflows.map((w) => "• ${w.name}").join('\n');
    final count = workflows.length;
    
    return "${intl.workflowsListHeader} $count ${count == 1 ? '${intl.workflow}' : '${intl.workflows}'}:\n\n$workflowList\n\n"
           "${intl.workflowsListPrompt}";
  } catch (e) {
    return intl.fetchWorkflowsError(e.toString());
  }
}
  (String, String)? _extractEditParts(String message) {
    final separators = [' ${intl.tor} ', ' ${intl.as} ', ' ${intl.named} '];
    for (final sep in separators) {
      if (message.contains(sep)) {
        final parts = message.split(sep);
        if (parts.length == 2) {
          final oldName = parts[0].replaceAll(RegExp(r'edit|update|rename'), '').trim();
          return (oldName, parts[1].trim());
        }
      }
    }
    return null;
  }

}