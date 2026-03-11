// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notifSvc = NotificationService();
  final _permSvc  = PermissionService();

  Map<String, bool> _perms = {};
  String _selectedSound = 'three_beeps';
  DateTime _ramadanStart = DateTime(2026, 2, 19);
  DateTime _ramadanEnd   = DateTime(2026, 3, 20);

  final _sounds = [
    {'key': 'three_beeps',  'name': 'Three Beeps',   'desc': '880Hz · 3×pulse · classic alert'},
    {'key': 'soft_chime',   'name': 'Soft Chime',    'desc': 'C-E-G ascending · gentle but clear'},
    {'key': 'double_beep',  'name': 'Double Pulse',  'desc': '660Hz · 2×2 pattern · urgent feel'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final perms = await _permSvc.getPermissionStatuses();
    final prefs = await SharedPreferences.getInstance();
    final sound = prefs.getString('alarm_sound') ?? 'three_beeps';
    if (mounted) setState(() { _perms = perms; _selectedSound = sound; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d16),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: TextStyle(fontFamily: 'serif', fontSize: 24, color: Color(0xFFe6c872))),
              const SizedBox(height: 20),
              _section('ALERT SOUND', _buildSoundPicker()),
              const SizedBox(height: 16),
              _section('VIBRATION', _buildVibrationSection()),
              const SizedBox(height: 16),
              _section('RAMADAN 1447H', _buildRamadanSection()),
              const SizedBox(height: 16),
              _section('ANDROID PERMISSIONS', _buildPermissions()),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF5a6d88), letterSpacing: 1.5)),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _buildSoundPicker() {
    return Column(
      children: [
        ..._sounds.map((s) {
          final isSelected = _selectedSound == s['key'];
          return GestureDetector(
            onTap: () async {
              setState(() => _selectedSound = s['key']!);
              await _notifSvc.setAlarmSound(s['key']!);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x1ac8a84a) : const Color(0xFF141d2b),
                border: Border.all(
                  color: isSelected ? const Color(0x66c8a84a) : const Color(0xFF1c2c42),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFc8a84a) : const Color(0xFF1c2c42),
                        width: 2,
                      ),
                      color: isSelected ? const Color(0x33c8a84a) : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFc8a84a)))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(s['desc']!, style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88))),
                      ],
                    ),
                  ),
                  // Play button (visual only — implement with audioplayers package)
                  GestureDetector(
                    onTap: () => _showPlaySnackbar(s['name']!),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0x1a2dd4bf),
                        border: Border.all(color: const Color(0x332dd4bf)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Color(0xFF2dd4bf), size: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showPlaySnackbar(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: $name (add audioplayers package to implement)'),
        backgroundColor: const Color(0xFF141d2b),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildVibrationSection() {
    final patterns = [
      {'name': 'Prayer Notifications', 'desc': 'Single pulse · [0, 300ms]', 'icon': '🔔'},
      {'name': '30-min Reminders',     'desc': 'Double pulse · [0, 200, 100, 200ms]', 'icon': '⏰'},
      {'name': 'Urgent Alarm',         'desc': 'Triple heavy · [0, 300, 100, 300, 100, 300ms]', 'icon': '🚨'},
      {'name': 'Ramadan Encouragements', 'desc': 'Gentle single', 'icon': '🌙'},
    ];
    return Column(
      children: patterns.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141d2b),
          border: Border.all(color: const Color(0xFF1c2c42)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(p['icon']!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(p['desc']!, style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88))),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vibration test'), duration: Duration(seconds: 1)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1a2dd4bf),
                  border: Border.all(color: const Color(0x332dd4bf)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('📳 Test', style: TextStyle(fontSize: 11, color: Color(0xFF2dd4bf))),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRamadanSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141d2b),
        border: Border.all(color: const Color(0x38a78bfa)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _ramadanRow('Hijri Year', '1447H'),
          _ramadanRow('Ramadan Start', '19 Feb 2026', onTap: () => _pickDate(isStart: true)),
          _ramadanRow('Ramadan End', '20 Mar 2026', onTap: () => _pickDate(isStart: false)),
          _ramadanRow('Eid al-Fitr', '21 Mar 2026'),
          _ramadanRow('Encouragements', 'On · 5 per day (every 2h)'),
        ],
      ),
    );
  }

  Widget _ramadanRow(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5a6d88)))),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Text('›', style: TextStyle(color: Color(0xFF2dd4bf))),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _ramadanStart : _ramadanEnd,
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFc8a84a)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      if (isStart) {
        setState(() => _ramadanStart = picked);
        await prefs.setString('ramadan_start', picked.toIso8601String());
      } else {
        setState(() => _ramadanEnd = picked);
        await prefs.setString('ramadan_end', picked.toIso8601String());
      }
    }
  }

  Widget _buildPermissions() {
    final items = [
      {'key': 'notifications', 'name': 'Post Notifications', 'desc': 'Android 13+ runtime permission', 'icon': '🔔'},
      {'key': 'exact_alarms',  'name': 'Exact Alarms', 'desc': 'USE_EXACT_ALARM — precise prayer times', 'icon': '⏰'},
      {'key': 'battery_exempt','name': 'Battery Optimisation', 'desc': 'Exempt — prevents Samsung killing alarms', 'icon': '🔋'},
      {'key': 'camera',        'name': 'Camera', 'desc': 'Wudu sink photo verification', 'icon': '📷'},
    ];

    return Column(
      children: items.map((item) {
        final granted = _perms[item['key']] ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141d2b),
            border: Border.all(color: const Color(0xFF1c2c42)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(item['icon']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(item['desc']!, style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88))),
                  ],
                ),
              ),
              granted
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x1a4ade80),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text('✓ Granted', style: TextStyle(fontSize: 11, color: Color(0xFF4ade80))),
                    )
                  : GestureDetector(
                      onTap: () async {
                        await _permSvc.requestAllPermissions(context);
                        await _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x1afbbf24),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('⚠ Grant', style: TextStyle(fontSize: 11, color: Color(0xFFfbbf24))),
                      ),
                    ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
