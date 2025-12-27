import 'package:flutter/material.dart';
import 'dart:math' as math;

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  final List<CategoryCard> categories = [
    CategoryCard(
      title: 'Hair Styling',
      imagePath: 'assets/images/hair_styling.jpg',
    ),
    CategoryCard(
      title: 'Spa & Wellness',
      imagePath: 'assets/images/spa_wellness.jpg',
    ),
    CategoryCard(
      title: 'Nail Care',
      imagePath: 'assets/images/nail_care.jpg',
    ),
    CategoryCard(
      title: 'Makeup',
      imagePath: 'assets/images/makeup.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Logo at top
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      'Glow',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.purple[400],
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Title and subtitle
              Column(
                children: [
                  Text(
                    'Welcome to Glow',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your beauty & wellness companion',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 25),

              // Rotating circular grid of images
              Expanded(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Center(
                      child: SizedBox(
                        width: 350,
                        height: 350,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (int i = 0; i < categories.length; i++)
                              _buildRotatingImageCard(i),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Get Started Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/user-type');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.purple[700],
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.purple[700],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Footer text
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Join thousands of happy customers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRotatingImageCard(int index) {
    // Calculate angle for each image (0°, 90°, 180°, 270°)
    final baseAngle = (index / 4) * 2 * math.pi;
    final rotationValue = _rotationController.value * 2 * math.pi;
    final angle = baseAngle + rotationValue;

    // Calculate position in a square formation
    final radius = 140.0; // Distance from center
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                categories[index].imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[400],
                    child: Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),

            // Dark overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),

            // Title at bottom
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  categories[index].title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
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

class CategoryCard {
  final String title;
  final String imagePath;

  CategoryCard({
    required this.title,
    required this.imagePath,
  });
}
