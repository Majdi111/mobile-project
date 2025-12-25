import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Photos section (takes most of the screen)
            Expanded(
              flex: 3,
              child: PageView(
                children: [
                  _buildImageSlide(
                    'assets/images/slide1.jpg',
                    'Find the Best Barbers',
                    'Discover top-rated barbers near you',
                  ),
                  _buildImageSlide(
                    'assets/images/slide2.jpg',
                    'Book Appointments',
                    'Schedule your visit with just a tap',
                  ),
                  _buildImageSlide(
                    'assets/images/slide3. jpg',
                    'Look Your Best',
                    'Get the style you deserve',
                  ),
                ],
              ),
            ),

            // Get Started Button
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/user-type');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlide(String imagePath, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replace with your actual image
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            // Use this for actual images:
            // child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
          SizedBox(height: 30),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
