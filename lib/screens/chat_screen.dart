import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

/// The customer's chat on one booking. The desk can write on any booking,
/// a washer only on jobs assigned to them. New messages show while open.
class BookingChatScreen extends StatefulWidget {
  const BookingChatScreen({super.key, required this.bookingId, this.title = ''});

  final String bookingId;
  final String title;

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    final token = context.read<AuthProvider>().token;
    try {
      final rows = await context.read<AdminService>().messages(token, widget.bookingId);
      if (!mounted) return;
      final grew = rows.length != _messages.length;
      setState(() {
        _messages = rows;
        _error = null;
        _loading = false;
      });
      if (grew) _toBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!quiet || _messages.isEmpty) _error = error.toString();
      });
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(context, context.read<AdminService>().sendMessage(token, widget.bookingId, text));
    if (!mounted) return;
    if (ok) {
      _input.clear();
      await _load(quiet: true);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().account;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer chat'),
            if (widget.title.isNotEmpty) Text(widget.title, style: deskCaption),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          DeskEmpty(message: _error!),
                          Center(child: TextButton(onPressed: _load, child: const Text('Retry'))),
                        ],
                      )
                    : _messages.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: DeskEmpty(message: 'No messages yet. Write to the customer below.'),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _Bubble(
                              message: _messages[index],
                              mine: _messages[index].userId == me?.id,
                            ),
                          ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppConstants.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Write to the customer', counterText: ''),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      tooltip: 'Send',
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final who = switch (message.fromRole) {
      'staff' => 'Washer',
      'admin' || 'superadmin' => 'Desk',
      _ => 'Customer',
    };
    final customer = message.fromRole == 'customer';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: mine ? AppConstants.iconWell : (customer ? AppConstants.pendingBg : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: Border.all(color: AppConstants.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mine ? 'You' : who, style: deskCaption.copyWith(color: AppConstants.accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(message.body, style: deskBody),
            const SizedBox(height: 2),
            Text(whenText(message.at), style: deskCaption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// Every booking with a conversation, newest first. Threads where the
/// customer wrote last are marked as waiting for a reply.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<InboxThread> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    final rows = await runGuarded(context, context.read<AdminService>().inbox(token));
    if (!mounted) return;
    setState(() {
      if (rows != null) _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _rows.where((row) => row.waiting).length;
    return Scaffold(
      appBar: AppBar(title: Text(waiting == 0 ? 'Customer chats' : 'Customer chats · $waiting waiting')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _rows.isEmpty ? 1 : _rows.length,
                itemBuilder: (context, index) {
                  if (_rows.isEmpty) return const DeskEmpty(message: 'No customer chats yet.');
                  final row = _rows[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DeskCard(
                      onTap: () async {
                        await context.push(
                          Uri(path: '/desk/chat/${row.bookingId}', queryParameters: {'title': row.customer}).toString(),
                        );
                        if (mounted) _load();
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconWell(icon: row.waiting ? Icons.mark_chat_unread_outlined : Icons.chat_bubble_outline),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(row.customer, maxLines: 1, overflow: TextOverflow.ellipsis, style: deskRow),
                                    ),
                                    Text(whenText(row.at), style: deskCaption),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [row.service, row.date].where((part) => part.isNotEmpty).join(' · '),
                                  style: deskCaption,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  row.last,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: deskBody.copyWith(
                                    fontWeight: row.waiting ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                                if (row.waiting)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Waiting for a reply',
                                      style: deskCaption.copyWith(color: AppConstants.pending, fontWeight: FontWeight.w700),
                                    ),
                                  ),
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
