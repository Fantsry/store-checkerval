import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/chat_message.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';

class SocialChatSheet extends StatefulWidget {
  final FriendEntity friend;

  const SocialChatSheet({super.key, required this.friend});

  static Future<void> show(BuildContext context, FriendEntity friend) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SocialChatSheet(friend: friend),
    );
  }

  @override
  State<SocialChatSheet> createState() => _SocialChatSheetState();
}

class _SocialChatSheetState extends State<SocialChatSheet> {
  static const int _maxMessageLength = 500;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageEntity> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool showLoading = true}) async {
    if (!mounted) return;
    final cubit = context.read<SocialCubit>();

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    final result = await cubit.getChatMessages(widget.friend.puuid);
    if (!mounted) return;

    result.when(
      success: (stored) {
        var merged = stored;
        for (final pending in _messages.where(
          (message) => message.status != ChatMessageStatus.sent,
        )) {
          merged = mergeChatMessages(merged, pending);
        }

        setState(() {
          _messages
            ..clear()
            ..addAll(merged);
          _isLoading = false;
          _loadError = null;
        });
        _scrollToBottom();
        if (merged.any((message) => !message.isMine)) {
          unawaited(cubit.markChatRead(widget.friend.puuid));
        }
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _loadError = failure.message;
        });
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;
    if (text.length > _maxMessageLength) {
      _showError('Pesan maksimal $_maxMessageLength karakter');
      return;
    }

    _textController.clear();
    await _sendText(text);
  }

  Future<void> _retryMessage(ChatMessageEntity failedMessage) async {
    if (_isSending) return;
    await _sendText(failedMessage.body, retryOf: failedMessage);
  }

  Future<void> _sendText(String text, {ChatMessageEntity? retryOf}) async {
    final cubit = context.read<SocialCubit>();
    final now = DateTime.now();
    final optimistic = ChatMessageEntity(
      id: retryOf?.id ?? 'local-${now.microsecondsSinceEpoch}',
      body: text,
      timestamp: now,
      isMine: true,
      status: ChatMessageStatus.sending,
    );

    setState(() {
      _isSending = true;
      _messages.removeWhere((message) => message.id == optimistic.id);
      _messages.add(optimistic);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    _scrollToBottom();

    final result = await cubit.sendChatMessage(
      puuid: widget.friend.puuid,
      body: text,
    );
    if (!mounted) return;

    result.when(
      success: (sent) {
        setState(() {
          _isSending = false;
          final index = _messages.indexWhere(
            (message) => message.id == optimistic.id,
          );
          if (index != -1) {
            _messages[index] = sent;
          } else {
            _messages.add(sent);
          }
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        _scrollToBottom();
      },
      failure: (failure) {
        setState(() {
          _isSending = false;
          final index = _messages.indexWhere(
            (message) => message.id == optimistic.id,
          );
          if (index != -1) {
            _messages[index] = optimistic.copyWith(
              status: ChatMessageStatus.failed,
            );
          }
        });
        _showError(failure.message);
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.lossRed),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final friend = widget.friend;

    Color statusDotColor = AppColors.textMuted;
    if (friend.status == FriendLiveStatus.inGame) {
      statusDotColor = AppColors.accent;
    } else if (friend.status == FriendLiveStatus.inLobby) {
      statusDotColor = const Color(0xFF22C55E);
    } else if (friend.status == FriendLiveStatus.away) {
      statusDotColor = AppColors.drawAmber;
    }

    return BlocListener<SocialCubit, SocialState>(
      listenWhen: (previous, current) {
        if (current is! SocialLoaded || current.isRefreshing) return false;
        return previous is! SocialLoaded ||
            previous.isRefreshing ||
            previous.friends != current.friends;
      },
      listener: (_, __) => _loadHistory(showLoading: false),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75 + bottomInset,
          decoration: const BoxDecoration(
            color: Color(0xFF0F141C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: Color(0xFF262C36), width: 1.5),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(friend, statusDotColor),
              Expanded(child: _buildMessages(friend)),
              _buildInputBar(friend, bottomInset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FriendEntity friend, Color statusDotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E242E))),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.cardElevated,
                backgroundImage: friend.cardSmallArt != null
                    ? NetworkImage(friend.cardSmallArt!)
                    : null,
                child: friend.cardSmallArt == null
                    ? Text(
                        friend.gameName.isNotEmpty
                            ? friend.gameName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusDotColor,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  friend.clientActivity ??
                      (friend.isOnline ? 'Online' : 'Offline'),
                  style: TextStyle(
                    fontSize: 12,
                    color: friend.status == FriendLiveStatus.inGame
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(FriendEntity friend) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadHistory, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF334155),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai percakapan dengan ${friend.gameName}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity message) {
    final isFailed = message.status == ChatMessageStatus.failed;
    final isSending = message.status == ChatMessageStatus.sending;

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMine ? AppColors.accent : AppColors.cardElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message.body,
              style: TextStyle(
                color: message.isMine
                    ? AppColors.onAccent
                    : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (message.isMine)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 4),
              child: isFailed
                  ? InkWell(
                      onTap: () => _retryMessage(message),
                      child: const Text(
                        'Gagal dikirim · Coba lagi',
                        style: TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 11,
                        ),
                      ),
                    )
                  : Text(
                      isSending ? 'Mengirim...' : 'Terkirim',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
            )
          else
            const SizedBox(height: 7),
        ],
      ),
    );
  }

  Widget _buildInputBar(FriendEntity friend, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 12),
      decoration: const BoxDecoration(
        color: Color(0xFF141923),
        border: Border(top: BorderSide(color: Color(0xFF222936))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              maxLength: _maxMessageLength,
              enabled: !_isSending,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Kirim pesan ke ${friend.gameName}...',
                hintStyle: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
                counterText: '',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF262C36)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF262C36)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: _isSending
                  ? AppColors.textMuted
                  : AppColors.accent,
              shape: const CircleBorder(),
            ),
            icon: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  )
                : const Icon(
                    Icons.send_rounded,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
          ),
        ],
      ),
    );
  }
}
