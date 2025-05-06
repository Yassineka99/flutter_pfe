import 'package:front/model/workflow.dart';
import 'package:front/repository/workflow_repository.dart';

import '../model/process.dart';
import '../repository/process_repository.dart';

class ProcessViewModel {
  ProcessRepoitory processRepository = ProcessRepoitory();
  Process? process;
  Future<void> create(
      String name, int workflowId, int status, int order, int createdby) async {
    try {
      process = await processRepository.createProcess(
          name, workflowId, status, order, createdby);
    } catch (e) {
      print('Error creating client: $e');
    }
  }

  Future<Process?> getbyid(String id) async {
    try {
      process = await processRepository.getProcessById(id);
      if (process != null) {
        return process!;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching client: $e');
    }
  }

  Future<List<Process>> getByUserId(int id) async {
    processRepository.syncProcess();
    return await processRepository.getByUserId(id);
  }

  Future<List<Process>> getByStatusId(int id) async {
    processRepository.syncProcess();
    return await processRepository.getByStatusId(id);
  }

  Future<List<Process>> getByWorkflowId(int id) async {
    try {
      processRepository.syncProcess();
      final processes = await processRepository.getByWorkflowId(id);

      return processes;
    } catch (e, stack) {
      print('Error fetching processes: $e\n$stack');
      return [];
    }
  }

  Future<void> update(Process updatedProcess) async {
    try {
      process = await processRepository.updateProcess(updatedProcess);
      print('Process updated successfully');
    } catch (e) {
      print('Error updating process: $e');
    }
  }
}
