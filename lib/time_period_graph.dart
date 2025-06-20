//time_period_graph.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'vital_model.dart';

enum TimePeriod { hour, day, month }

class TimePeriodGraph extends StatelessWidget {
  final List<VitalReading> readings;
  final String title;
  final Color lineColor;
  final double minY;
  final double maxY;
  final TimePeriod period;

  const TimePeriodGraph({
    super.key,
    required this.readings,
    required this.title,
    required this.lineColor,
    required this.minY,
    required this.maxY,
    required this.period,
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

  String _formatTimestamp(DateTime timestamp) {
    switch (period) {
      case TimePeriod.hour:
        return DateFormat('HH:mm').format(timestamp);
      case TimePeriod.day:
        return DateFormat('HH:00').format(timestamp);
      case TimePeriod.month:
        return DateFormat('MM/dd').format(timestamp);
    }
  }

  LineChartData _createLineChartData() {
    // Calculate appropriate intervals based on period type
    final double xInterval;
    if (period == TimePeriod.month) {
      // For monthly view, show about 5-6 labels on x-axis
      xInterval = readings.length > 15 ? (readings.length / 5).toDouble() : 5;
    } else {
      // For hour and day views
      xInterval = readings.length > 10 ? (readings.length / 5).toDouble() : 1;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxY - minY) / 5,
        verticalInterval: xInterval,
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
            interval: xInterval,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= readings.length || index < 0) {
                return const SizedBox.shrink();
              }
              
              final dateTime = readings[index].timestamp;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _formatTimestamp(dateTime),
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
      maxX: readings.length - 1.0,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(readings.length, (index) {
            return FlSpot(index.toDouble(), readings[index].value);
          }),
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: readings.length < 30 && period != TimePeriod.month, // Show dots only when we have fewer points and not in month view
          ),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withOpacity(0.2),
          ),
        ),
      ],
      // Add touch interaction for better user experience
      lineTouchData: LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        // corner radius:
        tooltipBorderRadius: BorderRadius.circular(8),

        // padding inside the tooltip:
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        // margin between the tooltip and the chart:
        tooltipMargin: 4,

        // background color via callback:
        getTooltipColor: (LineBarSpot spot) =>
        Colors.white.withAlpha((0.8 * 255).round()),

        // optionally force it inside the chart bounds:
        fitInsideHorizontally: true,
        fitInsideVertically: true,

        // build the actual text items:
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((spot) {
            final reading = readings[spot.x.toInt()];
            final time = _formatTimestamp(reading.timestamp);
            final val  = reading.value.toStringAsFixed(1);
            return LineTooltipItem(
              // combine time + value on two lines
              '$time\n$val',
              const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
      ),
    ),
    );
  }
}