import 'package:front/model/notification.dart';
import 'package:front/repository/notification_repository.dart';

class NotificationViewModel {
  NotificationRepository notificationRepository = NotificationRepository();
  Notification? notification;
  Future<void> create(String message, int usertonotify) async {
    try {
      notification = await notificationRepository.createNotification(
          message, usertonotify);
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error creating client: $e');
    }
  }

  Future<List<Notification>> getUserId(int userid) async {
    await notificationRepository.syncNotification();
    return await notificationRepository.getByUserId(userid);
  }

  Future<void> markAllAsRead(int userId) async {
    try {
      await notificationRepository.markAllAsRead(userId);
      // Optionally notify UI or listeners
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<List<Notification>> getUnreadNotifications(int userid) async {
    await notificationRepository.syncNotification();
    return await notificationRepository.getUnreadNotifications(userid);
  }
}
