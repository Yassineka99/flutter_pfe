import 'package:front/model/notification.dart';
import 'package:front/repository/notification_repository.dart';
class NotificationViewModel {
  NotificationRepository notificationRepository = NotificationRepository();
  Notification? notification;
    Future<void> create(
      String message, int usertonotify ) async {
    try {
      notification =
          await notificationRepository.createNotification(message,usertonotify);
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error creating client: $e');
    }
  }

    Future<Notification?> getbyuserid(String id) async {
    try {
      notification = await notificationRepository.getNotificationByUserId(id);
      if (notification != null) {
        return notification!;
      } else {
        return null;
      }
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error fetching client: $e');
    }
  }

}