import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
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
  final TextEditingController _textController = TextEditingController();
  final List<_ChatMessageItem> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.friend.lastChatMessage != null && widget.friend.lastChatMessage!.isNotEmpty) {
      _messages.add(_ChatMessageItem(
        text: widget.friend.lastChatMessage!,
        isMe: false,
        timestamp: widget.friend.lastChatTimestamp ?? DateTime.now(),
      ));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessageItem(
        text: text,
        isMe: true,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
    });

    // Update friend's last chat message in cubit and local store
    final updatedFriend = widget.friend.copyWith(
      lastChatMessage: text,
      lastChatTimestamp: DateTime.now(),
    );
    context.read<SocialCubit>().saveUpdatedFriend(updatedFriend);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final friend = widget.friend;

    Color statusDotColor = const Color(0xFF64748B);
    if (friend.status == FriendLiveStatus.inGame) {
      statusDotColor = AppColors.red;
    } else if (friend.status == FriendLiveStatus.inLobby) {
      statusDotColor = const Color(0xFF22C55E);
    } else if (friend.status == FriendLiveStatus.away) {
      statusDotColor = const Color(0xFFEAB308);
    }

    return Container(
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
          // Header Bar
          Container(
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
                      backgroundColor: const Color(0xFF1E2633),
                      backgroundImage: friend.cardSmallArt != null
                          ? NetworkImage(friend.cardSmallArt!)
                          : null,
                      child: friend.cardSmallArt == null
                          ? Text(
                              friend.gameName.isNotEmpty ? friend.gameName[0].toUpperCase() : 'A',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                          border: Border.all(color: const Color(0xFF0F141C), width: 2),
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        friend.clientActivity ?? (friend.isOnline ? 'Online' : 'Offline'),
                        style: TextStyle(
                          fontSize: 12,
                          color: friend.status == FriendLiveStatus.inGame
                              ? AppColors.red
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF334155)),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai percakapan dengan ${friend.gameName}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: msg.isMe ? AppColors.red : const Color(0xFF1E2530),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            msg.text,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 12),
            decoration: const BoxDecoration(
              color: Color(0xFF141923),
              border: Border(top: BorderSide(color: Color(0xFF222936))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Kirim pesan ke ${friend.gameName}...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0F141C),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        borderSide: const BorderSide(color: AppColors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.red,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageItem {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  const _ChatMessageItem({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}
