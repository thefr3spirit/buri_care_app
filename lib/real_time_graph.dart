//real_time_graph.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'vital_model.dart';

class RealTimeGraph extends StatelessWidget {
  final List<VitalReading> readings;
  final String title;
  final Color lineColor;
  final double minY;
  final double maxY;
  final double currentValue;

  const RealTimeGraph({
    super.key,
    required this.readings,
    required this.title,
    required this.lineColor,
    required this.minY,
    required this.maxY,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Current value tile
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Current Value",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentValue.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: lineColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: readings.isEmpty
                  ? const Center(child: Text('No data available'))
                  : LineChart(
                      _createLineChartData(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _createLineChartData() {
    // For real-time display, we show the last 30 readings at most (or all if fewer)
    final maxPoints = 30;
    final displayReadings = readings.length <= maxPoints 
        ? readings 
        : readings.sublist(readings.length - maxPoints);
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxY - minY) / 5,
        verticalInterval: 5,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 5,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= displayReadings.length) {
                return const SizedBox.shrink();
              }
              
              final dateTime = displayReadings[index].timestamp;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('HH:mm:ss').format(dateTime),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY - minY) / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.black12, width: 1),
      ),
      minX: 0,
      maxX: displayReadings.length - 1.0,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(displayReadings.length, (index) {
            return FlSpot(index.toDouble(), displayReadings[index].value);
          }),
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: displayReadings.length < 15, // Show dots only when we have fewer points
          ),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}