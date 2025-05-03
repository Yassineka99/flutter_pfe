import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/user.dart';
import '../model/sub_process.dart';
import '../viewmodel/user_view_model.dart';
import '../viewmodel/sub_process_view_model.dart';

enum SortCriteria { byName, byRole, byMaxFinished }

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final UserViewModel _userViewModel = UserViewModel();
  final SubProcessViewModel _subProcessViewModel = SubProcessViewModel();
  List<User>? usersList;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userViewModel.getUsersByRoleId(3);
      setState(() {
        usersList = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleSort(SortCriteria criteria) async {
    if (usersList == null) return;

    List<User> sortedUsers = List.from(usersList!);

    switch (criteria) {
      case SortCriteria.byName:
        sortedUsers.sort((a, b) => a.name!.compareTo(b.name!));
        break;
      case SortCriteria.byRole:
        sortedUsers.sort((a, b) => a.role!.compareTo(b.role!));
        break;
      case SortCriteria.byMaxFinished:
        setState(() {
          isLoading = true;
        });
        try {
          List<UserProcessCount> userCounts = [];
          for (var user in sortedUsers) {
            var subProcesses = await _subProcessViewModel.getByUserId(user.id!);
            int count = subProcesses.where((p) => p.statusId == 3).length;
            userCounts.add(UserProcessCount(user, count));
          }
          userCounts.sort((a, b) => b.count.compareTo(a.count));
          sortedUsers = userCounts.map((e) => e.user).toList();
        } catch (e) {
          // Handle error
        } finally {
          setState(() {
            usersList = sortedUsers;
            isLoading = false;
          });
        }
        return;
      default:
        break;
    }

    setState(() {
      usersList = sortedUsers;
    });
  }

  void _showAddUserDialog() {
    final intl = AppLocalizations.of(context)!;
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String password = '';
    int role = 2;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(intl.addUser),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: intl.name),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return intl.requiredField;
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: intl.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return intl.requiredField;
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return intl.invalidEmail;
                      }
                      return null;
                    },
                    onSaved: (value) => email = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: intl.phone),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return intl.requiredField;
                      }
                      return null;
                    },
                    onSaved: (value) => phone = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: intl.password),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return intl.requiredField;
                      }
                      if (value.length < 6) {
                        return intl.passwordLength;
                      }
                      return null;
                    },
                    onSaved: (value) => password = value!,
                  ),
                  DropdownButtonFormField<int>(
                    value: role,
                    items: [
                      DropdownMenuItem(
                        value: 2,
                        child: Text(intl.manager),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(intl.worker),
                      ),
                    ],
                    onChanged: (value) {
                      role = value!;
                    },
                    decoration: InputDecoration(labelText: intl.role),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(intl.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await _userViewModel.createClient(
                        name, email, phone, password, role);
                    _loadUsers();
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(intl.errorCreatingUser)),
                    );
                  }
                }
              },
              child: Text(intl.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(intl.users),
        actions: [
          PopupMenuButton<SortCriteria>(
            icon: const Icon(Icons.filter_list),
            onSelected: _handleSort,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: SortCriteria.byName, child: Text(intl.byName)),
                PopupMenuItem(
                    value: SortCriteria.byRole, child: Text(intl.byRole)),
                PopupMenuItem(
                    value: SortCriteria.byMaxFinished,
                    child: Text(intl.byMaxFinished)),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : usersList == null
              ? Center(child: Text(intl.errorLoadingUsers))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usersList!.length,
                  itemBuilder: (context, index) {
                    final user = usersList![index];
                    return _UserCard(
                      user: user,
                      subProcessViewModel: _subProcessViewModel,
                    );
                  },
                ),
    );
  }
}

class UserProcessCount {
  final User user;
  final int count;

  UserProcessCount(this.user, this.count);
}

class _UserCard extends StatefulWidget {
  final User user;
  final SubProcessViewModel subProcessViewModel;

  const _UserCard({
    required this.user,
    required this.subProcessViewModel,
  });

  @override
  __UserCardState createState() => __UserCardState();
}

class __UserCardState extends State<_UserCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    Uint8List? imageBytes;

    if (widget.user.image != null && widget.user.image!.isNotEmpty) {
      try {
        imageBytes = base64Decode(widget.user.image!);
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: imageBytes != null
                      ? MemoryImage(imageBytes)
                      : const AssetImage('assets/images/user.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'BrandonGrotesque',
                        ),
                      ),
                      Text(
                        widget.user.role == 1
                            ? intl.admin
                            : widget.user.role == 2
                                ? intl.manager
                                : intl.worker,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'BrandonGrotesque',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<SubProcess>>(
              future: widget.subProcessViewModel.getByUserId(widget.user.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final subProcesses = snapshot.data ?? [];
                final completedCount = subProcesses.where((p) => p.statusId == 3).length;
                final totalCount = subProcesses.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          intl.assignedProcesses,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BrandonGrotesque',
                          ),
                        ),
                        Row(
                          children: [
                            _ProcessCounter(
                              count: completedCount,
                              color: Colors.green[100]!,
                              textColor: Colors.green[800]!,
                            ),
                            const SizedBox(width: 8),
                            _ProcessCounter(
                              count: totalCount,
                              color: Colors.blue[100]!,
                              textColor: Colors.blue[800]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (subProcesses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          intl.noAssignedProcesses,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ...(_isExpanded 
                              ? subProcesses 
                              : subProcesses.take(2))
                              .map((process) => _ProcessItem(process: process))
                              .toList(),
                          if (subProcesses.length > 2)
                            IconButton(
                              icon: Icon(
                                _isExpanded 
                                    ? Icons.expand_less 
                                    : Icons.expand_more,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _isExpanded = !_isExpanded),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessCounter extends StatelessWidget {
  final int count;
  final Color color;
  final Color textColor;

  const _ProcessCounter({
    required this.count,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'BrandonGrotesque',
        ),
      ),
    );
  }
}

class _ProcessItem extends StatelessWidget {
  final SubProcess process;

  const _ProcessItem({required this.process});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(process.statusId),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  process.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'BrandonGrotesque',
                  ),
                ),
                if (process.message != null)
                  Text(
                    process.message!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'BrandonGrotesque',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int? statusId) {
    switch (statusId) {
      case 1: // Pending
        return Colors.orange;
      case 2: // In Progress
        return Colors.blue;
      case 3: // Completed
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}