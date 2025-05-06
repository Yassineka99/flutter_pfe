import 'package:front/model/workflow.dart';
import 'package:front/repository/workflow_repository.dart';

class WorkflowViewModel {
  WorkflowRepository workflowRepository = WorkflowRepository();
  Workflow? workflow;
  Future<void> create(String name, int createdBy) async {
    try {
      await workflowRepository.createWorkflow(name, createdBy);
      await workflowRepository.syncWorkflows(); // Trigger sync after creation
    } catch (e) {
      print('Error creating workflow: $e');
    }
  }

  Future<Workflow?> getbyid(String id) async {
    try {
      workflow = await workflowRepository.getWorkflowById(id);
      if (workflow != null) {
        return workflow!;
      } else {
        return null;
      }
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error fetching client: $e');
    }
  }

  Future<Workflow?> getbyname(String id) async {
    try {
      workflow = await workflowRepository.getWorkflowByName(id);
      if (workflow != null) {
        return workflow!;
      } else {
        return null;
      }
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error fetching client: $e');
    }
  }

Future<List<Workflow>> fetchAllWorkflows() async {
  try {
    // first push any local-only rows up to server
    await workflowRepository.syncWorkflows();

    // then pull either remote or cached (depending on connectivity)
    final List<Workflow> workflows = 
        await workflowRepository.getAllWorkflows();

    // no need to filter out nulls—the repo never returns null entries
    return workflows;
  } catch (e) {
    print('Error loading data: $e');
    return <Workflow>[];
  }
}

  Future<void> update(Workflow subProcess) async {
    try {
      workflow = await workflowRepository.updateWorkflow(subProcess);
      await workflowRepository.syncWorkflows();
    } catch (e) {
      print('Error updating subprocess: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      await workflowRepository.deleteWorkflow(id);
      await workflowRepository.syncWorkflows();
    } catch (e) {
      print('Error deleting subprocess: $e');
    }
  }
}
