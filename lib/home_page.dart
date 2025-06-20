import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'vital_detail_page.dart';
import 'vitals_repository.dart';
import 'settings_page.dart';
import 'auth.dart';
import 'bluetooth_page.dart'; // Import the Bluetooth page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final VitalsRepository _vitalsRepository = VitalsRepository();
  final Auth _auth = Auth();
  
  // Theme color - Maroon
  final Color _themeColor = const Color(0xFF6D071A);
  
  // User and baby information
  String _firstName = '';
  String _babyName = 'baby';
  
  // Current vital values
  double _currentHeartRate = 0.0;
  double _currentTemperature = 0.0;
  double _currentSpo2 = 0.0;

  // Normal ranges
  final _normalHeartRateRange = (120.0, 160.0); // bpm for premature infants
  final _normalTemperatureRange = (36.5, 37.5); // °C
  final _normalSpo2Range = (90.0, 100.0); // percentage

  // Alert messages
  String? _alertMessage;

  // Stream subscriptions
  StreamSubscription? _heartRateSubscription;
  StreamSubscription? _temperatureSubscription;
  StreamSubscription? _spo2Subscription;
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _subscribeToVitals();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user from Auth
      final user = _auth.currentUser;
      
      if (user != null) {
        // Fetch user data from Firestore using the current user's ID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _firstName = userData['firstName'] ?? '';
            _babyName = userData['babyName'] ?? 'baby';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeRepository() {
    // Initialize the repository to start data generation and processing
    _vitalsRepository.initialize();
  }

  void _subscribeToVitals() {
    // Subscribe to heart rate updates
    _heartRateSubscription = _vitalsRepository.heartRateStream.listen((value) {
      setState(() {
        _currentHeartRate = value;
        _checkVitalSigns();
      });
    });

    // Subscribe to temperature updates
    _temperatureSubscription =
        _vitalsRepository.temperatureStream.listen((value) {
      setState(() {
        _currentTemperature = value;
        _checkVitalSigns();
      });
    });

    // Subscribe to SpO2 updates
    _spo2Subscription = _vitalsRepository.spo2Stream.listen((value) {
      setState(() {
        _currentSpo2 = value;
        _checkVitalSigns();
      });
    });
  }

  void _checkVitalSigns() {
    // Check if any vital sign is outside of normal range and set alert message
    if (!_isInNormalRange(_currentHeartRate, _normalHeartRateRange)) {
      String status = _currentHeartRate < _normalHeartRateRange.$1 ? 'too low' : 'too high';
      _alertMessage = "$_babyName's heart rate is $status";
    } else if (!_isInNormalRange(_currentTemperature, _normalTemperatureRange)) {
      String status = _currentTemperature < _normalTemperatureRange.$1 ? 'too low' : 'too high';
      _alertMessage = "$_babyName's temperature is $status";
    } else if (!_isInNormalRange(_currentSpo2, _normalSpo2Range)) {
      String status = _currentSpo2 < _normalSpo2Range.$1 ? 'too low' : 'too high';
      _alertMessage = "$_babyName's SpO₂ is $status";
    } else {
      _alertMessage = null;
    }
  }

  @override
  void dispose() {
    // Cancel subscriptions
    _heartRateSubscription?.cancel();
    _temperatureSubscription?.cancel();
    _spo2Subscription?.cancel();
    super.dispose();
  }

  // Check if value is in normal range
  bool _isInNormalRange(double value, (double, double) range) {
    return value >= range.$1 && value <= range.$2;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BuriCare Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) => _fetchUserData()); // Refresh user data when returning from settings
            },
          ),
        ],
      ),
      // Remove any potential bottom bar space by setting resizeToAvoidBottomInset to false
      resizeToAvoidBottomInset: false,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Container(
              // Full screen height minus app bar to eliminate bottom space
              height: screenHeight - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.5), Colors.white],
                ),
              ),
              // Main content
              child: ListView(
                padding: const EdgeInsets.only(bottom: 0), // Zero bottom padding
                children: [
                  // Greeting Card - Improved to ensure text fits
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: _themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Baby Icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.child_care,  // Baby icon
                                color: Color(0xffAD5858),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Greeting Text - Improved text handling
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello ${_firstName.isNotEmpty ? _firstName : "there"},',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Let's have a look at $_babyName's vital signs",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: true,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Alert Message (if any)
                  if (_alertMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              _alertMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Vital Signs Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Vital Signs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _themeColor,
                      ),
                    ),
                  ),

                  // VITAL SIGNS LAYOUT
                  // Top row - Heart Rate and Temperature
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Heart Rate Card
                        Expanded(
                          child: _buildImprovedVitalCard(
                            title: 'Heart Rate',
                            value: _currentHeartRate,
                            unit: 'BPM',
                            icon: Icons.favorite,
                            iconColor: Colors.red,
                            isNormal: _isInNormalRange(_currentHeartRate, _normalHeartRateRange),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VitalDetailPage(
                                    vitalType: VitalType.heartRate,
                                    title: 'Heart Rate',
                                    color: Colors.red,
                                    minValue: 100.0,
                                    maxValue: 180.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Temperature Card
                        Expanded(
                          child: _buildImprovedVitalCard(
                            title: 'Temperature',
                            value: _currentTemperature,
                            unit: '°C',
                            icon: Icons.thermostat,
                            iconColor: Colors.orange,
                            isNormal: _isInNormalRange(_currentTemperature, _normalTemperatureRange),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VitalDetailPage(
                                    vitalType: VitalType.temperature,
                                    title: 'Temperature',
                                    color: Colors.orange,
                                    minValue: 35.5,
                                    maxValue: 38.5,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // SpO2 Card - Centered in its own row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: screenWidth * 0.45, // Centered triangle effect
                        child: _buildImprovedVitalCard(
                          title: 'SpO₂',
                          value: _currentSpo2,
                          unit: '%',
                          icon: Icons.air,
                          iconColor: Colors.blue,
                          isNormal: _isInNormalRange(_currentSpo2, _normalSpo2Range),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VitalDetailPage(
                                  vitalType: VitalType.spo2,
                                  title: 'SpO₂',
                                  color: Colors.blue,
                                  minValue: 85.0,
                                  maxValue: 100.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Tip of the Day
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0), // Adjusted padding
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.amber[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Tip of the Day',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Regular skin-to-skin contact with your baby can help regulate their temperature and heart rate while strengthening your bond.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      // Add Bluetooth FAB to the bottom right corner
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BluetoothPage()),
          );
        },
        backgroundColor: _themeColor,
        tooltip: 'Connect to device',
        child: const Icon(
          Icons.bluetooth, 
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildImprovedVitalCard({
    required String title,
    required double value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required bool isNormal,
    required VoidCallback onTap,
  }) {
    final Color backgroundColor = isNormal ? Colors.white : Colors.red.shade100;
    final Color textColor = isNormal ? Colors.black87 : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                icon,
                size: 28,
                color: isNormal ? iconColor : Colors.red,
              ),
              const SizedBox(height: 4),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              // Value and Unit together
              Text(
                title == 'SpO₂' ? value.toStringAsFixed(0) : value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              // Unit inside the card
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}