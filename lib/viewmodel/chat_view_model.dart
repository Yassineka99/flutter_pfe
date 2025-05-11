import '../model/chat.dart';
import '../repository/chat_repository.dart';

class ChatViewModel{
    ChatRepository chatRepository = ChatRepository();
  Chat? chat;
    Future<void> create(
      String message, int from_user,int to_user ) async {
    try {
      chat =
          await chatRepository.createMessage(message,from_user,to_user);
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error creating client: $e');
    }
  }

    Future<List<Chat>>? GetAllbySenderid(int userid) async {
  return await chatRepository.GetAllbySenderid(userid);
}

  Future<List<Chat>>? GetAllbyRecieverid(int userid) async {
  return await chatRepository.GetAllbyRecieverid(userid);
}

Future<void> update(Chat chat) async {
  try {
     await chatRepository.updateSubProcess(chat);
  } catch (e) {
    print('Error updating subprocess: $e');
  }
}

  Future<List<Chat>>? GetAllbySenderAndRecieverid(int sender,int reciever) async {
  return await chatRepository.GetAllbySenderAndRecieverid(sender,reciever);
}

Future<List<Chat>> getConversation(int user1, int user2) async {
  try {
    final sentMessages = await GetAllbySenderAndRecieverid(user1, user2) ?? [];
    final receivedMessages = await GetAllbySenderAndRecieverid(user2, user1) ?? [];
    
    final allMessages = [...sentMessages, ...receivedMessages];
    
    
    allMessages.sort((a, b) {
      final aDate = a.from_user_date ?? DateTime(0);
      final bDate = b.from_user_date ?? DateTime(0);
      return bDate.compareTo(aDate); 
    });
    
    return allMessages;
  } catch (e) {
    print('Error getting conversation: $e');
    return [];
  }
}
}