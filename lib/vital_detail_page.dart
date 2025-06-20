//vital_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'vital_model.dart';
import 'vitals_data_service.dart';
import 'vitals_repository.dart';
import 'real_time_graph.dart';
import 'time_period_graph.dart';

enum VitalType {
  heartRate,
  temperature,
  spo2,
}

class VitalDetailPage extends StatefulWidget {
  final VitalType vitalType;
  final String title;
  final Color color;
  final double minValue;
  final double maxValue;

  const VitalDetailPage({
    super.key,
    required this.vitalType,
    required this.title,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  @override
  State<VitalDetailPage> createState() => _VitalDetailPageState();
}

class _VitalDetailPageState extends State<VitalDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VitalsDataService _dataService = VitalsDataService();
  final VitalsRepository _repository = VitalsRepository();
  
  // Current value and readings list for real-time updates
  double _currentValue = 0.0;
  final List<VitalReading> _realTimeReadings = [];
  
  // Stream subscriptions
  StreamSubscription? _vitalSubscription;
  final StreamController<List<VitalReading>> _realTimeController = StreamController<List<VitalReading>>.broadcast();
  
  // Cache for historical data to prevent reloading
  Future<List<VitalReading>>? _lastHourFuture;
  Future<List<VitalReading>>? _lastDayFuture;
  Future<List<VitalReading>>? _lastMonthFuture;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _subscribeToRealTimeVital();
    
    // Pre-load historical data
    _loadHistoricalData();
  }
  
  void _loadHistoricalData() {
    _lastHourFuture = _getLastHourData();
    _lastDayFuture = _getLastDayData();
    _lastMonthFuture = _getLastMonthData();
  }
  
  void _handleTabChange() {
    // Only update the real-time stream if the first tab is selected
    if (_tabController.index == 0) {
      _realTimeController.add(List<VitalReading>.from(_realTimeReadings));
    }
  }
  
  @override
  void dispose() {
    _vitalSubscription?.cancel();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _realTimeController.close();
    super.dispose();
  }
  
  void _subscribeToRealTimeVital() {
    switch (widget.vitalType) {
      case VitalType.heartRate:
        _vitalSubscription = _repository.heartRateStream.listen(_handleVitalUpdate);
        break;
      case VitalType.temperature:
        _vitalSubscription = _repository.temperatureStream.listen(_handleVitalUpdate);
        break;
      case VitalType.spo2:
        _vitalSubscription = _repository.spo2Stream.listen(_handleVitalUpdate);
        break;
    }
  }
  
  void _handleVitalUpdate(double value) {
    // Update current value
    _currentValue = value;
    
    // Add reading to the list
    _realTimeReadings.add(VitalReading(
      value: value,
      timestamp: DateTime.now(),
    ));
    
    // Keep only the last 60 readings (1 minute at 1 reading per second)
    if (_realTimeReadings.length > 60) {
      _realTimeReadings.removeAt(0);
    }
    
    // Only emit events and rebuild if we're on the real-time tab
    if (_tabController.index == 0) {
      setState(() {}); // Update the UI to reflect new value
      _realTimeController.add(List<VitalReading>.from(_realTimeReadings));
    }
  }
  
  Stream<List<VitalReading>> _getRealTimeData() {
    // Return our controlled stream
    return _realTimeController.stream;
  }
  
  Future<List<VitalReading>> _getLastHourData() {
    switch (widget.vitalType) {
      case VitalType.heartRate:
        return _dataService.getLastHourHeartRate();
      case VitalType.temperature:
        return _dataService.getLastHourTemperature();
      case VitalType.spo2:
        return _dataService.getLastHourSpo2();
    }
  }
  
  Future<List<VitalReading>> _getLastDayData() {
    switch (widget.vitalType) {
      case VitalType.heartRate:
        return _dataService.getLastDayHeartRate();
      case VitalType.temperature:
        return _dataService.getLastDayTemperature();
      case VitalType.spo2:
        return _dataService.getLastDaySpo2();
    }
  }
  
  Future<List<VitalReading>> _getLastMonthData() {
    switch (widget.vitalType) {
      case VitalType.heartRate:
        return _dataService.getLastMonthHeartRate();
      case VitalType.temperature:
        return _dataService.getLastMonthTemperature();
      case VitalType.spo2:
        return _dataService.getLastMonthSpo2();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize stream with current data when building
    if (_realTimeReadings.isNotEmpty && _tabController.index == 0) {
      // Add initial data to the stream
      Future.microtask(() => _realTimeController.add(List<VitalReading>.from(_realTimeReadings)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.color,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Real-time'),
            Tab(text: 'Last Hour'),
            Tab(text: 'Last Day'),
            Tab(text: 'Last Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Real-time tab
          StreamBuilder<List<VitalReading>>(
            stream: _getRealTimeData(),
            initialData: _realTimeReadings,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return RealTimeGraph(
                readings: snapshot.data!,
                title: 'Real-time ${widget.title}',
                lineColor: widget.color,
                minY: widget.minValue,
                maxY: widget.maxValue,
                currentValue: _currentValue,
              );
            },
          ),
          
          // Last Hour tab - using cached future
          FutureBuilder<List<VitalReading>>(
            future: _lastHourFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final readings = snapshot.data ?? [];
              return TimePeriodGraph(
                readings: readings,
                title: 'Last Hour ${widget.title}',
                lineColor: widget.color,
                minY: widget.minValue,
                maxY: widget.maxValue,
                period: TimePeriod.hour,
              );
            },
          ),
          
          // Last Day tab - using cached future
          FutureBuilder<List<VitalReading>>(
            future: _lastDayFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final readings = snapshot.data ?? [];
              return TimePeriodGraph(
                readings: readings,
                title: 'Last Day ${widget.title}',
                lineColor: widget.color,
                minY: widget.minValue,
                maxY: widget.maxValue,
                period: TimePeriod.day,
              );
            },
          ),
          
          // Last Month tab - using cached future
          FutureBuilder<List<VitalReading>>(
            future: _lastMonthFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final readings = snapshot.data ?? [];
              return TimePeriodGraph(
                readings: readings,
                title: 'Last Month ${widget.title}',
                lineColor: widget.color,
                minY: widget.minValue,
                maxY: widget.maxValue,
                period: TimePeriod.month,
              );
            },
          ),
        ],
      ),
    );
  }
}