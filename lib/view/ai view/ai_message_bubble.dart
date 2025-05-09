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
                backgroundColor: const Color(0xFF78A190).withOpacity(0.2),
                child: const Icon(Icons.assistant, size: 18, color: Color(0xFF28445C)),
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
                    ? const Color(0xFF78A190)
                    : const Color(0xFFF5F7F9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUserMessage ? 20 : 4),
                  bottomRight: Radius.circular(isUserMessage ? 4 : 20),
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF28445C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          intl.thinking,
                          style: const TextStyle(
                            fontFamily: 'BrandonGrotesque',
                            color: Color(0xFF28445C),
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
                            : const Color(0xFF28445C),
                      ),
                    ),
            ),
          ),
          if (isUserMessage)
            Container(
              margin: const EdgeInsets.only(left: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF28445C).withOpacity(0.1),
                child: const Icon(Icons.person, size: 18, color: Color(0xFF28445C)),
              ),
            ),
        ],
      ),
    );
  }
}