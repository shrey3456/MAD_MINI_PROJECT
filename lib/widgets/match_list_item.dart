import 'package:flutter/material.dart';
import '../models/match_model.dart';
import 'package:intl/intl.dart';

class MatchListItem extends StatelessWidget {
  final MatchModel match;
  final VoidCallback? onTap;
  final VoidCallback? onStatusChange;

  const MatchListItem({
    Key? key,
    required this.match,
    this.onTap,
    this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${match.team1 ?? 'TBA'} vs ${match.team2 ?? 'TBA'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              SizedBox(height: 8),
              Text(
                match.venue ?? 'Venue TBA',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (onStatusChange != null)
                    IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: onStatusChange,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text = (match.status ?? 'unknown').toUpperCase();

    switch (match.status) {
      case 'upcoming':
        color = Colors.blue;
        break;
      case 'live':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDateTime() {
    if (match.date == null) return 'Date TBA';
    
    final dateStr = DateFormat('dd MMM yyyy').format(match.date!);
    final timeStr = match.time ?? 'Time TBA';
    return '$dateStr at $timeStr';
  }
}