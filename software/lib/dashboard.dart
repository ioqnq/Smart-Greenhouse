import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String getTimeAgo(dynamic timestamp) {
  if (timestamp == null) return "Unknown";
  
  // convert firestore number to dart int
  int seconds = 0;
  if (timestamp is int) {
    seconds = timestamp;
  } else if (timestamp is String) {
    // fallback if saved as string
    seconds = int.tryParse(timestamp) ?? 0;
  }
  
  if (seconds == 0) return "Never";

  final wateringTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  final diff = DateTime.now().difference(wateringTime);

  if (diff.isNegative) {
      return "Just now";
  }

  if (diff.inSeconds < 60) {
    return "Just now";
  } else if (diff.inMinutes < 60) {
    return "${diff.inMinutes}m ago";
  } else if (diff.inHours < 24) {
    return "${diff.inHours}h ago";
  } else {
    return "${diff.inDays}d ago";
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentGraphIndex = 0;

  String getStatus({
  required double value,
  required double targetValue,
  double tolerance = 2,
  }) {
    final diff = (value - targetValue).abs();

    if (diff <= tolerance) {
      return 'Good';
    } else if (diff <= tolerance * 2) {
      return 'Warning';
    } else {
      return 'Bad';
    }
  }

  List<FlSpot> historyToChart(
  Map<String, dynamic> hourlyHistory,
  String stat,
  ) {
    final List<FlSpot> chartPoints = [];
    final sortedHours = hourlyHistory.keys.toList()..sort();

    for (final hourKey in sortedHours) {
      final cleanKey = hourKey.replaceAll('`', '');
      final int hour = int.tryParse(cleanKey) ?? 0;

      final Map<String, dynamic> statValuesAtHour = hourlyHistory[hourKey];
      final double value = (statValuesAtHour[stat] as num).toDouble();

      chartPoints.add(FlSpot(hour.toDouble(), value));
    }

    return chartPoints;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final greenhouse = data['greenhouse'];

        final temp = greenhouse['Temperature'];
        final humid = greenhouse['Humid'];
        final history = greenhouse['history'];

        final tempSpots = historyToChart(history, 'temp');
        final humidSpots = historyToChart(history, 'humid');

        final double tempValue = (temp['value'] as num).toDouble();
        final double tempTarget = (temp['targetTemp'] as num).toDouble();

        final double humidValue = (humid['value'] as num).toDouble();
        final double humidTarget = (humid['targetHumid'] as num).toDouble();

        final String tempStatus = getStatus(
          value: tempValue,
          targetValue: tempTarget,
        );

        final String humidStatus = getStatus(
          value: humidValue,
          targetValue: humidTarget,
        );

        // read timestamps
        final lastWateringTimestamp = humid['lastWatering'];
        final lastFanningTimestamp = temp['lastFanning'];
        
        final String wateredTimeAgo = getTimeAgo(lastWateringTimestamp);
        final String fannedTimeAgo = getTimeAgo(lastFanningTimestamp);

        return Column(
          children: [
            // status tiles
            Expanded(
              child: GridView.extent(
                padding: const EdgeInsets.all(16),
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.5,
                children: [
                  StatusTile(
                    name: 'Temperature',
                    borderColor: AppColors.temperature,
                    amount: '${temp['value']}°C',
                    status: tempStatus,
                    nameIcon: Icons.thermostat,
                    auto: '${temp['auto']}',
                    statusExtraText: 'Fanned: $fannedTimeAgo',
                    onAmountPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      // trigger fan command
                      await FirebaseFirestore.instance.collection('users').doc(uid).set({
                        'greenhouse': {
                          'Temperature': {
                            'command': true 
                          }
                        }
                      }, SetOptions(merge: true));      
                    }
                  ),
                  StatusTile(
                    name: 'Humidity',
                    borderColor: AppColors.humidity,
                    amount: '${humid['value']}%',
                    status: humidStatus,
                    nameIcon: Icons.water_drop,
                    auto: '${humid['auto']}',
                    statusExtraText: 'Watered: $wateredTimeAgo',
                    onAmountPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      // trigger water command
                      await FirebaseFirestore.instance.collection('users').doc(uid).set({
                        'greenhouse': {
                          'Humid': {
                            'command': true 
                          }
                        }
                      }, SetOptions(merge: true));      
                    }              
                  ),
                ],
              ),
            ),
                        
            const SizedBox(height: 3),

            // graph
            SizedBox(
              height: 350,
              child: PageView(
                onPageChanged: (i) => setState(() => _currentGraphIndex = i),
                children: [
                  GraphChart(
                    title: 'Temperature - Last 24h',
                    icon: Icons.thermostat,
                    color: AppColors.temperature,
                    spots: tempSpots,
                    maxY: 28,
                  ),
                  GraphChart(
                    title: 'Humidity - Last 24h',
                    icon: Icons.water_drop,
                    color: AppColors.humidity,
                    spots: humidSpots,
                    maxY: 100,
                  ),
                ],
              ),
            ),

            // graph select
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  width: _currentGraphIndex == index ? 12 : 8,
                  height: _currentGraphIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentGraphIndex == index ? Colors.black : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

}

class GraphChart extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<FlSpot> spots;
  final double maxY;

  const GraphChart({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.spots,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.grey, width: 1),
                    bottom: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                lineTouchData: const LineTouchData(
                  enabled: false,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false), 
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false), 
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        int hour = value.toInt() % 24;
                        return Text(
                          hour.toString().padLeft(2, '0') + ':00',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}

class StatusTile extends StatelessWidget {
  final String name;
  final Color borderColor;
  final String amount;
  final String status;
  final String auto;
  final IconData nameIcon;
  final VoidCallback? onAmountPressed;
  final IconData amountButtonIcon = Icons.play_arrow;
  final String statusExtraText;

  const StatusTile({
    super.key,
    required this.name,
    required this.borderColor,
    required this.amount,
    required this.status,
    this.auto = '',
    this.onAmountPressed,
    this.nameIcon = Icons.device_thermostat,
    this.statusExtraText = '',
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'good': return AppColors.success;
      case 'bad': return AppColors.danger;
      case 'warning': return AppColors.warning;
      default: return Colors.grey;
    }
  }

  Color get autoColor {
    switch (auto.toLowerCase()) {
      case 'on': return AppColors.danger;
      case 'off': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(nameIcon, color: borderColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Auto: $auto',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: autoColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  amount,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAmountPressed,
                icon: Icon(amountButtonIcon, size: 18),
                label: const Text('Action'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                status,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Colors.grey.shade700),
              ),
              const Spacer(),
              if (statusExtraText.isNotEmpty)
                Text(
                  statusExtraText,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
            ],
          ),
        ],
      ),
    );
  }
}