import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/events/constants/event_constants.dart';
import 'package:society_management/events/service/event_service.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';
import 'package:society_management/widget/gradient_button.dart';

class AddEventPage extends StatefulWidget {
  final UserModel currentUser;

  const AddEventPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final EventService _eventService = getIt<EventService>();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 2)),
  );

  String _selectedCategory = EventConstants.categoryGeneral;
  bool _isAllDay = false;
  bool _isRecurring = false;
  String _recurringPattern = EventConstants.recurringMonthly;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _startDate) {
      setState(() {
        _startDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _startTime.hour,
          _startTime.minute,
        );

        // If end date is before start date, update it
        if (_endDate.isBefore(_startDate)) {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _endTime.hour,
            _endTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _endDate) {
      setState(() {
        _endDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _endTime.hour,
          _endTime.minute,
        );
      });
    }
  }

  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // If end time is before start time on the same day, update it
        if (_endDate.year == _startDate.year &&
            _endDate.month == _startDate.month &&
            _endDate.day == _startDate.day &&
            (_endTime.hour < _startTime.hour ||
                (_endTime.hour == _startTime.hour && _endTime.minute < _startTime.minute))) {
          _endTime = TimeOfDay.fromDateTime(_startDate.add(const Duration(hours: 1)));
          _endDate = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            _endTime.hour,
            _endTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (pickedTime != null && pickedTime != _endTime) {
      setState(() {
        _endTime = pickedTime;
        _endDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create start and end DateTimes
      final startDateTime = _isAllDay ? DateTime(_startDate.year, _startDate.month, _startDate.day) : _startDate;

      final endDateTime = _isAllDay ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59) : _endDate;

      final result = await _eventService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: _locationController.text.trim(),
        category: _selectedCategory,
        creator: widget.currentUser,
        lineNumber: widget.currentUser.lineNumber,
        isAllDay: _isAllDay,
        isRecurring: _isRecurring,
        recurringPattern: _isRecurring ? _recurringPattern : null,
      );

      result.fold(
        (failure) {
          Utility.toast(message: 'Failed to create event: ${failure.message}');
          setState(() {
            _isLoading = false;
          });
        },
        (event) {
          Utility.toast(message: 'Event created successfully!');
          Navigator.pop(context, true);
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error creating event: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonGradientAppBar(
        title: 'Create New Event',
        gradientColors: AppColors.gradientPurplePink,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event description';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event location';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: EventConstants.allCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const Gap(16),

                    // All Day Switch
                    SwitchListTile(
                      title: const Text('All Day Event'),
                      value: _isAllDay,
                      onChanged: (value) {
                        setState(() {
                          _isAllDay = value;
                        });
                      },
                      secondary: const Icon(Icons.access_time),
                    ),
                    const Divider(),

                    // Start Date & Time
                    const Text(
                      'Start Date & Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('EEE, MMM d, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        if (!_isAllDay) ...[
                          const Gap(8),
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _startTime.format(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(16),

                    // End Date & Time
                    const Text(
                      'End Date & Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('EEE, MMM d, yyyy').format(_endDate),
                              ),
                            ),
                          ),
                        ),
                        if (!_isAllDay) ...[
                          const Gap(8),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _endTime.format(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(16),

                    // Recurring Event
                    SwitchListTile(
                      title: const Text('Recurring Event'),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                      secondary: const Icon(Icons.repeat),
                    ),

                    if (_isRecurring) ...[
                      const Gap(8),
                      DropdownButtonFormField<String>(
                        value: _recurringPattern,
                        decoration: const InputDecoration(
                          labelText: 'Recurring Pattern',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: EventConstants.allRecurringPatterns.map((pattern) {
                          return DropdownMenuItem<String>(
                            value: pattern,
                            child: Text(pattern.substring(0, 1).toUpperCase() + pattern.substring(1)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _recurringPattern = value;
                            });
                          }
                        },
                      ),
                    ],

                    const Gap(24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: _createEvent,
                        text: 'Create Event',
                        gradientColors: AppColors.gradientPurplePink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
