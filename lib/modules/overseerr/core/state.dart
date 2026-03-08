import 'package:lunasea/core.dart';
import 'package:lunasea/modules/overseerr/core/api.dart';
import 'package:lunasea/modules/overseerr/core/models/media_request.dart';
import 'package:lunasea/modules/overseerr/core/models/search_result.dart';

class OverseerrState extends LunaModuleState {
  List<OverseerrMediaRequest> _requests = [];
  List<OverseerrSearchResult> _searchResults = [];
  bool _fetching = false;
  bool _searching = false;
  bool _error = false;
  String _errorMessage = '';

  OverseerrState() {
    reset();
  }

  @override
  void reset() {
    _navigationIndex = 0;
    _requests = [];
    _searchResults = [];
    _fetching = false;
    _searching = false;
    _error = false;
    _errorMessage = '';
    notifyListeners();
  }

  List<OverseerrMediaRequest> get requests => _requests;
  List<OverseerrSearchResult> get searchResults => _searchResults;
  bool get fetching => _fetching;
  bool get searching => _searching;
  bool get error => _error;
  String get errorMessage => _errorMessage;

  Future<void> fetchRequests({bool silent = false}) async {
    if (!silent) {
      _fetching = true;
      _error = false;
      notifyListeners();
    }

    try {
      final api = OverseerrAPI.from(LunaProfile.current);
      _requests = await api.getRequests();
      _error = false;
      _errorMessage = '';
    } catch (e) {
      _error = true;
      _errorMessage = e.toString();
      LunaLogger().error('OverseerrState: Failed to fetch requests', e, StackTrace.current);
    } finally {
      _fetching = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _searching = true;
    _error = false;
    notifyListeners();

    try {
      final api = OverseerrAPI.from(LunaProfile.current);
      _searchResults = await api.search(query);
      _error = false;
      _errorMessage = '';
    } catch (e) {
      _error = true;
      _errorMessage = e.toString();
      LunaLogger().error('OverseerrState: Failed to search', e, StackTrace.current);
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<bool> requestMedia({
    required int tmdbId,
    required String mediaType,
    bool is4k = false,
  }) async {
    try {
      final api = OverseerrAPI.from(LunaProfile.current);
      if (await api.requestMedia(
        tmdbId: tmdbId,
        mediaType: mediaType,
        is4k: is4k ? 1 : 0,
      )) {
        await fetchRequests(silent: true);
        return true;
      }
      return false;
    } catch (e) {
      LunaLogger().error('OverseerrState: Failed to request media', e, StackTrace.current);
      return false;
    }
  }

  int _navigationIndex = 0;
  int get navigationIndex => _navigationIndex;
  set navigationIndex(int index) {
    _navigationIndex = index;
    notifyListeners();
  }
}
