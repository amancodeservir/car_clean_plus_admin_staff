import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';
import 'desk_tools.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthProvider>().account;
    final name = account?.name ?? '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DeskCard(
          child: Row(
            children: [
              const IconWell(icon: Icons.account_circle_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Wash desk' : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppConstants.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account?.email ?? '',
                      style: const TextStyle(color: AppConstants.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _RolePill(role: account?.role ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Icon(Icons.grid_view_outlined, size: 20, color: AppConstants.accent),
            SizedBox(width: 8),
            Text(
              'Desk tools',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppConstants.ink),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DeskToolGrid(),
        const SizedBox(height: 16),
        DeskCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MoreTile(
                icon: Icons.notifications_outlined,
                title: 'Alerts',
                onTap: () => context.push('/desk/alerts'),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.person_outlined,
                title: 'Profile',
                onTap: () => context.push('/desk/profile'),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.mail_outlined,
                title: 'Enquiries',
                onTap: () => context.push('/desk/contacts'),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.photo_library_outlined,
                title: 'Gallery',
                onTap: () => context.push('/desk/gallery'),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.celebration_outlined,
                title: 'Festival offer',
                onTap: () => context.push('/desk/festival'),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.logout_outlined,
                title: 'Log out',
                iconColor: AppConstants.danger,
                onTap: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    if (role.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.iconWell,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: const TextStyle(color: AppConstants.accent, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconWell(icon: icon, iconColor: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_outlined, size: 20, color: AppConstants.muted),
      onTap: onTap,
    );
  }
}

class _DeskToolGrid extends StatelessWidget {
  const _DeskToolGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        for (final link in deskToolLinks)
          DeskToolTile(
            label: link.$1,
            onTap: () => context.push('/desk/tools', extra: link.$2),
          ),
      ],
    );
  }
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactMessage> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    final items = await runGuarded(
      context,
      context.read<AdminService>().contacts(token),
    );
    if (!mounted) return;
    setState(() {
      if (items != null) _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enquiries')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [DeskEmpty(message: 'No enquiries')],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DeskCard(
                            onTap: item.phone.isEmpty ? null : () => dialNumber(item.phone),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const IconWell(icon: Icons.mail_outlined),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.subject.isEmpty ? item.name : item.subject,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppConstants.ink,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      shortDate(item.createdAt),
                                      style: const TextStyle(color: AppConstants.muted, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(item.name, style: const TextStyle(color: AppConstants.muted)),
                                const SizedBox(height: 4),
                                Text(item.message, style: const TextStyle(color: AppConstants.ink, height: 1.35)),
                                if (item.phone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 20, color: AppConstants.accent),
                                        const SizedBox(width: 6),
                                        Text(item.phone, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ],
                                    ),
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

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    final items = await runGuarded(
      context,
      context.read<AdminService>().gallery(token),
    );
    if (!mounted) return;
    setState(() {
      if (items != null) _items = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final url = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: url,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                prefixIcon: Icon(Icons.link_outlined, size: 20),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final shot = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 40,
                    maxWidth: 800,
                  );
                  if (shot == null || !context.mounted) return;
                  final bytes = await shot.readAsBytes();
                  if (!context.mounted) return;
                  url.text = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                },
                icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                label: const Text('Pick photo'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.add_outlined, size: 20),
            label: const Text('Add'),
          ),
        ],
      ),
    );
    final imageUrl = url.text.trim();
    final imageTitle = title.text.trim();
    title.dispose();
    url.dispose();
    if (saved != true || imageUrl.isEmpty || !mounted) return;
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().createGallery(token, {
        'title': imageTitle,
        'imageUrl': imageUrl,
        'category': 'General',
        'isActive': true,
      }),
    );
    if (ok) _load();
  }

  Future<void> _toggle(GalleryItem item, bool active) async {
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().setGalleryActive(token, item.id, active),
    );
    if (ok) _load();
  }

  Future<void> _delete(GalleryItem item) async {
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().deleteGallery(token, item.id),
    );
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_outlined, size: 20),
        label: const Text('Add photo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [DeskEmpty(message: 'No photos')],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DeskCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: _galleryThumb(item.imageUrl),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title.isEmpty ? item.category : item.title,
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.isActive ? 'Visible' : 'Hidden',
                                        style: TextStyle(
                                          color: item.isActive ? AppConstants.completed : AppConstants.muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: item.isActive,
                                  onChanged: (value) => _toggle(item, value),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(item),
                                  icon: const Icon(Icons.delete_outlined, size: 22),
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

class FestivalScreen extends StatefulWidget {
  const FestivalScreen({super.key});

  @override
  State<FestivalScreen> createState() => _FestivalScreenState();
}

class _FestivalScreenState extends State<FestivalScreen> {
  FestivalSetting? _setting;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    final setting = await runGuarded(
      context,
      context.read<AdminService>().festival(token),
    );
    if (!mounted) return;
    setState(() {
      _setting = setting ?? _setting;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final setting = _setting;
    if (setting == null) return;
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().updateFestival(token, setting),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Festival offer saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final setting = _setting;
    return Scaffold(
      appBar: AppBar(title: const Text('Festival offer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : setting == null
              ? const Center(child: Text('Festival settings could not be loaded.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const DeskPhoto(asset: AppConstants.interiorWash, height: 140),
                    const SizedBox(height: 14),
                    DeskCard(
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: AppConstants.festivals.contains(setting.activeFestival)
                                ? setting.activeFestival
                                : 'GENERAL',
                            decoration: const InputDecoration(
                              labelText: 'Festival',
                              prefixIcon: Icon(Icons.celebration_outlined, size: 20),
                            ),
                            items: [
                              for (final item in AppConstants.festivals)
                                DropdownMenuItem(value: item, child: Text(item)),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _setting = FestivalSetting(
                                  activeFestival: value,
                                  isOfferActive: setting.isOfferActive,
                                  customOfferPrice: setting.customOfferPrice,
                                  customDiscount: setting.customDiscount,
                                );
                              });
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.local_offer_outlined, size: 22, color: AppConstants.accent),
                            title: const Text('Offer is active'),
                            value: setting.isOfferActive,
                            onChanged: (value) {
                              setState(() {
                                _setting = FestivalSetting(
                                  activeFestival: setting.activeFestival,
                                  isOfferActive: value,
                                  customOfferPrice: setting.customOfferPrice,
                                  customDiscount: setting.customDiscount,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.save_outlined, size: 20),
                      label: Text(_busy ? 'Saving…' : 'Save'),
                    ),
                  ],
                ),
    );
  }
}

Widget _galleryThumb(String url) {
  if (url.startsWith('data:image')) {
    final comma = url.indexOf(',');
    if (comma > 0) {
      try {
        return Image.memory(
          base64Decode(url.substring(comma + 1)),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined, size: 22),
        );
      } catch (_) {
        return const Icon(Icons.broken_image_outlined, size: 22);
      }
    }
  }
  return Image.network(
    url,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined, size: 22),
  );
}
