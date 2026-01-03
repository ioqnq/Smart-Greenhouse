import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'constants/colors.dart';
import 'login.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool loading = true;

  bool autoHumid = false;
  bool autoTemp = false;

  double targetHumid = 30;
  double targetTemp = 25;

  int waterTimeInt = 2;
  int fanTimeInt = 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final uid = user.uid;

    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = snap.data() ?? {};
    final greenhouse = (data['greenhouse'] as Map<String, dynamic>?) ?? {};
    final humid = (greenhouse['Humid'] as Map<String, dynamic>?) ?? {};
    final temp = (greenhouse['Temperature'] as Map<String, dynamic>?) ?? {};

    setState(() {
      autoHumid = (humid['auto']?.toString().toLowerCase() == 'on');
      autoTemp = (temp['auto']?.toString().toLowerCase() == 'on');

      targetHumid = (humid['targetHumid'] as num?)?.toDouble() ?? 30;
      targetTemp = (temp['targetTemp'] as num?)?.toDouble() ?? 25;

      waterTimeInt = (humid['waterTimeInt'] as num?)?.toInt() ?? 2;
      fanTimeInt = (temp['fanTimeInt'] as num?)?.toInt() ?? 2;

      loading = false;
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'greenhouse': {
        'Humid': {
          'auto': autoHumid ? 'on' : 'off',
          'targetHumid': targetHumid.round(),
          'waterTimeInt': waterTimeInt,
        },
        'Temperature': {
          'auto': autoTemp ? 'on' : 'off',
          'targetTemp': targetTemp.round(),
          'fanTimeInt': fanTimeInt,
        },
      }
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved ✅")),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _counter({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle)),
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "user";

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Hello, $email",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // HUMIDITY CARD
              _sectionCard(
                title: "Humidity",
                icon: Icons.water_drop,
                iconColor: AppColors.humidity,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Auto watering"),
                      value: autoHumid,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => autoHumid = v),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Target: ${targetHumid.round()}%"),
                    ),
                    Slider(
                      value: targetHumid,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      activeColor: AppColors.humidity,
                      onChanged: (v) => setState(() => targetHumid = v),
                    ),
                    _counter(
                      label: "Water interval (hours)",
                      value: waterTimeInt,
                      onMinus: () => setState(() {
                        waterTimeInt = waterTimeInt > 1 ? waterTimeInt - 1 : 1;
                      }),
                      onPlus: () => setState(() => waterTimeInt++),
                    ),
                  ],
                ),
              ),

              // TEMPERATURE CARD
              _sectionCard(
                title: "Temperature",
                icon: Icons.thermostat,
                iconColor: AppColors.temperature,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Auto fan"),
                      value: autoTemp,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => autoTemp = v),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Target: ${targetTemp.round()}°C"),
                    ),
                    Slider(
                      value: targetTemp,
                      min: 10,
                      max: 40,
                      divisions: 30,
                      activeColor: AppColors.temperature,
                      onChanged: (v) => setState(() => targetTemp = v),
                    ),
                    _counter(
                      label: "Fan interval (hours)",
                      value: fanTimeInt,
                      onMinus: () => setState(() {
                        fanTimeInt = fanTimeInt > 1 ? fanTimeInt - 1 : 1;
                      }),
                      onPlus: () => setState(() => fanTimeInt++),
                    ),
                  ],
                ),
              ),

              // ACTIONS CARD (Save + Logout)
              _sectionCard(
                title: "Actions",
                icon: Icons.settings,
                iconColor: AppColors.primaryDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _save,
                      child: const Text("Save"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (_) => false,
                        );
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
