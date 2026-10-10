import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class PhoneBookingScreen extends StatefulWidget {
  const PhoneBookingScreen({super.key});

  @override
  State<PhoneBookingScreen> createState() => _PhoneBookingScreenState();
}

class _PhoneBookingScreenState extends State<PhoneBookingScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _car = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Lucknow');
  final _price = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'Standard';
  String _service = 'Doorstep Car Wash';
  String _slot = AppConstants.timeSlots.first;
  String _payment = 'Cash';
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _car.dispose();
    _address.dispose();
    _city.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _mobile.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and mobile are required')),
      );
      return;
    }
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final message = await runGuarded(
      context,
      context.read<AdminService>().createPhoneBooking(token, {
        'customerName': _name.text.trim(),
        'mobile': _mobile.text.trim(),
        'carName': _car.text.trim(),
        'carCategory': _category,
        'service': _service,
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'date': formatYmd(_date),
        'timeSlot': _slot,
        'finalPrice': num.tryParse(_price.text.trim()) ?? 0,
        'paymentMethod': _payment,
        'notes': _notes.text.trim(),
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DeskPhoto(asset: AppConstants.coverPhoto, height: 120),
          const SizedBox(height: 14),
          const Row(
            children: [
              IconWell(icon: Icons.add_ic_call_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Book a wash from a phone call',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DeskCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Customer name',
                    prefixIcon: Icon(Icons.person_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _car,
                  decoration: const InputDecoration(
                    labelText: 'Car name',
                    prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  items: [
                    for (final item in AppConstants.carCategories)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) => setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _service,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    prefixIcon: Icon(Icons.local_car_wash_outlined, size: 20),
                  ),
                  items: [
                    for (final item in AppConstants.services)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) => setState(() => _service = value ?? _service),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _city,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DeskCard(
                  onTap: _pickDate,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: AppConstants.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(color: AppConstants.muted, fontSize: 12)),
                            Text(formatYmd(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _slot,
                  decoration: const InputDecoration(
                    labelText: 'Time slot',
                    prefixIcon: Icon(Icons.schedule_outlined, size: 20),
                  ),
                  items: [
                    for (final item in AppConstants.timeSlots)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) => setState(() => _slot = value ?? _slot),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.currency_rupee_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _payment,
                  decoration: const InputDecoration(
                    labelText: 'Payment',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'Online', child: Text('Online')),
                  ],
                  onChanged: (value) => setState(() => _payment = value ?? _payment),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.save_outlined, size: 20),
            label: Text(_busy ? 'Saving…' : 'Save booking'),
          ),
        ],
      ),
    );
  }
}

class BlockSlotScreen extends StatefulWidget {
  const BlockSlotScreen({super.key});

  @override
  State<BlockSlotScreen> createState() => _BlockSlotScreenState();
}

class _BlockSlotScreenState extends State<BlockSlotScreen> {
  final _reason = TextEditingController();
  final _city = TextEditingController(text: 'Lucknow');
  String _slot = AppConstants.timeSlots.first;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final message = await runGuarded(
      context,
      context.read<AdminService>().blockSlot(token, {
        'date': formatYmd(_date),
        'timeSlot': _slot,
        'reason': _reason.text.trim(),
        'city': _city.text.trim(),
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block a slot')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DeskCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconWell(icon: Icons.info_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Blocked slots stay closed on the website and the customer app.',
                    style: TextStyle(color: AppConstants.ink, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DeskCard(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                initialDate: _date,
              );
              if (picked != null) setState(() => _date = picked);
            },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20, color: AppConstants.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: TextStyle(color: AppConstants.muted, fontSize: 12)),
                      Text(formatYmd(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _slot,
            decoration: const InputDecoration(
              labelText: 'Slot',
              prefixIcon: Icon(Icons.schedule_outlined, size: 20),
            ),
            items: [
              const DropdownMenuItem(value: 'ALL_DAY', child: Text('All day')),
              for (final item in AppConstants.timeSlots)
                DropdownMenuItem(value: item, child: Text(item)),
            ],
            onChanged: (value) => setState(() => _slot = value ?? _slot),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              labelText: 'Reason',
              prefixIcon: Icon(Icons.notes_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.event_busy_outlined, size: 20),
            label: Text(_busy ? 'Saving…' : 'Block slot'),
          ),
        ],
      ),
    );
  }
}
