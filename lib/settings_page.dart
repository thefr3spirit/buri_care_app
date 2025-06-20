import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'auth.dart';
import 'account_settings_page.dart';
import 'theme_provider.dart';
import 'package:app_settings/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Auth _auth = Auth();
  bool _isLoading = false;
  String _userName = '';
  String _babyName = '';
  String _email = '';
  final TextEditingController _feedbackController = TextEditingController();
  
  
  // Collapsible section state
  final Map<String, bool> _expandedSections = {
    'appSettings': false,
    'helpSupport': false,
    'userAgreement': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userData.exists && mounted) {
          setState(() {
            _userName = '${userData['firstName']} ${userData['lastName']}';
            _babyName = userData['babyName'] ?? '';
            _email = user.email ?? '';
          });
        }
      } catch (e) {
        // Handle error
        if (mounted) {
          _showSnackBar('Error loading user data: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF9A1622).withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  Future<void> _submitFeedback() async {
    final feedbackText = _feedbackController.text.trim();

    // 1) Validate non‐empty
    if (feedbackText.isEmpty) {
      _showSnackBar('Please enter your feedback before submitting');
      return;
    }

    // 2) (Optional) Make sure user is signed in before sending an email
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('You must be signed in to submit feedback');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 3) Construct a "mailto:" URI with prefilled fields:
      //
      //    - to: your development address
      //    - subject: e.g. "BuriCare Feedback from <user email>"
      //    - body: the feedback text (URI‐encoded)
      final subject =
          Uri.encodeComponent('BuriCare Feedback from ${user.email}');
      final body = Uri.encodeComponent(feedbackText);
      final mailtoUri =
          Uri.parse('mailto:obilledwin@gmail.com?subject=$subject&body=$body');

      // 4) Attempt to launch it:
      if (!await launchUrl(mailtoUri)) {
        _showSnackBar('Could not open email client. Please try again.');
      } else {
        // Optionally clear the field immediately (since user sees the draft in their mail app)
        if (mounted) {
          _feedbackController.clear();
          _showSnackBar('Email draft opened. Please tap "Send" to submit.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error opening email client: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        _showSnackBar('Could not launch $url');
      }
    } catch (e) {
      _showSnackBar('Error launching URL: $e');
    }
  }
  
  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF9A1622)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  await _auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    _showSnackBar('Error signing out: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A1622),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF9A1622),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9A1622),
              ),
            )
          : Container(
              color: Colors.grey.shade50,
              child: ListView(
                children: [
                  // Profile Section
                  Container(
                    color: const Color(0xFF9A1622).withOpacity(0.03),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        // Profile Image
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF9A1622).withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF9A1622),
                            child: Text(
                              _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // User Name
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (_babyName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.child_care,
                                color: const Color(0xFF9A1622).withOpacity(0.8),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Baby: $_babyName',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Account Settings button
                      // Account Settings button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context)
                              .push(
                                MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                              )         
                              .then((_) {
                                // When AccountSettingsPage pops, reload the user data:
                                _loadUserData();
                              }); 
                          },    
                            borderRadius: BorderRadius.circular(12),
                           child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  spreadRadius: 1,),
                              ],
                            ),
                            child: Row(
                                 children: [
                                    Icon(
                                    Icons.person_outline,
                                       color: const Color(0xFF9A1622).withOpacity(0.8),
                                    size: 22, ),
                                      const SizedBox(width: 16),
                              const Expanded(
                                      child: Text(
                                    'Edit Account',
                                      style: TextStyle(
                                            fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          ),
                                ),
                              ),      
                            const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),  
                                ], 
                              ),
                            ),
                          ),
                        ),  

                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Settings Categories
                  _buildCollapsibleSection(
                    title: 'App Settings',
                    icon: Icons.settings,
                    key: 'appSettings',
                    children: [
                      _buildSettingsSubtitle('Appearance'),
                      // Theme Toggle
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                  size: 22,
                                  color: const Color(0xFF9A1622).withOpacity(0.8),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Dark Mode',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (value) {
                                    themeProvider.toggleTheme();
                                  },
                                  activeColor: const Color(0xFF9A1622),
                                  activeTrackColor: const Color(0xFF9A1622).withOpacity(0.3),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsSubtitle('Permissions'),
                      _buildSettingsItem(
                        icon: Icons.bluetooth,
                        title: 'Bluetooth',
                        onTap: () {
                          AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        onTap: () {
                          AppSettings.openAppSettings(type: AppSettingsType.location);
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notifications',
                        onTap: () {
                          AppSettings.openAppSettings(type: AppSettingsType.notification);
                        },
                      ),
                    ],
                  ),

                  _buildCollapsibleSection(
                    title: 'Help & Support',
                    icon: Icons.help_outline,
                    key: 'helpSupport',
                    children: [
                      _buildSettingsSubtitle('Help'),
                      _buildSettingsItem(
                        icon: Icons.watch_outlined,
                        title: 'How to wear and use device',
                        onTap: () {
                          _showSnackBar('Opening device usage guide');
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.bluetooth_connected,
                        title: 'How to connect to app',
                        onTap: () {
                          _showSnackBar('Opening connection guide');
                        },
                      ),
                      
                      _buildSettingsSubtitle('FAQ'),
                      _buildSettingsItem(
                        icon: Icons.battery_charging_full_outlined,
                        title: 'How long does it take to charge device?',
                        onTap: () {
                          _showSnackBar('Opening charging information');
                        },
                        withDivider: true,
                      ),
                      _buildSettingsItem(
                        icon: Icons.wifi_tethering,
                        title: 'How far can my phone be away from device?',
                        onTap: () {
                          _showSnackBar('Opening range information');
                        },
                      ),
                      
                      _buildSettingsSubtitle('Contact Us'),
                      _buildSettingsItem(
                        icon: Icons.phone_outlined,
                        title: '+256 775 591026',
                        onTap: () {
                          _launchUrl('tel:+256775591026');
                        },
                        withDivider: true,
                      ),
                      _buildSettingsItem(
                        icon: Icons.email_outlined,
                        title: 'beofr3spirit@gmail.com',
                        onTap: () {
                          _launchUrl('mailto:beofr3spirit@gmail.com');
                        },
                        withDivider: true,
                      ),
                      _buildSettingsItem(
                        icon: Icons.language_outlined,
                        title: 'www.buri-care.com',
                        onTap: () {
                          _launchUrl('https://www.buri-care.com');
                        },
                      ),
                      
                      _buildSettingsSubtitle('Feedback'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: _feedbackController,
                                maxLines: 4,
                                maxLength: 200,
                                decoration: InputDecoration(
                                  hintText: 'Share your thoughts with us...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  counterStyle: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitFeedback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9A1622),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Submit Feedback',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  _buildCollapsibleSection(
                    title: 'User Agreement',
                    icon: Icons.description_outlined,
                    key: 'userAgreement',
                    children: [
                      _buildSettingsItem(
                        icon: Icons.gavel_outlined,
                        title: 'Terms and Conditions',
                        onTap: () {
                          _launchUrl('https://www.buri-care.com');
                        },
                      ),
                    ],
                  ),
                  
                  _buildStandaloneItem(
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onTap: () {
                      _launchUrl('https://www.buri-care.com');
                    },
                  ),
                                  
                  const SizedBox(height: 24),
                  
                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF9A1622),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: const Color(0xFF9A1622).withOpacity(0.3)),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App Version
                  Center(
                    child: Text(
                      'BuriCare v1.0.0',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required String key,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_expandedSections[key]! ? 0 : 12),
            ),
            onTap: () {
              setState(() {
                _expandedSections[key] = !_expandedSections[key]!;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF9A1622),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expandedSections[key]!
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_expandedSections[key]!)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Column(
                children: children,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStandaloneItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF9A1622),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool withDivider = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: const Color(0xFF9A1622).withOpacity(0.8),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (withDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 56,
            endIndent: 16,
            color: Colors.grey.shade300,
          ),
      ],
    );
  }
}