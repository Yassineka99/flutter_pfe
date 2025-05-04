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
      _notificationsFuture = _notificationVM.getUnreadNotifications(session.user!.id!);
    });
  }

void _showNotificationsPopup(List<model.Notification> notifications) {
  final intl = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF28445C).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF78A190).withOpacity(0.95),
              const Color(0xFF28445C).withOpacity(0.97),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (Fixed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF28445C).withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78A190).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded, 
                      color: Color(0xFFD8E6E3),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    intl.notifications,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'BrandonGrotesque',
                      color: const Color(0xFFE0F0ED),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close, 
                      color: const Color(0xFFD8E6E3).withOpacity(0.8)
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Notifications Body
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: notifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        intl.noNotifications,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'BrandonGrotesque',
                          color: const Color(0xFFE0F0ED).withOpacity(0.7),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: notifications.map((notification) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 16
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF28445C).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF78A190).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC3D7C2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF78A190).withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
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
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFE0F0ED),
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
                                            color: const Color(0xFFA8C0B5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
            ),

            // Footer (Fixed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF28445C).withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notifications.length} ${intl.notifications.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'BrandonGrotesque',
                      color: const Color(0xFF78A190).withOpacity(0.9),
                      letterSpacing: 1.1,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: const Color(0xFFC3D7C2).withOpacity(0.9),
                      size: 18,
                    ),
                    label: Text(
                      intl.markAllRead,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'BrandonGrotesque',
                        color: const Color(0xFFC3D7C2),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).then((_) {
    final session = context.read<UserSession>();
    _notificationVM.markAllAsRead(session.user!.id!).then((_) => _refreshNotifications());
  });
}

  String _getLanguageName(String localeCode, AppLocalizations intl) {
    switch (localeCode) {
      case 'en': return intl.english;
      case 'fr': return intl.french;
      case 'de': return intl.german;
      case 'es': return intl.spanish;
      case 'ru': return intl.russian;
      case 'ar': return intl.arabic;
      default: return intl.english;
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
            // PROFILE CARD
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF81ABBC),
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
                                      : const AssetImage('assets/images/user.png')
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
                            final count = snapshot.hasData ? snapshot.data!.length : 0;
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: const Color(0xFFFBD2C9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final selectedLocale = await showDialog<String>(
                        context: context,
                        builder: (_) => SimpleDialog(
                          title: Text(intl.selectLanguage,
                              textAlign: TextAlign.center),
                          children: _flags.keys
                              .map((localeCode) => SimpleDialogOption(
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                          color: Color.fromARGB(255, 228, 228, 228)),
                                      child: Center(
                                        child: Text(
                                            _getLanguageName(localeCode, intl),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'BrandonGrotesque')),
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, localeCode),
                                  ))
                              .toList(),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: const Color(0xFF774A62),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _darkMode ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.white,
                          size: 50,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _darkMode ? intl.darkTheme : intl.lightTheme,
                          style: const TextStyle(
                            fontSize: 25,
                            fontFamily: 'BrandonGrotesque',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _darkMode,
                          onChanged: (v) => setState(() => _darkMode = v),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: const Color(0xFFF83C31),
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
                          const Icon(Icons.logout,
                              color: Colors.white, size: 50),
                          const SizedBox(width: 8),
                          Text(intl.logout,
                              style: const TextStyle(
                                fontSize: 25,
                                fontFamily: 'BrandonGrotesque',
                                color: Colors.white,
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