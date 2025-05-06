import '../model/sub_process.dart';
import '../repository/sub_process_repository.dart';

class SubProcessViewModel {
  SubProcessRepoitory subprocessRepository = SubProcessRepoitory();
  SubProcess? subprocess;
  Future<void> create(String name, int processId, int status, String message,
      int assignedto, int createdby) async {
    try {
      subprocess = await subprocessRepository.createSubProcess(
          name, processId, status, message, assignedto, createdby);
    } catch (e) {
      print('Error creating client: $e');
    }
  }

  Future<SubProcess?> getbyid(String id) async {
    try {
      subprocess = await subprocessRepository.getSubProcessById(id);
      if (subprocess != null) {
        return subprocess!;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching client: $e');
    }
  }

  Future<List<SubProcess>> getAll() async {
    await subprocessRepository.syncSubProcess();
    return await subprocessRepository.getAllSubProcesses();
  }

  Future<List<SubProcess>> getByProcessId(int id) async {
    await subprocessRepository.syncSubProcess();
    return await subprocessRepository.getByProcessId(id);
  }

  Future<List<SubProcess>> getByUserId(int id) async {
    await subprocessRepository.syncSubProcess();
    return await subprocessRepository.getByUserId(id);
  }

  Future<List<SubProcess>> getByUserAndProcess(
      int userId, int processId) async {
        await subprocessRepository.syncSubProcess();
    return await subprocessRepository.getByUserAndProcessId(userId, processId);
  }

  Future<void> update(SubProcess subProcess) async {
    try {
      subprocess = await subprocessRepository.updateSubProcess(subProcess);
    } catch (e) {
      print('Error updating subprocess: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      await subprocessRepository.deleteSubProcess(id);
    } catch (e) {
      print('Error deleting subprocess: $e');
    }
  }

  Future<List<SubProcess>> getByStatusAndUserId(int status, int userid) async {
    await subprocessRepository.syncSubProcess();
    return await subprocessRepository.getByStatusAndUserId(status, userid);
  }
}
