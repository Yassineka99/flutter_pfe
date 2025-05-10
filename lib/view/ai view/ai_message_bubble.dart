import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AIMessageBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final bool isLoading;

  const AIMessageBubble({
    super.key,
    required this.text,
    this.isUserMessage = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUserMessage)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFB5927F).withOpacity(0.15),
                child: Icon(Icons.assistant, 
                  size: 18, 
                  color: const Color(0xFF4E3A31).withOpacity(0.8),
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? const Color(0xFFB5927F) // Terracotta for user messages
                    : const Color(0xFFEDE0D4), // Warm off-white for AI
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUserMessage ? 20 : 4),
                  bottomRight: Radius.circular(isUserMessage ? 4 : 20),
                ),
                border: Border.all(
                  color: isUserMessage
                      ? const Color(0xFFB5927F).withOpacity(0.2)
                      : const Color(0xFFD3B8AB).withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF4E3A31).withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          intl.thinking,
                          style: TextStyle(
                            fontFamily: 'BrandonGrotesque',
                            color: const Color(0xFF4E3A31).withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'BrandonGrotesque',
                        color: isUserMessage
                            ? Colors.white
                            : const Color(0xFF4E3A31),
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (isUserMessage)
            Container(
              margin: const EdgeInsets.only(left: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF4E3A31).withOpacity(0.08),
                child: Icon(Icons.person, 
                  size: 18, 
                  color: const Color(0xFF4E3A31).withOpacity(0.7)),
              ),
            ),
        ],
      ),
    );
  }
}