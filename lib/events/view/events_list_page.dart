import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/events/service/event_service.dart';
import 'package:society_management/events/view/add_event_page.dart';
import 'package:society_management/events/view/events_calendar_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  final EventService _eventService = getIt<EventService>();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUser();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      // Log the user role and permission status for debugging
      if (user != null) {
        debugPrint('User role: ${user.role}');
        debugPrint('Can create events: ${_eventService.canUserCreateEvents(user)}');
      } else {
        debugPrint('No user logged in');
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonGradientAppBar(
        title: 'Society Events',
        gradientColors: AppColors.gradientPurplePink,
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : const EventsCalendarPage(),
      floatingActionButton: _currentUser != null &&
              (_currentUser!.role == AppConstants.admin ||
                  _currentUser!.role == AppConstants.lineLead ||
                  _currentUser!.role == AppConstants.lineHeadAndMember) &&
              _eventService.canUserCreateEvents(_currentUser!)
          ? FloatingActionButton(
              onPressed: () async {
                final result = await context.push(AddEventPage(currentUser: _currentUser!));
                if (result == true) {
                  // Refresh the calendar by rebuilding the page
                  setState(() {});
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
