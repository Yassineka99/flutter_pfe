import 'package:front/model/workflow.dart';
import 'package:front/repository/workflow_repository.dart';

class WorkflowViewModel {
  WorkflowRepository workflowRepository = WorkflowRepository();
  Workflow? workflow;
    Future<void> create(
      String name, int user) async {
    try {
      workflow =
          await workflowRepository.createWorkflow(name, user);
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error creating client: $e');
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
    return await workflowRepository.getAllWorkflows();
  } catch (e) {
    print('Error fetching workflows: $e');
    return [];
  }
}

Future<void> update(Workflow subProcess) async {
  try {
    workflow = await workflowRepository.updateWorkflow(subProcess);
  } catch (e) {
    print('Error updating subprocess: $e');
  }
}

Future<void> delete(int id) async {
  try {
    await workflowRepository.deleteWorkflow(id);
  } catch (e) {
    print('Error deleting subprocess: $e');
  }
}


}
