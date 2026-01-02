import 'package:flutter/material.dart';
import 'constants/colors.dart';
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column( 
      children: [
        // const Padding(
        //   padding: EdgeInsets.all(16.0),
        //   child: Text('Dashboard', style: TextStyle(fontSize: 24)),
        // ),
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
      ],
    );
  }
}

/// Temp/humidity card
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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// NAME ROW
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

          /// AMOUNT ROW
          Row(
            children: [
              Expanded(
                child: Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
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

          /// STATUS ROW
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (statusExtraText.isNotEmpty)
                Text(
                  statusExtraText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

