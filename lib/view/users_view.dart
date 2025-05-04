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
  bool _showFilters = false;
  SortCriteria? _selectedSort;
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
        setState(() => isLoading = true);
        try {
          final counts = await Future.wait(
            sortedUsers.map((user) async {
              try {
                // Add null check for user ID
                if (user.id == null) return 0;

                final completed = await _subProcessViewModel
                    .getByStatusAndUserId(3, user.id!)
                    .timeout(const Duration(seconds: 5));
                return completed.length;
              } catch (e) {
                print('Error counting processes for user ${user.id}: $e');
                return 0; // Return 0 as fallback
              }
            }),
          );

          final userCounts = List.generate(
            sortedUsers.length,
            (i) => UserProcessCount(sortedUsers[i], counts[i]),
          );

          userCounts.sort((a, b) => b.count.compareTo(a.count));
          sortedUsers = userCounts.map((e) => e.user).toList();
        } finally {
          setState(() {
            usersList = sortedUsers;
            isLoading = false;
          });
        }
        return;
    }

    setState(() => usersList = sortedUsers);
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
      return Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 16,
          ),
        ),
        child: AlertDialog(
          title: Center(
            child: Text(
              intl.addUser,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF28445C),
              ),
            ),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    label: intl.name,
                    icon: Icons.person_outline,
                    validator: (value) => value?.isEmpty ?? true ? intl.requiredField : null,
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: intl.email,
                    icon: Icons.email_outlined,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return intl.requiredField;
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                        return intl.invalidEmail;
                      }
                      return null;
                    },
                    onSaved: (value) => email = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: intl.phone,
                    icon: Icons.phone_outlined,
                    validator: (value) => value?.isEmpty ?? true ? intl.requiredField : null,
                    onSaved: (value) => phone = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: intl.password,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return intl.requiredField;
                      if (value!.length < 6) return intl.passwordLength;
                      return null;
                    },
                    onSaved: (value) => password = value!,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF28445C).withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonFormField<int>(
                      value: role,
                      icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF28445C)),
                      decoration: InputDecoration(
                        labelText: intl.role,
                        border: InputBorder.none,
                        labelStyle: TextStyle(color: const Color(0xFF28445C).withOpacity(0.6)),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 2,
                          child: Text(intl.manager, style: TextStyle(color: const Color(0xFF28445C))),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(intl.worker, style: TextStyle(color: const Color(0xFF28445C))),
                        ),
                      ],
                      onChanged: (value) => role = value!,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF78A190).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      intl.cancel,
                      style: TextStyle(
                        color: const Color(0xFF28445C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF78A190),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        try {
                          await _userViewModel.createClient(name, email, phone, password, role);
                          _loadUsers();
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(intl.errorCreatingUser)),
                          );
                        }
                      }
                    },
                    child: Text(
                      intl.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.all(24),
        ),
      );
    },
  );
}

Widget _buildFormField({
  required String label,
  required IconData icon,
  required String? Function(String?) validator,
  required void Function(String?) onSaved,
  bool obscureText = false,
}) {
  return TextFormField(
    obscureText: obscureText,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF28445C).withOpacity(0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: const Color(0xFF28445C).withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF78A190)),
      ),
      labelStyle: TextStyle(color: const Color(0xFF28445C).withOpacity(0.6)),
    ),
    validator: validator,
    onSaved: onSaved,
  );
}
Widget _buildFilterChip(SortCriteria criteria, String label) {
  return ChoiceChip(
    label: Text(label),
    selected: _selectedSort == criteria,
    onSelected: (selected) {
      setState(() {
        _selectedSort = selected ? criteria : null;
        _handleSort(_selectedSort!); // Call your sorting logic
      });
    },
    selectedColor: const Color(0xFF28445C).withOpacity(0.2),
    labelStyle: TextStyle(
      color: _selectedSort == criteria 
          ? const Color(0xFF28445C) // Active color
          : const Color(0xFF28445C).withOpacity(0.6),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
 // Track selected filter
    final intl = AppLocalizations.of(context)!;

    return Scaffold(
  appBar: AppBar(
    backgroundColor: const Color(0xFF78A190),
    title: Text(intl.users),
    iconTheme: IconThemeData(
      color: const Color(0xFF28445C).withOpacity(.40),
    ),
    actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _showFilters 
                  ? const Color(0xFF28445C) // Solid color when filters are visible
                  : const Color(0xFF28445C).withOpacity(.40), // Transparent when hidden
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
      IconButton(
        icon: Icon(Icons.add, color: const Color(0xFF28445C).withOpacity(.40)),
        onPressed: _showAddUserDialog,
      ),
    ],
  ),
  body: isLoading
      ? const Center(child: CircularProgressIndicator())
      : usersList == null
          ? Center(child: Text(intl.errorLoadingUsers))
          : Column(
              children: [
                // Filter section under AppBar
                Visibility(
                  visible: _showFilters,
                  child: Container(
                    color: Colors.white.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFilterChip(SortCriteria.byName, intl.byName),
                        _buildFilterChip(SortCriteria.byRole, intl.byRole),
                        _buildFilterChip(SortCriteria.byMaxFinished, intl.byMaxFinished),
                      ],
                    ),
                  ),
                ),
                // Main content area
                Expanded(
                  child: ListView.builder(
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
                ),
              ],
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
  int finishedsum = 0;
  late Future<Map<String, dynamic>> _combinedFuture;

  @override
  void initState() {
    super.initState();
    _combinedFuture = _loadCombinedData();
  }

  Future<Map<String, dynamic>> _loadCombinedData() async {
    final subProcesses = await widget.subProcessViewModel.getByUserId(widget.user.id!);
    final finished = await SubProcessViewModel().getByStatusAndUserId(3, widget.user.id!);
    return {
      'all': subProcesses,
      'finished': finished,
    };
  }

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
            FutureBuilder<Map<String, dynamic>>(
              future: _combinedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text(intl.errorLoadingProcesses);
                }

                final subProcesses = snapshot.data?['all'] ?? [];
                final finished = snapshot.data?['finished'] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          intl.assignedSubProcess,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BrandonGrotesque',
                          ),
                        ),
                        Row(
                          children: [
                            _ProcessCounter(
                              count: finished.length,
                              color: Colors.green[100]!,
                              textColor: Colors.green[800]!,
                            ),
                            const SizedBox(width: 8),
                            _ProcessCounter(
                              count: subProcesses.length,
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
                          intl.noAssignedSubProcesses,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ...(_isExpanded ? subProcesses : subProcesses.take(2))
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
                              onPressed: () =>
                                  setState(() => _isExpanded = !_isExpanded),
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
