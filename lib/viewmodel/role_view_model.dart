import 'package:front/repository/role_repository.dart';

import '../model/role.dart';

class RoleViewModel {
  final RoleRepository roleRepository = RoleRepository();
  Role? role;
  Future<Role?> getClient(String id) async {
    try {
      role = await roleRepository.getNotificationByUserId(id);
      if (role != null) {
        return role!;
      } else {
        return null;
      }
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error fetching client: $e');
    }
  }
}
