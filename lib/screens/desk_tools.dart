import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class DeskToolsScreen extends StatelessWidget {
  const DeskToolsScreen({super.key, this.tool = ''});

  final String tool;

  @override
  Widget build(BuildContext context) {
    return switch (tool) {
      'prices' => const _PricesScreen(),
      'report' => const _DailyReportScreen(),
      'staff' => const _CreateStaffScreen(),
      'branches' => const _BranchesScreen(),
      'promos' => const _PromosScreen(),
      'payroll' => const _PayrollScreen(),
      _ => const _DeskHub(),
    };
  }
}

class DeskToolTile extends StatelessWidget {
  const DeskToolTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DeskCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          IconWell(icon: iconFor(label)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.ink),
            ),
          ),
          const Icon(Icons.chevron_right_outlined, size: 20, color: AppConstants.muted),
        ],
      ),
    );
  }

  static IconData iconFor(String label) {
    switch (label) {
      case 'Prices':
        return Icons.sell_outlined;
      case 'Daily report':
        return Icons.receipt_long_outlined;
      case 'Create staff':
        return Icons.person_add_outlined;
      case 'Branches':
        return Icons.store_outlined;
      case 'Promos':
        return Icons.local_offer_outlined;
      case 'Payroll':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }
}

const deskToolLinks = <(String, String)>[
  ('Prices', 'prices'),
  ('Daily report', 'report'),
  ('Create staff', 'staff'),
  ('Branches', 'branches'),
  ('Promos', 'promos'),
  ('Payroll', 'payroll'),
];

class _DeskHub extends StatelessWidget {
  const _DeskHub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Desk tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final link in deskToolLinks) ...[
            DeskToolTile(
              label: link.$1,
              onTap: () => context.push('/desk/tools', extra: link.$2),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PriceRow {
  _PriceRow({
    required this.category,
    required this.service,
    required this.amount,
  });

  final String category;
  final String service;
  String amount;

  bool get isBike => category.toLowerCase() == 'bike';
}

class _AddonRow {
  _AddonRow({required this.name, required this.amount});

  final String name;
  String amount;
}

class _PricesScreen extends StatefulWidget {
  const _PricesScreen();

  @override
  State<_PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<_PricesScreen> {
  List<_PriceRow> _rows = [];
  List<_AddonRow> _addons = [];
  bool _sendAddons = false;
  bool _loading = true;
  bool _busy = false;
  int _generation = 0;
  String? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final data = await runGuarded(
      context,
      context.read<AdminService>().getMap(token, AppConstants.catalog),
    );
    if (!mounted) return;
    final payload = data == null ? null : data['data'];
    final rows = <_PriceRow>[];
    final addons = <_AddonRow>[];
    var sendAddons = false;
    String? note;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final prices = map['prices'];
      if (prices is List) {
        for (final item in prices.whereType<Map>()) {
          final row = Map<String, dynamic>.from(item);
          rows.add(
            _PriceRow(
              category: row['category']?.toString() ?? '',
              service: row['service']?.toString() ?? '',
              amount: _plainNumber(row['amount']),
            ),
          );
        }
      }
      final rawAddons = map['addons'];
      if (rawAddons is List) {
        sendAddons = true;
        for (final item in rawAddons.whereType<Map>()) {
          final row = Map<String, dynamic>.from(item);
          addons.add(
            _AddonRow(
              name: row['name']?.toString() ?? '',
              amount: _plainNumber(row['amount']),
            ),
          );
        }
      }
      final festival = map['festival'];
      if (festival is Map && festival['isOfferActive'] == true) {
        note = 'Festival pricing is on. Saving writes these amounts into the catalog.';
      }
    }
    setState(() {
      _rows = rows;
      _addons = addons;
      _sendAddons = sendAddons;
      _note = note;
      _generation += 1;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final body = <String, dynamic>{
      'prices': [
        for (final row in _rows)
          {
            'category': row.category,
            'service': row.service,
            'amount': num.tryParse(row.amount) ?? 0,
          },
      ],
      if (_sendAddons)
        'addons': [
          for (final addon in _addons)
            {
              'name': addon.name,
              'amount': num.tryParse(addon.amount) ?? 0,
            },
        ],
    };
    final ok = await runOk(
      context,
      context.read<AdminService>().put(token, AppConstants.catalog, body),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prices')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: const [
                    DeskEmpty(message: 'No prices in the catalog.'),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_note != null) ...[
                      DeskCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outlined, size: 20, color: AppConstants.accent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_note!)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Row(
                      children: [
                        Icon(Icons.directions_car_outlined, size: 20, color: AppConstants.accent),
                        SizedBox(width: 8),
                        Text(
                          'Car and bike',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PriceTable(rows: _rows, generation: _generation),
                    if (_sendAddons) ...[
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.add_outlined, size: 20, color: AppConstants.accent),
                          SizedBox(width: 8),
                          Text(
                            'Add-ons',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _AddonTable(addons: _addons, generation: _generation),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.save_outlined, size: 20),
                      label: Text(_busy ? 'Saving…' : 'Save prices'),
                    ),
                  ],
                ),
    );
  }
}

class _PriceTable extends StatelessWidget {
  const _PriceTable({required this.rows, required this.generation});

  final List<_PriceRow> rows;
  final int generation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
        children: [
          const _TableHead(
            labels: ['Vehicle', 'Category', 'Service', '₹'],
            flexes: [2, 3, 3, 2],
          ),
          for (final row in rows)
            _TableLine(
              accent: row.isBike,
              children: [
                Text(row.isBike ? 'Bike' : 'Car'),
                Text(row.category),
                Text(row.service),
                _AmountField(
                  key: ValueKey('$generation|${row.category}|${row.service}'),
                  initial: row.amount,
                  onChanged: (value) => row.amount = value,
                ),
              ],
            ),
        ],
        ),
      ),
    );
  }
}

class _AddonTable extends StatelessWidget {
  const _AddonTable({required this.addons, required this.generation});

  final List<_AddonRow> addons;
  final int generation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
        children: [
          const _TableHead(labels: ['Add-on', '₹'], flexes: [3, 2]),
          for (final addon in addons)
            _TableLine(
              cells: const [3, 2],
              children: [
                Text(addon.name),
                _AmountField(
                  key: ValueKey('$generation|addon|${addon.name}'),
                  initial: addon.amount,
                  onChanged: (value) => addon.amount = value,
                ),
              ],
            ),
        ],
        ),
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead({required this.labels, required this.flexes});

  final List<String> labels;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppConstants.iconWell,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 6),
            for (var index = 0; index < labels.length; index++)
              Expanded(
                flex: index < flexes.length ? flexes[index] : 1,
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    color: AppConstants.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TableLine extends StatelessWidget {
  const _TableLine({
    required this.children,
    this.accent = false,
    this.cells = const [2, 3, 3, 2],
  });

  final List<Widget> children;
  final bool accent;
  final List<int> cells;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppConstants.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: [
            if (cells.length == 4) ...[
              Icon(
                accent ? Icons.two_wheeler_outlined : Icons.directions_car_outlined,
                size: 20,
                color: AppConstants.accent,
              ),
              const SizedBox(width: 6),
            ],
            for (var index = 0; index < children.length; index++)
              Expanded(
                flex: index < cells.length ? cells[index] : 1,
                child: children[index],
              ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({super.key, required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.accent, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _DailyReportScreen extends StatefulWidget {
  const _DailyReportScreen();

  @override
  State<_DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<_DailyReportScreen> {
  DateTime _date = DateTime.now();
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final data = await runGuarded(
      context,
      context.read<AdminService>().getMap(
            token,
            '${AppConstants.dailyReport}?date=${formatYmd(_date)}',
          ),
    );
    if (!mounted) return;
    final payload = data == null ? null : data['data'];
    setState(() {
      _report = payload is Map ? Map<String, dynamic>.from(payload) : null;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final lines = report == null
        ? const <(String, String)>[]
        : <(String, String)>[
            ('Cash', _rupee(report['cash'])),
            ('UPI', _rupee(report['upi'])),
            ('Online', _rupee(report['online'])),
            ('Collected cash', _rupee(report['collectedCash'])),
            ('Collected UPI', _rupee(report['collectedUpi'])),
            ('Unpaid', _rupee(report['unpaid'])),
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily report'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            label: Text(formatYmd(_date)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (report == null)
                  const DeskEmpty(message: 'Report could not be loaded.')
                else
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DeskCard(
                        child: Row(
                          children: [
                            IconWell(icon: _reportIcon(line.$1)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                line.$1,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                              ),
                            ),
                            Text(
                              line.$2,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppConstants.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _CreateStaffScreen extends StatefulWidget {
  const _CreateStaffScreen();

  @override
  State<_CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<_CreateStaffScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _branch = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _branch.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        !_email.text.contains('@') ||
        _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, email, and password are required')),
      );
      return;
    }
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().post(token, AppConstants.staffAccount, {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'branch': _branch.text.trim(),
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    _name.clear();
    _email.clear();
    _phone.clear();
    _password.clear();
    _branch.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff login created')),
    );
    if (context.canPop()) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create staff')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: _field('Name', icon: Icons.person_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _field('Email', icon: Icons.email_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _field('Phone', icon: Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: _field('Password', icon: Icons.lock_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _branch,
            decoration: _field('Branch', icon: Icons.store_outlined),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.person_add_outlined, size: 20),
            label: Text(_busy ? 'Saving…' : 'Create staff'),
          ),
        ],
      ),
    );
  }
}

class _BranchesScreen extends StatefulWidget {
  const _BranchesScreen();

  @override
  State<_BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<_BranchesScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final data = await runGuarded(
      context,
      context.read<AdminService>().getMap(token, AppConstants.branches),
    );
    if (!mounted) return;
    setState(() {
      _rows = _maps(data?['data']);
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and city are required')),
      );
      return;
    }
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().post(token, AppConstants.branches, {
        'name': _name.text.trim(),
        'city': _city.text.trim(),
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    _name.clear();
    _city.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: _field('Name', icon: Icons.store_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            decoration: _field('City', icon: Icons.location_city_outlined),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.add_outlined, size: 20),
            label: Text(_busy ? 'Saving…' : 'Add branch'),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LinearProgressIndicator()
          else if (_rows.isEmpty)
            const DeskEmpty(message: 'No branches yet.')
          else
            for (final row in _rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DeskCard(
                  child: Row(
                    children: [
                      const IconWell(icon: Icons.store_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${row['name'] ?? ''} · ${row['city'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _PromosScreen extends StatefulWidget {
  const _PromosScreen();

  @override
  State<_PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends State<_PromosScreen> {
  final _code = TextEditingController();
  final _value = TextEditingController();
  String _kind = 'flat';
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final data = await runGuarded(
      context,
      context.read<AdminService>().getMap(token, AppConstants.promos),
    );
    if (!mounted) return;
    setState(() {
      _rows = _maps(data?['data']);
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_code.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code is required')),
      );
      return;
    }
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().post(token, AppConstants.promos, {
        'code': _code.text.trim(),
        'kind': _kind,
        'value': num.tryParse(_value.text.trim()) ?? 0,
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    _code.clear();
    _value.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _code,
            decoration: _field('Code', icon: Icons.local_offer_outlined),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_kind),
            initialValue: _kind,
            decoration: _field('Kind', icon: Icons.category_outlined),
            items: const [
              DropdownMenuItem(value: 'percent', child: Text('percent')),
              DropdownMenuItem(value: 'flat', child: Text('flat')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _kind = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: TextInputType.number,
            decoration: _field('Value', icon: Icons.currency_rupee_outlined),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.add_outlined, size: 20),
            label: Text(_busy ? 'Saving…' : 'Add promo'),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LinearProgressIndicator()
          else if (_rows.isEmpty)
            const DeskEmpty(message: 'No promos yet.')
          else
            for (final row in _rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DeskCard(
                  child: Row(
                    children: [
                      const IconWell(icon: Icons.local_offer_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${row['code'] ?? ''} · ${row['kind'] ?? 'flat'} · ${_plainNumber(row['value'])}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _PayrollScreen extends StatefulWidget {
  const _PayrollScreen();

  @override
  State<_PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<_PayrollScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _payingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final data = await runGuarded(
      context,
      context.read<AdminService>().getMap(token, AppConstants.payroll),
    );
    if (!mounted) return;
    setState(() {
      _rows = _maps(data?['data']);
      _loading = false;
    });
  }

  Future<void> _markPaid(String id) async {
    setState(() => _payingId = id);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().put(token, AppConstants.payoutPaid(id), {}),
    );
    if (!mounted) return;
    setState(() => _payingId = null);
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _rows.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        DeskEmpty(message: 'No payouts yet.'),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final id = row['_id']?.toString() ?? '';
                        final paid = row['paid'] == true;
                        final staff = row['staff'];
                        final booking = row['booking'];
                        final name = staff is Map
                            ? (staff['name']?.toString().isNotEmpty == true
                                ? staff['name'].toString()
                                : 'Staff')
                            : 'Staff';
                        final detail = booking is Map
                            ? [
                                booking['date']?.toString() ?? '',
                                booking['service']?.toString() ?? '',
                              ].where((part) => part.isNotEmpty).join(' · ')
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DeskCard(
                          child: Row(
                            children: [
                              const IconWell(icon: Icons.account_balance_wallet_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.currency_rupee_outlined,
                                          size: 20,
                                          color: AppConstants.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${_plainNumber(row['amount'])}${detail.isEmpty ? '' : ' · $detail'}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (paid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppConstants.completedBg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Paid',
                                    style: TextStyle(
                                      color: AppConstants.completed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                FilledButton.icon(
                                  onPressed: id.isEmpty || _payingId == id
                                      ? null
                                      : () => _markPaid(id),
                                  icon: Icon(
                                    _payingId == id
                                        ? Icons.hourglass_bottom_outlined
                                        : Icons.check_circle_outlined,
                                    size: 20,
                                  ),
                                  label: Text(_payingId == id ? '…' : 'Mark paid'),
                                ),
                            ],
                          ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

InputDecoration _field(String label, {IconData? icon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
  );
}

IconData _reportIcon(String label) {
  switch (label) {
    case 'UPI':
    case 'Collected UPI':
      return Icons.qr_code_2_outlined;
    case 'Online':
      return Icons.language_outlined;
    case 'Unpaid':
      return Icons.hourglass_bottom_outlined;
    default:
      return Icons.payments_outlined;
  }
}

List<Map<String, dynamic>> _maps(Object? raw) {
  if (raw is! List) return [];
  return [
    for (final item in raw)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

String _plainNumber(Object? value) {
  final amount = value is num ? value : num.tryParse('$value') ?? 0;
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  return amount.toString();
}

String _rupee(Object? value) => '₹${_plainNumber(value)}';
