import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/auth_controller.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  final AuthController _authController = AuthController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _pushNotifications = true;
  String _selectedLanguage = 'eng';

  // Helper method to format working hours
  String _formatWorkingHours(int? startingHour, int? closingHour) {
    if (startingHour == null || closingHour == null) {
      return 'Not set';
    }
    return '${startingHour.toString().padLeft(2, '0')}:00 - ${closingHour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.getCurrentUser();
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('providers').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          
          // Load saved preferences
          _pushNotifications = data['push_notifications'] ?? true;
          _selectedLanguage = data['language'] ?? 'eng';
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(data),
                
                const SizedBox(height: 16),
                
                // Personal Information Section
                _buildPersonalInfo(user.uid, data),
                
                const SizedBox(height: 16),
                
                // Settings Section
                _buildSettings(user.uid, data),
                
                const SizedBox(height: 16),
                
                // Help & Support Section
                _buildHelpSupport(),
                
                const SizedBox(height: 24),
                
                // Logout Button
                _buildLogoutButton(),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    final fullName = data['full_name'] ?? 'Provider';
    final email = data['email'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[400]!, Colors.green[600]!],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
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
    );
  }

  Widget _buildPersonalInfo(String uid, Map<String, dynamic> data) {
    final fullName = data['full_name'] ?? '';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '';
    final locationData = data['location'];
    String location = '';
    if (locationData is GeoPoint) {
      if (locationData.latitude == 0 && locationData.longitude == 0) {
        location = 'Not set';
      } else {
        location = '${locationData.latitude}, ${locationData.longitude}';
      }
    } else {
      location = locationData?.toString() ?? 'Not set';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Section Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Name - Editable
            ListTile(
              leading: const Icon(Icons.badge, color: Colors.blue),
              title: const Text('Name'),
              subtitle: Text(fullName.isEmpty ? 'Not provided' : fullName),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editName(uid, fullName),
              ),
            ),
            const Divider(height: 1),
            // Email - Read only
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email'),
              subtitle: Text(email.isEmpty ? 'Not provided' : email),
            ),
            const Divider(height: 1),
            // Phone - Editable
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Phone Number'),
              subtitle: Text(phone.isEmpty ? 'Not provided' : phone),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editPhone(uid, phone),
              ),
            ),
            const Divider(height: 1),
            // Location
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Location'),
              subtitle: Text(location.isEmpty ? 'Not set' : location),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.store, size: 18),
                label: const Text('Update Shop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _updateLocationWithGPS(uid),
              ),
            ),
            const Divider(height: 1),
            // Working Hours
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: const Text('Working Hours'),
              subtitle: Text(_formatWorkingHours(data['starting_hour'], data['closing_hour'])),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editWorkingHours(uid, data['starting_hour'] ?? 9, data['closing_hour'] ?? 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(String uid, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Section Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Push Notifications
            SwitchListTile(
              secondary: const Icon(Icons.notifications, color: Colors.purple),
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive booking updates'),
              value: _pushNotifications,
              onChanged: (value) async {
                setState(() {
                  _pushNotifications = value;
                });
                await _db.collection('providers').doc(uid).update({
                  'push_notifications': value,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Notifications enabled' : 'Notifications disabled',
                      ),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1),
            // Language
            ListTile(
              leading: const Icon(Icons.language, color: Colors.purple),
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage == 'eng' ? 'English' : 'Français'),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'eng', child: Text('English')),
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                    await _db.collection('providers').doc(uid).update({
                      'language': value,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language updated')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSupport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Section Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.help, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  const Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // FAQ
            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.teal),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showFAQ(),
            ),
            const Divider(height: 1),
            // Contact Support
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.teal),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help from our team'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showContactSupport(),
            ),
            const Divider(height: 1),
            // Privacy Policy
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.teal),
              title: const Text('Privacy Policy'),
              subtitle: const Text('How we handle your data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyPolicy(),
            ),
            const Divider(height: 1),
            // Terms of Service
            ListTile(
              leading: const Icon(Icons.description, color: Colors.teal),
              title: const Text('Terms of Service'),
              subtitle: const Text('Our terms and conditions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTermsOfService(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );

          if (confirm == true && context.mounted) {
            await _authController.signOut();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Edit Methods
  void _editName(String uid, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _db.collection('providers').doc(uid).update({
                  'full_name': controller.text,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPhone(String uid, String currentPhone) {
    final controller = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('providers').doc(uid).update({
                'phone': controller.text,
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number updated')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editWorkingHours(String uid, int currentStartingHour, int currentClosingHour) {
    int startingHour = currentStartingHour;
    int closingHour = currentClosingHour;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Working Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: startingHour,
                decoration: const InputDecoration(
                  labelText: 'Starting Hour',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: List.generate(24, (index) => index)
                    .map((hour) => DropdownMenuItem(
                          value: hour,
                          child: Text('${hour.toString().padLeft(2, '0')}:00'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    startingHour = value!;
                    if (closingHour <= startingHour) {
                      closingHour = (startingHour + 1) % 24;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: closingHour,
                decoration: const InputDecoration(
                  labelText: 'Closing Hour',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time_filled),
                ),
                items: List.generate(24, (index) => index)
                    .map((hour) => DropdownMenuItem(
                          value: hour,
                          child: Text('${hour.toString().padLeft(2, '0')}:00'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value! > startingHour) {
                    setDialogState(() => closingHour = value);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Closing hour must be after starting hour'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _db.collection('providers').doc(uid).update({
                  'starting_hour': startingHour,
                  'closing_hour': closingHour,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Working hours updated')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLocationWithGPS(String uid) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Please enable in settings.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show confirmation dialog with location details
      if (mounted) {
        _showLocationConfirmationDialog(uid, position);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showLocationConfirmationDialog(String uid, Position position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green[700]),
            const SizedBox(width: 12),
            const Expanded(child: Text('Confirm Shop Location')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your current location:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gps_fixed, size: 18, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Latitude:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    position.latitude.toStringAsFixed(6),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.gps_fixed, size: 18, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Longitude:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    position.longitude.toStringAsFixed(6),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.speed, size: 18, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Accuracy:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '±${position.accuracy.toStringAsFixed(1)} meters',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will set your shop location for customers to find you.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              // Show saving indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                // Update Firestore with GPS coordinates as GeoPoint
                await _db.collection('providers').doc(uid).update({
                  'location': GeoPoint(position.latitude, position.longitude),
                  'last_location_update': FieldValue.serverTimestamp(),
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Shop location updated successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving location: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Help & Support Methods
  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem(
                'How do I add a new service?',
                'Go to the Dashboard and tap the + icon in the app bar to add a new service.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'How do I accept bookings?',
                'Bookings appear in the Pending Confirmations section. Tap Accept to confirm.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'How are bookings managed?',
                'Bookings automatically change status based on their scheduled time and duration.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'How do I view my agenda?',
                'Navigate to the Agenda tab to see all your bookings in a calendar view.',
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
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Contact our support team:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'support@serviceapp.com',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '+216 XX XXX XXX',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Mon-Fri: 9:00 AM - 6:00 PM',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Last updated: December 2025',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Information We Collect',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We collect information you provide directly to us, including your name, email, phone number, and location.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. How We Use Your Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We use your information to provide, maintain, and improve our services, and to communicate with you.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                '3. Data Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We implement appropriate security measures to protect your personal information.',
                style: TextStyle(color: Colors.grey[700]),
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
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Last updated: December 2025',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Acceptance of Terms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'By using this service, you agree to be bound by these terms and conditions.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Service Provider Responsibilities',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You agree to provide accurate information and maintain professional conduct with clients.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                '3. Booking Policies',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You must honor confirmed bookings and provide services as described.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                '4. Cancellation Policy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You may cancel bookings with reasonable notice. Repeated cancellations may affect your account.',
                style: TextStyle(color: Colors.grey[700]),
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
}
