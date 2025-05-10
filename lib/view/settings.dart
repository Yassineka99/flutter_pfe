import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:front/view/login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../model/user_session.dart';
import '../services/locale_provider.dart';
import '../services/theme_provider.dart';
import '../viewmodel/notification_view_model.dart';
import '../viewmodel/user_view_model.dart';
import '../model/notification.dart' as model;

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _picker = ImagePicker();
  bool _loadingImage = false;
  bool _darkMode = false;
  late Future<List<model.Notification>> _notificationsFuture;
  final NotificationViewModel _notificationVM = NotificationViewModel();
  final Map<String, String> _flags = {
    'en': 'assets/flags/us.png',
    'fr': 'assets/flags/fr.png',
    'de': 'assets/flags/de.png',
    'es': 'assets/flags/es.png',
    'ru': 'assets/flags/ru.png',
    'ar': 'assets/flags/ar.png',
  };
/*-----------------------------------------Build Methodes --------------------------------------*/
  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  void _refreshNotifications() {
    final session = context.read<UserSession>();
    setState(() {
      _notificationsFuture =
          _notificationVM.getUnreadNotifications(session.user!.id!);
    });
  }

 void _showNotificationsPopup(List<model.Notification> notifications) {
    final intl = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: _dialogShape,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5E6DC), // New background color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildDialogHeader(intl.notifications, Icons.notifications_none_rounded),

              // Notifications Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    notifications.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              intl.noNotifications,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'BrandonGrotesque',
                                color: Color(0xFF4e3a31).withOpacity(0.6),
                              ),
                            ),
                          )
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.4),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: notifications.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 16, color: Colors.transparent),
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB5927F).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFB5927F).withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        child: Icon(Icons.circle,
                                            size: 12, color: Color(0xFF4e3a31)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notification.message ?? '',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'BrandonGrotesque',
                                                color: Color(0xFF4e3a31),
                                                height: 1.4,
                                              ),
                                            ),
                                            if (notification.visibility != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  'Status: ${notification.visibility}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'BrandonGrotesque',
                                                    color: Color(0xFF4e3a31).withOpacity(0.8),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                child: _buildDialogActionButtons(
                  onCancel: () => Navigator.pop(context),
                  onConfirm: () {
                    Navigator.pop(context);
                    final session = context.read<UserSession>();
                    _notificationVM
                        .markAllAsRead(session.user!.id!)
                        .then((_) => _refreshNotifications());
                  },
                  confirmColor: const Color(0xFFB5927F),
                  confirmText: intl.markAllRead,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String localeCode, AppLocalizations intl) {
    switch (localeCode) {
      case 'en':
        return intl.english;
      case 'fr':
        return intl.french;
      case 'de':
        return intl.german;
      case 'es':
        return intl.spanish;
      case 'ru':
        return intl.russian;
      case 'ar':
        return intl.arabic;
      default:
        return intl.english;
    }
  }

  Future<void> _pickAndUpload() async {
    final session = context.read<UserSession>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, maxWidth: 600);
    if (picked == null) return;

    setState(() => _loadingImage = true);
    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = lookupMimeType(picked.path) ?? 'image/jpeg';

    try {
      final updatedUser = await UserViewModel().updateUserProfilePicture(
        session.user!.id!,
        base64Image,
        mimeType,
      );
      if (updatedUser != null) await session.logIn(updatedUser);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _loadingImage = false);
    }
  }
/*-----------------------------------------Build Widgets --------------------------------------*/

  /* ---------------------------Notification popup design  -----------------------*/
 Widget _buildDialogHeader(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFB5927F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: const Color(0xFF4e3a31)),
        ),
        const SizedBox(height: 16),
        Text(title, style: _headerStyle),
      ],
    );
  }

  // Updated action buttons
  Widget _buildDialogActionButtons({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    Color confirmColor = const Color(0xFFB5927F),
    String confirmText = 'Save',
  }) {
    final intl = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(intl.cancel,
              style: const TextStyle(
                  color: Color(0xFF4e3a31),
                  fontFamily: 'BrandonGrotesque')),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: _buttonStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll(confirmColor)),
          onPressed: onConfirm,
          child: Text(confirmText,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'BrandonGrotesque')),
        ),
      ],
    );
  }

  /* ---------------------------Notification popup design --------------------- */
  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();
    final user = session.user!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final intl = AppLocalizations.of(context)!;
    final currentLocale = localeProvider.locale.languageCode;

    Uint8List? imageBytes;
    if (user.image != null && user.image!.isNotEmpty) {
      try {
        imageBytes = base64Decode(user.image!);
      } catch (_) {}
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Updated PROFILE CARD
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5927F), // Terracotta color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _loadingImage ? null : _pickAndUpload,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: imageBytes != null
                                      ? MemoryImage(imageBytes)
                                      : const AssetImage(
                                              'assets/images/user.png')
                                          as ImageProvider,
                                ),
                                if (_loadingImage)
                                  const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name ?? '',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'BrandonGrotesque',
                                      fontWeight: FontWeight.bold,
                                    )),
                                Text(user.email ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'BrandonGrotesque',
                                    )),
                                Text(
                                  user.role == 1
                                      ? intl.admin
                                      : user.role == 2
                                          ? intl.manager
                                          : intl.worker,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'BrandonGrotesque',
                                  ),
                                ),
                                Text(user.phone ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'BrandonGrotesque',
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: FutureBuilder<List<model.Notification>>(
                          future: _notificationsFuture,
                          builder: (context, snapshot) {
                            final count =
                                snapshot.hasData ? snapshot.data!.length : 0;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined,
                                      size: 30, color: Colors.white),
                                  onPressed: () {
                                    if (snapshot.hasData) {
                                      _showNotificationsPopup(snapshot.data!);
                                    }
                                  },
                                ),
                                if (count > 0)
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        count.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // LANGUAGE CARD (UNCHANGED)
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: const Color(0xFFB5927F).withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final selectedLocale = await showDialog<String>(
                  context: context,
                  builder: (_) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Color(0xFFB5927F).withOpacity(0.3), width: 1),
                    ),
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF5E6DC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              intl.selectLanguage,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4e3a31),
                                fontFamily: 'BrandonGrotesque',
                              ),
                            ),
                          ),

                          // Language Options
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.5,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: BouncingScrollPhysics(),
                              itemCount: _flags.keys.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Color(0xFFB5927F).withOpacity(0.2),
                              ),
                              itemBuilder: (context, index) {
                                final localeCode = _flags.keys.elementAt(index);
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context, localeCode),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            _flags[localeCode]!,
                                            width: 40,
                                            height: 40,
                                          ),
                                          SizedBox(width: 16),
                                          Text(
                                            _getLanguageName(localeCode, intl),
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF4e3a31),
                                              fontFamily: 'BrandonGrotesque',
                                            ),
                                          ),
                                          Spacer(),
                                          if (localeCode == currentLocale)
                                            Icon(Icons.check, 
                                              color: Color(0xFFB5927F),
                                              size: 24,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Close Button
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(intl.close,
                                style: TextStyle(
                                  color: Color(0xFFB5927F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'BrandonGrotesque',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                if (selectedLocale != null) {
                  localeProvider.setLocale(Locale(selectedLocale));
                }
              },
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            _flags[currentLocale]!,
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(width: 8),
                          Text(_getLanguageName(currentLocale, intl),
                              style: const TextStyle(
                                fontSize: 25,
                                fontFamily: 'BrandonGrotesque',
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // THEME CARD (UNCHANGED)
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: const Color(0xFFB5927F).withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _darkMode ? Icons.dark_mode : Icons.light_mode,
                         
                          size: 50,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _darkMode ? intl.darkTheme : intl.lightTheme,
                          style: TextStyle(
                            fontSize: 25,
                            fontFamily: 'BrandonGrotesque',
                            
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: context.watch<ThemeProvider>().isDarkMode,
                          onChanged: (value) => {
                            context.read<ThemeProvider>().toggleTheme(value),
                            _darkMode = value
                          },
                          activeColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // LOGOUT CARD (UNCHANGED)
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: const Color(0xFFB5927F).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await session.logOut();
                      const Login();
                    },
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout,
                              size: 50),
                          const SizedBox(width: 8),
                          Text(intl.logout,
                              style: TextStyle(
                                fontSize: 25,
                                fontFamily: 'BrandonGrotesque',
                               
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20.0)),
);

const _headerStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  color: Color(0xFF4e3a31), // Dark brown
  fontFamily: 'BrandonGrotesque',
);

const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide(color: Color(0xFFB5927F)), // Terracotta
);

final _buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFB5927F), // Terracotta
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);
