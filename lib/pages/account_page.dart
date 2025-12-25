import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthController _authController = AuthController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final user = _authController.getCurrentUser();
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('clients').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final userName = userData['full_name'] ?? 'Client';
          final email = userData['email'] ?? '';
          final phone = userData['phone'] ?? 'Not provided';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Personal Information Section
                _buildSectionHeader('Personal Information'),
                _buildInfoTile(
                  icon: Icons.person,
                  title: 'Full Name',
                  subtitle: userName,
                  onTap: () => _showEditDialog('Full Name', userName, 'full_name'),
                ),
                _buildInfoTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: email,
                  onTap: null, // Email not editable
                ),
                _buildInfoTile(
                  icon: Icons.phone,
                  title: 'Phone Number',
                  subtitle: phone,
                  onTap: () => _showEditDialog('Phone Number', phone, 'phone'),
                ),

                const SizedBox(height: 16),

                // Settings Section
                _buildSectionHeader('Settings'),
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Push Notifications',
                  subtitle: 'Receive booking updates',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildMenuTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: _selectedLanguage,
                  onTap: () => _showLanguageSelector(),
                ),

                const SizedBox(height: 16),

                // Favorite Providers Section
                _buildSectionHeader('Favorite Providers'),
                _buildFavoriteProviders(user.uid),

                const SizedBox(height: 16),

                // Help & Support Section
                _buildSectionHeader('Help & Support'),
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  subtitle: 'Frequently asked questions',
                  onTap: () => _showFAQ(),
                ),
                _buildMenuTile(
                  icon: Icons.support_agent,
                  title: 'Contact Support',
                  subtitle: 'Get help from our team',
                  onTap: () => _showContactSupport(),
                ),
                _buildMenuTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Learn about our privacy practices',
                  onTap: () => _showPrivacyPolicy(),
                ),
                _buildMenuTile(
                  icon: Icons.article,
                  title: 'Terms of Service',
                  subtitle: 'Read our terms and conditions',
                  onTap: () => _showTermsOfService(),
                ),

                const SizedBox(height: 16),

                // Logout Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Version
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.edit, size: 20) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.blue,
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildFavoriteProviders(String clientId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('clients').doc(clientId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final clientData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> favoriteIds = clientData['favorite_providers'] ?? [];

        if (favoriteIds.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.favorite_border, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No favorite providers yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: favoriteIds.length,
          itemBuilder: (context, index) {
            final providerId = favoriteIds[index];

            return FutureBuilder<DocumentSnapshot>(
              future: _db.collection('providers').doc(providerId).get(),
              builder: (context, providerSnapshot) {
                if (!providerSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final providerData = providerSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final providerName = providerData['full_name'] ?? 'Provider';
                final rating = (providerData['rating'] ?? 0.0).toDouble();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(providerName),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${rating.toStringAsFixed(1)}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      // Remove from favorites array
                      List<dynamic> updatedFavorites = List.from(favoriteIds);
                      updatedFavorites.remove(providerId);
                      
                      await _db.collection('clients').doc(clientId).set({
                        'favorite_providers': updatedFavorites,
                      }, SetOptions(merge: true));
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed from favorites')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditDialog(String fieldName, String currentValue, String firestoreField) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = _authController.getCurrentUser();
              if (user != null) {
                await _db.collection('clients').doc(user.uid).update({
                  firestoreField: controller.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$fieldName updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
                'How do I book a service?',
                'Go to the Dashboard and tap "New Booking". Select a provider, choose a date and time, then confirm.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'Can I cancel my booking?',
                'Yes, you can cancel pending bookings from the "My Bookings" page.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'How do I add a provider to favorites?',
                'Visit the provider\'s profile and tap the heart icon to add them to your favorites.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'How does the rating system work?',
                'After a confirmed appointment is completed, you can rate the service from 1 to 5 stars.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Contact us:'),
            const SizedBox(height: 16),
            _buildContactItem(Icons.email, 'Email', 'support@glowapp.com'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.phone, 'Phone', '+216 XX XXX XXX'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.schedule, 'Hours', 'Mon-Fri: 9AM - 6PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language changed to English')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'Français',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Langue changée en Français')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              await _authController.signOut();
              
              // Navigate to welcome page
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.blue),
            SizedBox(width: 8),
            Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last updated: December 23, 2025',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildPolicySection(
                'Information We Collect',
                'We collect information you provide directly to us, including your name, email address, phone number, and booking information. We also collect information about your use of our services.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'How We Use Your Information',
                'We use the information we collect to provide, maintain, and improve our services, to process your bookings, to communicate with you, and to personalize your experience.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'Information Sharing',
                'We do not sell your personal information. We may share your information with service providers who perform services on our behalf, such as hosting and data analysis.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'Data Security',
                'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'Your Rights',
                'You have the right to access, update, or delete your personal information at any time through your account settings.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.article, color: Colors.blue),
            SizedBox(width: 8),
            Text('Terms of Service'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last updated: December 23, 2025',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildPolicySection(
                'Acceptance of Terms',
                'By accessing and using this service, you accept and agree to be bound by the terms and provision of this agreement.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'Use of Service',
                'You agree to use our service only for lawful purposes and in accordance with these Terms. You are responsible for maintaining the confidentiality of your account.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'Booking and Payments',
                'All bookings are subject to availability and confirmation. Prices are subject to change without notice. Payment terms will be provided at the time of booking.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'Cancellation Policy',
                'Cancellations must be made according to the provider\'s cancellation policy. Late cancellations or no-shows may result in charges.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'User Conduct',
                'You agree not to misuse our service, interfere with its operation, or attempt to access it using any method other than the interface we provide.',
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                'Limitation of Liability',
                'We shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
