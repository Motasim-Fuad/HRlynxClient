import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../model/chat/sessionHistoryModel.dart';

class SessionHistoryTile extends StatelessWidget {
  final SessionHistory session;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // Add delete callback
  final bool isCurrentSession; // Add this to identify current session

  const SessionHistoryTile({
    required this.session,
    required this.onTap,
    this.onDelete, // Optional delete callback
    this.isCurrentSession = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('session_${session.id}'), // Unique key for each session
      direction: isCurrentSession
          ? DismissDirection.none // Disable swipe for current session
          : DismissDirection.endToStart, // Allow swipe for other sessions
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        // Don't show dialog for current session
        if (isCurrentSession) return false;

        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Chat'),
              content: Text('Are you sure you want to delete this chat session? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text('Delete'),
                ),
              ],
            );
          },
        ) ?? false; // Return false if dialog is dismissed
      },
      onDismissed: (direction) {
        // Call the delete callback if provided and not current session
        if (onDelete != null && !isCurrentSession) {
          onDelete!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentSession
              ? Colors.teal.shade800.withOpacity(0.3) // Highlight current session
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.lastMessage != null)
                Text(
                  session.lastMessage!.content,
                  style: TextStyle(
                    color: isCurrentSession ? Colors.white : Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Row(
                children: [
                  Text(
                    '${session.messageCount} messages • ${formatDate(session.updatedAt)}',
                    style: TextStyle(
                        color: isCurrentSession ? Colors.white70 : Colors.white54,
                        fontSize: 12
                    ),
                  ),
                  if (isCurrentSession) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          onTap: isCurrentSession ? null : onTap, // Disable tap for current session
          trailing: isCurrentSession
              ? Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ) // Show active indicator instead of swipe hint
              : Icon(
            Icons.swipe_left,
            color: Colors.white54,
            size: 16,
          ), // Visual hint for swipe action
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}