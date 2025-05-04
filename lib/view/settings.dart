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

  final Map<String, String> _flags = {
    'en': 'assets/flags/us.png',
    'fr': 'assets/flags/fr.png',
    'de': 'assets/flags/de.png',
    'es': 'assets/flags/es.png',
    'ru': 'assets/flags/ru.png',
    'ar': 'assets/flags/ar.png',
  };

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
              future: NotificationViewModel().getUserId(user.id!),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.length : 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          size: 30, color: Colors.white),
                      onPressed: () {
                        // Add navigation to notifications screen
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

            // LANGUAGE CARD
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            // THEME CARD
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            // LOGOUT CARD
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: const Color(0xFFF83C31),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await session.logOut();
                      const Login();
                      // Navigate to login screen here
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
