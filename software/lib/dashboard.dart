import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentGraphIndex = 0;

  // dummy values
  final List<FlSpot> tempData = List.generate(24, (i) => FlSpot(i.toDouble(), 15 + (i % 14).toDouble()));
  final List<FlSpot> humidityData = List.generate(24, (i) => FlSpot(i.toDouble(), 30 + (i % 50).toDouble()));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.extent(
            padding: const EdgeInsets.all(16),
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            children: const [
              StatusTile(
                name: 'Temperature',
                borderColor: AppColors.temperature,
                amount: '28°C',
                status: 'Good',
                nameIcon: Icons.thermostat,
                statusExtraText: 'Last watered: 2h ago',
                auto: 'on',
              ),
              StatusTile(
                name: 'Humidity',
                borderColor: AppColors.humidity,
                amount: '30%',
                status: 'Insufficient',
                nameIcon: Icons.water_drop,
                statusExtraText: 'Last fanned: 2h ago',
                auto: 'off',
              ),
            ],
          ),
        ),

        const SizedBox(height: 3),

        /// graph
        SizedBox(
          height: 350,
          child: PageView(
            onPageChanged: (index) => setState(() => _currentGraphIndex = index),
            children: [
              GraphChart(
                title: 'Temperature - Last 24h',
                icon: Icons.thermostat,
                color: AppColors.temperature,
                spots: tempData,
                maxY: 28,
              ),
              GraphChart(
                title: 'Humidity - Last 24h',
                icon: Icons.water_drop,
                color: AppColors.humidity,
                spots: humidityData,
                maxY: 100,
              ),
            ],
          ),
        ),

        /// dots indicator
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
  }
}

/// graph impl
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
          /// title row with icon
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

          /// graph
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
                    sideTitles: SideTitles(showTitles: false), // hide top values
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // hide right values
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
      case 'good':
        return Colors.green;
      case 'insufficient':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color get autoColor {
    switch (auto.toLowerCase()) {
      case 'on':
        return Colors.red;
      case 'off':
        return Colors.grey;
      default:
        return Colors.grey;
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
          /// 1st row
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

          /// 2nd row
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

          /// 3rd row
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
