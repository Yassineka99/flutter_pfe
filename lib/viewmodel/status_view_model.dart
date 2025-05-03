import '../model/status.dart';
import '../repository/status_repository.dart';

class StatusViewModel {
  StatusRepository statusRepository = StatusRepository();
  Status? status;


    Future<Status?> getbyid(String id) async {
    try {
      status = await statusRepository.getStatusByUserId(id);
      if (status != null) {
        return status!;
      } else {
        return null;
      }
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error fetching client: $e');
    }
  }

}