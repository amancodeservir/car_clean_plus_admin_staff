import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

const _section16 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  height: 1.2,
  color: AppConstants.ink,
);

const _body14 = TextStyle(fontSize: 14, color: AppConstants.ink, height: 1.35);

const _value14 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: AppConstants.ink,
);

const _label12 = TextStyle(fontSize: 12, color: AppConstants.muted);

const _fieldRadius = BorderRadius.all(Radius.circular(16));

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.paper,
      appBar: AppBar(title: const Text('Phone booking', style: _section16)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          const DeskPhoto(asset: AppConstants.coverPhoto, height: 120),
          const SizedBox(height: 14),
          const Row(
            children: [
              _IconBadge(icon: Icons.add_ic_call_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text('Book a wash from a phone call', style: _section16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            style: _body14,
            decoration: _fieldDecoration(
              'Customer name',
              Icons.person_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mobile,
            style: _body14,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration('Mobile', Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _car,
            style: _body14,
            decoration: _fieldDecoration(
              'Car name',
              Icons.directions_car_outlined,
            ),
          ),
          const SizedBox(height: 12),
          _choiceField(
            value: _category,
            label: 'Category',
            icon: Icons.category_outlined,
            items: [
              for (final item in AppConstants.carCategories)
                DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: _body14,
                  ),
                ),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          _choiceField(
            value: _service,
            label: 'Service',
            icon: Icons.local_car_wash_outlined,
            items: [
              for (final item in AppConstants.services)
                DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: _body14,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _service = value ?? _service),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            style: _body14,
            decoration: _fieldDecoration('Address', Icons.location_on_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            style: _body14,
            decoration: _fieldDecoration('City', Icons.location_city_outlined),
          ),
          const SizedBox(height: 12),
          _DateField(value: formatYmd(_date), onTap: _pickDate),
          const SizedBox(height: 12),
          _choiceField(
            value: _slot,
            label: 'Time slot',
            icon: Icons.schedule_outlined,
            items: [
              for (final item in AppConstants.timeSlots)
                DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: _body14,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _slot = value ?? _slot),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            style: _body14,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              'Price',
              Icons.currency_rupee_outlined,
            ),
          ),
          const SizedBox(height: 12),
          _choiceField(
            value: _payment,
            label: 'Payment',
            icon: Icons.payments_outlined,
            items: const [
              DropdownMenuItem(
                value: 'Cash',
                child: Text('Cash', style: _body14),
              ),
              DropdownMenuItem(
                value: 'UPI',
                child: Text('UPI', style: _body14),
              ),
              DropdownMenuItem(
                value: 'Online',
                child: Text('Online', style: _body14),
              ),
            ],
            onChanged: (value) => setState(() => _payment = value ?? _payment),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            style: _body14,
            decoration: _fieldDecoration('Notes', Icons.notes_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _PrimaryBar(
        busy: _busy,
        icon: Icons.save_outlined,
        label: 'Save booking',
        onPressed: _save,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.paper,
      appBar: AppBar(title: const Text('Block a slot', style: _section16)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _NoteCard(
            icon: Icons.info_outlined,
            text:
                'Blocked slots stay closed on the website and the customer app.',
          ),
          const SizedBox(height: 16),
          _DateField(value: formatYmd(_date), onTap: _pickDate),
          const SizedBox(height: 12),
          _choiceField(
            value: _slot,
            label: 'Slot',
            icon: Icons.schedule_outlined,
            items: [
              const DropdownMenuItem(
                value: 'ALL_DAY',
                child: Text('All day', style: _body14),
              ),
              for (final item in AppConstants.timeSlots)
                DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: _body14,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _slot = value ?? _slot),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            style: _body14,
            decoration: _fieldDecoration('City', Icons.location_city_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            style: _body14,
            decoration: _fieldDecoration('Reason', Icons.notes_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _PrimaryBar(
        busy: _busy,
        icon: Icons.event_busy_outlined,
        label: 'Block slot',
        onPressed: _save,
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBadge(icon: icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: _body14)),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: _fieldRadius,
        side: BorderSide(color: AppConstants.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: _fieldRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: AppConstants.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date', style: _label12),
                    const SizedBox(height: 2),
                    Text(value, style: _value14),
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

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppConstants.iconWell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: AppConstants.accent),
    );
  }
}

class _PrimaryBar extends StatelessWidget {
  const _PrimaryBar({
    required this.busy,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppConstants.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: Icon(
                  busy ? Icons.hourglass_bottom_outlined : icon,
                  size: 22,
                ),
                label: Text(busy ? 'Saving…' : label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label, IconData icon) {
  const border = OutlineInputBorder(
    borderRadius: _fieldRadius,
    borderSide: BorderSide(color: AppConstants.line),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: _label12,
    floatingLabelStyle: const TextStyle(
      fontSize: 12,
      color: AppConstants.accent,
    ),
    prefixIcon: Icon(icon, size: 22, color: AppConstants.accent),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: _fieldRadius,
      borderSide: BorderSide(color: AppConstants.accent, width: 1.5),
    ),
  );
}

DropdownButtonFormField<String> _choiceField({
  required String value,
  required String label,
  required IconData icon,
  required List<DropdownMenuItem<String>> items,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    icon: const Icon(
      Icons.keyboard_arrow_down_outlined,
      size: 22,
      color: AppConstants.muted,
    ),
    style: _body14,
    borderRadius: _fieldRadius,
    decoration: _fieldDecoration(label, icon),
    items: items,
    onChanged: onChanged,
  );
}
