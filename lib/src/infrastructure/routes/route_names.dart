import 'route_paths.dart';

class RouteNames {
  static const String splash = RoutePaths.splash;
  static const String login = RoutePaths.login;
  static const String register = '${RoutePaths.login}${RoutePaths.register}';
  static const String missions = RoutePaths.missions;
  static const String addMissions =
      '${RoutePaths.missions}${RoutePaths.addMissions}';
  static const String editMissions =
      '${RoutePaths.missions}${RoutePaths.editMissions}';
  static const String missionDetails =
      '${RoutePaths.missions}${RoutePaths.missionDetails}';
  static const String home = RoutePaths.home;
  static const String profile = RoutePaths.profile;
  static const String myEvents = RoutePaths.myEvents;
  static const String addEvents =
      '${RoutePaths.myEvents}${RoutePaths.addEvents}';
  static const String editEvents =
      '${RoutePaths.myEvents}${RoutePaths.editEvents}';
  static const String detailsEvent =
      '${RoutePaths.missions}${RoutePaths.detailsEvent}';
  static const String bookmark = RoutePaths.bookmark;
}


