import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/auth_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController();

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedGender = 'male';
  DateTime? selectedDateOfBirth;
  String userType = 'client'; // ⭐ Will be set from arguments
  bool isLoading = false;
  String? errorMessage;
  GeoPoint? shopLocation;
  bool isGettingLocation = false;
  int startingHour = 9;
  int closingHour = 18;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ⭐ Get userType from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['userType'] != null) {
      userType = args['userType'];
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDateOfBirth = picked);
    }
  }

  Future<void> _getShopLocation() async {
    setState(() {
      isGettingLocation = true;
      errorMessage = null;
    });

    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Location permission denied';
            isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'Location permission permanently denied. Please enable in settings.';
          isGettingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        shopLocation = GeoPoint(position.latitude, position.longitude);
        isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Shop location captured successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error getting location: $e';
        isGettingLocation = false;
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDateOfBirth == null) {
      setState(() => errorMessage = 'Please select your date of birth');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // ⭐ Pass userType to signUp method
    final result = await _authController.signUp(
      email: emailController.text.trim(),
      password: passwordController.text,
      fullName: fullNameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      gender: selectedGender,
      dateOfBirth: selectedDateOfBirth!,
      userType: userType, // ⭐ This determines which collection to save to
      location: shopLocation,
      startingHour: userType == 'provider' ? startingHour : null,
      closingHour: userType == 'provider' ? closingHour : null,
    );

    setState(() => isLoading = false);

    if (result['success']) {
      // ⭐ Navigate based on userType
      if (result['userType'] == 'client') {
        Navigator.pushReplacementNamed(context, '/client-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/provider-dashboard');
      }
    } else {
      setState(() => errorMessage = result['error']);
      // Show error in a dialog as well
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Up Failed'),
          content: Text(result['error'] ?? 'Unknown error occurred'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ Dynamic UI based on userType
    bool isClient = userType == 'client';
    Color themeColor = isClient ? Colors.blue : Colors.green;
    String title = isClient ? 'Client Sign Up' : 'Provider Sign Up';
    IconData icon = isClient ? Icons.person : Icons.content_cut;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 50, color: themeColor),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create $userType account',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Full Name
              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your phone' : null,
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => selectedGender = value!),
              ),
              const SizedBox(height: 16),

              // Date of Birth
              InkWell(
                onTap: _selectDateOfBirth,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    selectedDateOfBirth != null
                        ? '${selectedDateOfBirth!.day}/${selectedDateOfBirth!.month}/${selectedDateOfBirth!.year}'
                        : 'Select Date',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Starting Hour and Closing Hour (Provider only)
              if (userType == 'provider')
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: startingHour,
                        decoration: InputDecoration(
                          labelText: 'Starting Hour',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        items: List.generate(24, (index) => index)
                            .map((hour) => DropdownMenuItem(
                                  value: hour,
                                  child: Text('${hour.toString().padLeft(2, '0')}:00'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            startingHour = value!;
                            if (closingHour <= startingHour) {
                              closingHour = (startingHour + 1) % 24;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: closingHour,
                        decoration: InputDecoration(
                          labelText: 'Closing Hour',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.access_time_filled),
                        ),
                        items: List.generate(24, (index) => index)
                            .map((hour) => DropdownMenuItem(
                                  value: hour,
                                  child: Text('${hour.toString().padLeft(2, '0')}:00'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value! > startingHour) {
                            setState(() => closingHour = value);
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
                    ),
                  ],
                ),
              if (userType == 'provider') const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please confirm your password'
                    : null,
              ),
              const SizedBox(height: 24),

              // Get Shop Location button (Provider only)
              if (userType == 'provider')
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Shop Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          shopLocation != null
                              ? 'Location set: ${shopLocation!.latitude.toStringAsFixed(6)}, ${shopLocation!.longitude.toStringAsFixed(6)}'
                              : 'Set your shop location to help customers find you',
                          style: TextStyle(
                            fontSize: 13,
                            color: shopLocation != null ? Colors.green[700] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: isGettingLocation ? null : _getShopLocation,
                          icon: isGettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            shopLocation != null ? 'Update Location' : 'Get Shop Location',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (userType == 'provider') const SizedBox(height: 16),

              // Error Message
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),

              // Sign Up Button
              ElevatedButton(
                onPressed: isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 16),

              // Already have account?
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/sign-in',
                    arguments: {'userType': userType},
                  );
                },
                child: const Text('Already have an account?  Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
