import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Dark green
              Color(0xFF4CAF50), // Medium green
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container with background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Calculator background
                    Container(
                      margin: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Calculator screen
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      height: 25,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            'K',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Calculator buttons
                    Positioned(
                      bottom: 15,
                      left: 20,
                      child: Container(
                        width: 20,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 45,
                      child: Container(
                        width: 20,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 70,
                      child: Container(
                        width: 20,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Chart bars
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 3,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 3,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coins
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // App name
              const Text(
                'Kantemba Finances',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart Business Management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 