class UrlRepository {
  UrlRepository._();

  static const String _baseUrl = 'localhost:3000';
  static const String _users = '/users';
  static const String _missions = '/missions';
  static const String _category = '/category';
  static const String _proposals = '/proposals';
  static const String _events = '/missions';
  static const String _details = '/details';

  
  static String get _baseWithScheme => 'http://$_baseUrl';

  static Uri login(String username, String password) {
    return Uri.parse('$_baseWithScheme$_users');
  }

  static Uri register = Uri.parse('$_baseWithScheme$_users');

  static Uri users = Uri.parse('$_baseWithScheme$_users');

  static Uri userByUsername({required String username}) {
    return Uri.parse('$_baseWithScheme$_users?username=$username');
  }

  static Uri searchEvent({String? title, String? parameters}) {
    if (title == null && parameters == null) {
      return Uri.parse('$_baseWithScheme$_events');
    }
    return Uri.parse('$_baseWithScheme$_events/?title_like=$title${parameters ?? ''}');
  }

  static Uri events = Uri.parse('$_baseWithScheme$_events');

  static Uri missions = Uri.parse('$_baseWithScheme$_missions');

  static Uri category = Uri.parse('$_baseWithScheme$_category');

  static Uri proposals = Uri.parse('$_baseWithScheme$_proposals');

  static Uri getMissionById({required String missionId}) {
    return Uri.parse('$_baseWithScheme$_missions/$missionId');
  }
  static Uri getProposalById({required String proposalId}) {
    return Uri.parse('$_baseWithScheme$_proposals/$proposalId');
  }

  static Uri getBidsForHunterId({required String hunterId}) {
    return Uri.parse('$_baseWithScheme$_proposals?hunterId=$hunterId&_expand=mission');
  }

  static Uri getBidsForMissionId({required String missionId}) {
    return Uri.parse('$_baseWithScheme$_proposals?missionId=$missionId');
  }

  static Uri selectHunter(
      {required String missionId, required String hunterId}) {
    return Uri.parse('$_baseWithScheme$_missions/$missionId/select-hunter/$hunterId');
  }

  static Uri submitBid({required String missionId}) {
    return Uri.parse('$_baseWithScheme$_missions/$missionId/bid');
  }

  static Uri getEventsByParameters({required String queryParameters}) {
    return Uri.parse('$_baseWithScheme$_events');
  }

  static Uri getEventById({required String eventId}) {
    return Uri.parse('$_baseWithScheme$_events/$eventId');
  }

  static Uri getUserById({required String userId}) {
    return Uri.parse('$_baseWithScheme$_users/$userId');
  }

  static Uri getBookmarkedEvents({required int userId}) {
    return Uri.parse('$_baseWithScheme$_users/{$userId}/bookmark');
  }

  static Uri updateBookmark({required int userId}) {
    return Uri.parse('$_baseWithScheme$_users/bookmark');
  }

  static Uri myEvents(int userId) {
    return Uri.parse('$_baseWithScheme$_events/$userId');
  }

  static Uri getEventsByUserId({required int userId}) {
    return Uri.parse('$_baseWithScheme$_events?userId=$userId');
  }

  static Uri details = Uri.parse('$_baseWithScheme$_details');

  static Uri eventsById({required int eventId}) {
    return Uri.parse('$_baseWithScheme$_events/$eventId');
  }

  static Uri getMyEvents({required int creatorId}) {
    return Uri.parse('$_baseWithScheme$_events/?creatorId=$creatorId');
  }

  static Uri deleteEventById({required int eventId}) {
    return Uri.parse('http://$_baseUrl$_events/$eventId');
  }

  static Uri deleteEventById22({required int eventId}) =>
      Uri.parse('$_baseWithScheme$_events');

}


