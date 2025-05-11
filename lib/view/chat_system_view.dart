import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/chat.dart';
import '../model/user.dart';
import '../viewmodel/chat_view_model.dart';
import '../viewmodel/user_view_model.dart';

class ChatSystemView extends StatefulWidget {
  final int currentUserId;

  const ChatSystemView({super.key, required this.currentUserId});

  @override
  State<ChatSystemView> createState() => _ChatSystemViewState();
}

class _ChatSystemViewState extends State<ChatSystemView> {
  final ChatViewModel _chatViewModel = ChatViewModel();
  final UserViewModel _userViewModel = UserViewModel();
  final TextEditingController _messageController = TextEditingController();
  
  List<User> _users = [];
  User? _selectedUser;
  List<Chat> _messages = [];
  bool _isLoading = true;
  bool _showContacts = true;
  

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final allUsers = await _userViewModel.getUsersByRoleId(3);
      setState(() {
        _users = allUsers.where((user) => user.id != widget.currentUserId).toList();
        if (_users.isNotEmpty) {
          _selectedUser = _users.first;
          _loadMessages();
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading users: $e');
    }
  }

  Future<void> _loadMessages() async {
  if (_selectedUser == null) {
    if (mounted) setState(() => _isLoading = false);
    return;
  }
  
  try {
    final messages = await _chatViewModel.getConversation(
      widget.currentUserId, 
      _selectedUser!.id!
    );
    
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _isLoading = false);
    print('Error loading messages: $e');
    
    // Optional: Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load messages'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _selectedUser == null) return;
    
    try {
      await _chatViewModel.create(
        _messageController.text,
        widget.currentUserId,
        _selectedUser!.id!, // Include current timestamp
      );
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      print('Error sending message: $e');
    }
  }
    String _formatMessageTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    if (date.isAfter(today)) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.isAfter(yesterday)) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
  Widget _buildUserListItem(User user) {
  final isSelected = _selectedUser?.id == user.id;

  Uint8List? imageBytes;
  if (user.image != null && user.image!.isNotEmpty) {
    try {
      imageBytes = base64Decode(user.image!);
    } catch (_) {}
  }

  return Container(
    decoration: BoxDecoration(
      color: isSelected ? Color(0xFFB5927F).withOpacity(0.1) : Colors.transparent,
      border: Border(bottom: BorderSide(color: Color(0xFF4e3a31).withOpacity(0.1))),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(0xFFB5927F).withOpacity(0.2),
        backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
        child: imageBytes == null
            ? Text(
                user.name?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(color: Color(0xFF4e3a31)),
              )
            : null,
      ),
      title: Text(
        user.name ?? 'Unknown',
        style: TextStyle(
          color: Color(0xFF4e3a31),
          fontFamily: 'BrandonGrotesque',
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        setState(() => _selectedUser = user);
        _loadMessages();
      },
    ),
  );
}



    Widget _buildMessage(Chat message, bool isCurrentUser) {
    return Column(
      crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? Color(0xFFB5927F).withOpacity(0.8)
                : Color(0xFFFDF8F4),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: isCurrentUser ? Radius.circular(12) : Radius.circular(0),
              bottomRight: isCurrentUser ? Radius.circular(0) : Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4e3a31).withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.message ?? '',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Color(0xFF4e3a31),
                  fontFamily: 'BrandonGrotesque',
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formatMessageTime(message.from_user_date),
                style: TextStyle(
                  color: isCurrentUser 
                      ? Colors.white.withOpacity(0.7)
                      : Color(0xFF4e3a31).withOpacity(0.5),
                  fontSize: 10,
                  fontFamily: 'BrandonGrotesque',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFF4e3a31).withOpacity(0.1)))),
      child: Row(
        children: [
          if (!_showContacts)
            IconButton(
              icon: Icon(Icons.people_outline, color: Color(0xFF4e3a31)),
              onPressed: () => setState(() => _showContacts = true),
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFFDF8F4),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(
                color: Color(0xFF4e3a31),
                fontFamily: 'BrandonGrotesque',
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFB5927F),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF4e3a31).withOpacity(0.1)))),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF4e3a31).withOpacity(0.1)))),
            child: Row(
              children: [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: _showContacts
                        ? Icon(Icons.arrow_back, key: Key('arrow-back'))
                        : Icon(Icons.arrow_forward, key: Key('arrow-forward')),
                  ),
                  onPressed: () => setState(() => _showContacts = !_showContacts),
                ),
                SizedBox(width: 8),
                Text(
                 " contacts",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4e3a31),
                    fontFamily: 'BrandonGrotesque',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) => _buildUserListItem(_users[index]),
            ),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;
Uint8List? selectedImageBytes;
if (_selectedUser != null &&
    _selectedUser!.image != null &&
    _selectedUser!.image!.isNotEmpty) {
  try {
    selectedImageBytes = base64Decode(_selectedUser!.image!);
  } catch (_) {
    selectedImageBytes = null;
  }
}


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFB5927F),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF4e3a31)),
        title: Text(
          intl.chat,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4e3a31).withOpacity(0.7),
            fontFamily: 'BrandonGrotesque',
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4e3a31),
                strokeWidth: 2.5,
              ),
            )
          : Row(
              children: [
                if (_showContacts) _buildContactsList(),
                Expanded(
                  child: Column(
                    children: [
                      if (_selectedUser != null)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Color(0xFF4e3a31).withOpacity(0.1)))),
                          child: Row(
                            children: [
                              if (!_showContacts)
                                IconButton(
                                  icon: Icon(Icons.people_outline, color: Color(0xFF4e3a31)),
                                  onPressed: () => setState(() => _showContacts = true),
                                ),
CircleAvatar(
  backgroundColor: Color(0xFFB5927F).withOpacity(0.2),
  child: selectedImageBytes != null
      ? ClipOval(
          child: Image.memory(
            selectedImageBytes,
            fit: BoxFit.cover,
            width: 40,
            height: 40,
          ),
        )
      : Text(
          _selectedUser?.name?.substring(0, 1).toUpperCase() ?? 'U',
          style: TextStyle(color: Color(0xFF4e3a31)),
        ),
),




                              SizedBox(width: 12),
                              Text(
                                _showContacts ? '' : (_selectedUser!.name ?? 'Unknown'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4e3a31),
                                  fontFamily: 'BrandonGrotesque',
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
  child: Container(
    color: Color(0xFFFBEFE8).withOpacity(0.3),
    child: _messages.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Color(0xFFB5927F).withOpacity(0.3)),
                SizedBox(height: 16),
                Text(
                  intl.noMessages,
                  style: TextStyle(
                    color: Color(0xFF4e3a31).withOpacity(0.4),
                    fontFamily: 'BrandonGrotesque',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadMessages,
            color: Color(0xFFB5927F),
            backgroundColor: Color(0xFFFBEFE8),
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              reverse: true,
              physics: AlwaysScrollableScrollPhysics(), // Required for RefreshIndicator
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message.from_user == widget.currentUserId;
                return _buildMessage(message, isCurrentUser);
              },
            ),
          ),
  ),
),
                      _buildChatInput(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}