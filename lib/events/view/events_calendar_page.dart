import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/events/constants/event_constants.dart';
import 'package:society_management/events/model/event_model.dart';
import 'package:society_management/events/service/event_service.dart';
import 'package:society_management/events/view/event_details_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';

class EventsCalendarPage extends StatefulWidget {
  const EventsCalendarPage({super.key});

  @override
  State<EventsCalendarPage> createState() => _EventsCalendarPageState();
}

class _EventsCalendarPageState extends State<EventsCalendarPage> {
  final EventService _eventService = getIt<EventService>();

  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // Map of dates to events
  Map<DateTime, List<EventModel>> _eventsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh events when the page becomes visible in a tab view
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && route.settings.name == null) {
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _eventService.getEventsForMonth(
        _focusedMonth.year,
        _focusedMonth.month,
      );

      result.fold(
        (failure) {
          Utility.toast(message: 'Failed to load events: ${failure.message}');
          setState(() {
            _isLoading = false;
          });
        },
        (events) {
          // Group events by date
          final eventsByDate = <DateTime, List<EventModel>>{};

          for (final event in events) {
            // For multi-day events, add to each day in the range
            var currentDate = DateTime(
              event.startDateTime.year,
              event.startDateTime.month,
              event.startDateTime.day,
            );

            final endDate = DateTime(
              event.endDateTime.year,
              event.endDateTime.month,
              event.endDateTime.day,
            );

            while (!currentDate.isAfter(endDate)) {
              final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);

              if (!eventsByDate.containsKey(dateKey)) {
                eventsByDate[dateKey] = [];
              }

              eventsByDate[dateKey]!.add(event);
              currentDate = currentDate.add(const Duration(days: 1));
            }
          }

          setState(() {
            _eventsByDate = eventsByDate;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _focusedMonth = month;
    });
    _loadEvents();
  }

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _selectedDate = selectedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if this page is being shown inside a tab view
    final isInTabView = ModalRoute.of(context)?.settings.name == null;

    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildCalendarHeader(),
              _buildCalendarGrid(),
              const Divider(height: 1),
              _buildSelectedDayEvents(),
            ],
          );

    // If shown in a tab view, add a refresh button at the top right
    if (isInTabView) {
      return Column(
        children: [
          // Add a refresh button at the top
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primaryPurple),
                onPressed: _loadEvents,
                tooltip: 'Refresh events',
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    // Otherwise, show as a standalone page with app bar
    return Scaffold(
      appBar: CommonGradientAppBar(
        title: 'Events Calendar',
        gradientColors: AppColors.gradientPurplePink,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withAlpha(180),
            AppColors.primaryPink.withAlpha(128),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              final previousMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
                1,
              );
              _onMonthChanged(previousMonth);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // Month and year display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${DateFormat('MMMM').format(_focusedMonth)} ${DateFormat('yyyy').format(_focusedMonth)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Next month button
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            onPressed: () {
              final nextMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
                1,
              );
              _onMonthChanged(nextMonth);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Get the first day of the month
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);

    // Get the last day of the month
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Get the day of week for the first day (0 = Sunday, 6 = Saturday)
    final firstDayOfWeek = firstDay.weekday % 7;

    // Calculate the number of days to display (including padding)
    final daysInMonth = lastDay.day;

    // Make sure we always show at least 6 weeks (42 days) to accommodate all months
    // This ensures we have enough space for months with 31 days that start on a Saturday
    const totalWeeks = 6;

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          // Weekday headers
          const Row(
            children: [
              _WeekdayHeader(day: 'Sun'),
              _WeekdayHeader(day: 'Mon'),
              _WeekdayHeader(day: 'Tue'),
              _WeekdayHeader(day: 'Wed'),
              _WeekdayHeader(day: 'Thu'),
              _WeekdayHeader(day: 'Fri'),
              _WeekdayHeader(day: 'Sat'),
            ],
          ),

          // Calendar grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: totalWeeks * 7,
              itemBuilder: (context, index) {
                // Calculate the day to display
                final dayOffset = index - firstDayOfWeek;

                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  // Empty cell for padding
                  return const SizedBox();
                }

                final day = dayOffset + 1;
                final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);

                // Check if this date has events
                final hasEvents = _eventsByDate.containsKey(date);
                final isSelected = _selectedDate.year == date.year &&
                    _selectedDate.month == date.month &&
                    _selectedDate.day == date.day;

                return _CalendarDay(
                  day: day,
                  hasEvents: hasEvents,
                  isSelected: isSelected,
                  onTap: () => _onDaySelected(date),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    final selectedDateKey = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final events = _eventsByDate[selectedDateKey] ?? [];
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return Expanded(
      flex: 3,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isToday
                    ? [AppColors.lightContainerSecondary, AppColors.lightContainerSecondary.withAlpha(150)]
                    : [AppColors.lightContainerHighlight, AppColors.lightContainerHighlight.withAlpha(150)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(150),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _selectedDate.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppColors.primaryPink : AppColors.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isToday ? AppColors.primaryPink : AppColors.primaryPurple,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${events.length} ${events.length == 1 ? 'Event' : 'Events'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppColors.primaryPink : AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events scheduled',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add a new event',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final categoryColor = Color(EventConstants.getCategoryColor(event.category));
                      final isCancelled = event.status == EventConstants.statusCancelled;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final result = await context.push(EventDetailsPage(eventId: event.id));
                            if (result == true) {
                              _loadEvents();
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: categoryColor.withAlpha(100),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Category indicator
                                Container(
                                  width: double.infinity,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isCancelled ? Colors.grey : categoryColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Time column
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isCancelled ? Colors.grey.shade200 : categoryColor.withAlpha(30),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              event.isAllDay ? Icons.calendar_today : Icons.access_time,
                                              color: isCancelled ? Colors.grey : categoryColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (!event.isAllDay) ...[
                                            Text(
                                              DateFormat('h:mm').format(event.startDateTime),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isCancelled ? Colors.grey : Colors.grey.shade700,
                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('a').format(event.startDateTime),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                          ] else
                                            Text(
                                              'All day',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCancelled ? Colors.grey : Colors.grey.shade600,
                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      // Event details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    event.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: isCancelled ? Colors.grey : Colors.black,
                                                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                    ),
                                                  ),
                                                ),
                                                if (isCancelled)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withAlpha(30),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.red.shade300),
                                                    ),
                                                    child: const Text(
                                                      'Cancelled',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              event.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isCancelled ? Colors.grey : categoryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    event.location,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String day;

  const _WeekdayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    final isWeekend = day == 'Sun' || day == 'Sat';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isWeekend ? AppColors.lightContainerHighlight.withAlpha(150) : AppColors.lightContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(40),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          day,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isWeekend ? AppColors.primaryPurple : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final bool hasEvents;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.day,
    required this.hasEvents,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    // Check if this day is today
    final isToday = day == today.day && currentMonth == today.month && currentYear == today.year;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withAlpha(30)
              : isToday
                  ? AppColors.primaryPink.withAlpha(30)
                  : null,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : isToday
                    ? AppColors.primaryPink
                    : Colors.grey.shade300,
            width: isSelected || isToday ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
            Text(
              day.toString(),
              style: TextStyle(
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                color: isSelected
                    ? AppColors.primaryPurple
                    : isToday
                        ? AppColors.primaryPink
                        : null,
              ),
            ),

            // Event indicator
            if (hasEvents)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : isToday
                          ? AppColors.primaryPink
                          : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
