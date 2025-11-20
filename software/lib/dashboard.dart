import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Dashboard', style: TextStyle(fontSize: 24)),
        ),
        Expanded(
          child: GridView.extent(
            padding: const EdgeInsets.all(16),
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: const [
              ProductTile(name: 'Temperature', color: Colors.pink, amount:'28C', status: 'Good'),
              ProductTile(name: 'Humidity', color: Colors.orange, amount:'30%', status: 'Insufficient'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Temp/humidity card
class ProductTile extends StatelessWidget {
  final String name;
  final Color color;
  final String amount;
  final String status;

  const ProductTile({super.key, required this.name, required this.color, required this.amount, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: <Widget>[
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}