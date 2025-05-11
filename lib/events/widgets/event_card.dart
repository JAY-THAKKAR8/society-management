import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/events/constants/event_constants.dart';
import 'package:society_management/events/model/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(EventConstants.getCategoryColor(event.category));
    final isAllDay = event.isAllDay;
    final isCancelled = event.status == EventConstants.statusCancelled;

    // Format date and time
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final startDate = dateFormat.format(event.startDateTime);
    final endDate = dateFormat.format(event.endDateTime);

    final startTime = timeFormat.format(event.startDateTime);
    final endTime = timeFormat.format(event.endDateTime);

    // Determine if it's a multi-day event
    final isMultiDay = event.startDateTime.day != event.endDateTime.day ||
        event.startDateTime.month != event.endDateTime.month ||
        event.startDateTime.year != event.endDateTime.year;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: categoryColor.withAlpha(128),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                categoryColor.withAlpha(25),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category indicator
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                              color: isCancelled ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                        if (isCancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Text(
                              'Cancelled',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Gap(8),

                    // Category
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: categoryColor,
                        ),
                        const Gap(4),
                        Text(
                          event.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),

                    // Date and time
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const Gap(4),
                        Expanded(
                          child: Text(
                            isMultiDay ? '$startDate - $endDate' : startDate,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (!isAllDay) ...[
                      const Gap(4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const Gap(4),
                          Text(
                            isMultiDay ? 'Starts: $startTime' : '$startTime - $endTime',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                    const Gap(8),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const Gap(4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
