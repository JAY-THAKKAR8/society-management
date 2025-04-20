class AppStrings {
  static const List<MapEntry<String, String>> daysList = [
    MapEntry('Mon', 'MONDAY'),
    MapEntry('Tue', 'TUESDAY'),
    MapEntry('Wed', 'WEDNESDAY'),
    MapEntry('Thu', 'THURSDAY'),
    MapEntry('Fri', 'FRIDAY'),
    MapEntry('Sat', 'SATURDAY'),
    MapEntry('Sun', 'SUNDAY'),
  ];
  static List<int> monthList = List.generate(12, (index) => index + 1);
  static List<String> roleList = [
    'Admin',
    'Line head',
    'Line member',
  ];

  static List<String> lineList = [
    'First line',
    'Second line',
    'Third line',
    'Fourth line',
    'Fifth line',
  ];

  static const String tokenKey = 'TOKEN';

  // User Role
  static const String admin = 'ADMIN';
  static const String doctor = 'DOCTOR';
  static const String firstYear = 'FIRST_YEAR';
  static const String secondYear = 'SECOND_YEAR';
  static const String thirdYear = 'THIRD_YEAR';
  static const String fourthYear = 'FOURTH_YEAR';

  static const baseUrl = 'https://flexical.kodecreators.com/api';
  static const storageBaseUrl = 'https://flexical.kodecreators.com/storage/';

  static const v1 = '/v1';

  static const usersPath = '$baseUrl$v1/users';

  // user apis
  static const login = '$usersPath/login';
  static const forgotPassword = '$usersPath/forgot-password';
  static const detail = '$usersPath/detail';
  static const users = usersPath;
  static const createUser = '$usersPath/create';
  static const String editUser = '$usersPath/update';
  static const userDetails = '$usersPath/detail';
  static const changePassword = '$usersPath/change-password';
  static String deleteUser(String userId) => '$usersPath/$userId/delete';
  static const importUser = '$usersPath/import';
  static String importProjectUser(String projectId) => '$baseUrl$v1/projects/$projectId/import';
  static const downloadExcleFile = '$usersPath/excel-download';

  // google calendar apis
  static const String connectGoogleCalendar = '$baseUrl$v1/oauth/google-calender/connect';
  static const String disconnectGoogleCalendar = '$baseUrl$v1/oauth/google-calender/disconnect';

  // project apis
  static const projects = '$baseUrl$v1/projects';
  static const createProject = '$baseUrl$v1/projects/create';
  static String updateProject(String projectId) => '$baseUrl$v1/projects/$projectId/update';
  static String detailProject(String projectId) => '$baseUrl$v1/projects/$projectId/detail';
  static String deleteProject(String projectId) => '$baseUrl$v1/projects/$projectId/delete';
  static String deleteUserForThisProject(String projectId, String userId) =>
      '$baseUrl$v1/projects/$projectId/users/$userId/delete';
  static String projectPlanning(String projectId) => '$baseUrl$v1/projects/$projectId/planning';
  static String projectAvailability(String projectId) => '$baseUrl$v1/projects/$projectId/availabilities';
  static String updateProjectAvailability(String projectId) => '$baseUrl$v1/projects/$projectId/availabilities/update';
  static String rejectLeave(String projectId) => '$baseUrl$v1/projects/$projectId/reject-leave';
  static String calendarDateList(String projectId) => '$baseUrl$v1/projects/$projectId/calendars';
  static String getUserAvailability(String projectId) => '$baseUrl$v1/projects/$projectId/availabilities';
  static String updateUserProjectAvailability(String projectId) =>
      '$baseUrl$v1/projects/$projectId/availabilities/update';
  static String autoAssignShift(String projectId) => '$baseUrl$v1/projects/$projectId/auto-assign-shift';
  static String swapAvailabilityDate(String projectId) => '$baseUrl$v1/projects/$projectId/swap-availability';
  static String exportPdf(String projectId) => '$baseUrl$v1/projects/$projectId/downloadPDF';

  // holiday apis
  static const holidayCategories = '$baseUrl$v1/leave-categories';
  static const createHolidayCategory = '$baseUrl$v1/leave-categories/create';
  static String updateHolidayCategory(String id) => '$baseUrl$v1/leave-categories/$id/update';
  static String deleteHolidayCategory(String id) => '$baseUrl$v1/leave-categories/$id/delete';
}
