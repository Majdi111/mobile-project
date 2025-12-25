import 'package:flutter/material.dart';

class UserTypePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets. all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight. bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Select your role to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 60),

              // ========================================
              // CLIENT BUTTON
              // ========================================
              _buildUserTypeButton(
                context: context,
                icon: Icons.person,
                title: 'I am a Client',
                subtitle: 'Book appointments with barbers',
                color: Colors.blue,
                userType: 'client',  // ⭐ Pass userType
              ),
              SizedBox(height: 20),

              // ========================================
              // PROVIDER BUTTON
              // ========================================
              _buildUserTypeButton(
                context: context,
                icon: Icons. content_cut,
                title: 'I am a Provider',
                subtitle: 'Manage my barbershop services',
                color: Colors.green,
                userType: 'provider',  // ⭐ Pass userType
              ),
              SizedBox(height: 40),

              // Already have account
              TextButton(
                onPressed: () {
                  // Show dialog to choose user type for sign in
                  _showSignInTypeDialog(context);
                },
                child: Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.purple[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String userType,  // ⭐ userType parameter
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // ⭐ Navigate to Sign Up with userType
          Navigator.pushNamed(
            context,
            '/sign-up',
            arguments: {'userType': userType},
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets. symmetric(vertical: 20, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius. circular(15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets. all(12),
              decoration: BoxDecoration(
                color: Colors. white. withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 30, color: Colors. white),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight. bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ⭐ Dialog for Sign In - Ask user type first
  void _showSignInTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign in as... '),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons. person, color: Colors.blue),
              title: Text('Client'),
              onTap: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(
                  context,
                  '/sign-in',
                  arguments: {'userType': 'client'},
                );
              },
            ),
            ListTile(
              leading: Icon(Icons. content_cut, color: Colors.green),
              title: Text('Provider'),
              onTap: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(
                  context,
                  '/sign-in',
                  arguments: {'userType': 'provider'},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
