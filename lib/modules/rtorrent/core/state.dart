import 'dart:typed_data';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent/core/api/api.dart';
import 'package:lunasea/modules/rtorrent/core/api/data.dart';

enum RTorrentSort {
  name,
  status,
  size,
  dateDone,
  dateAdded,
  percentDownloaded,
  downloadSpeed,
  uploadSpeed,
  ratio,
}

enum RTorrentStatusFilter {
  all,
  downloading,
  seeding,
  active,
  inactive,
}

class RTorrentState extends LunaModuleState {
  List<RTorrentTorrentData> _torrents = [];
  RTorrentSort _sort = RTorrentSort.name;
  RTorrentStatusFilter _statusFilter = RTorrentStatusFilter.all;
  String _labelFilter = '';
  
  bool _fetching = false;
  bool _error = false;
  String _errorMessage = '';

  RTorrentState() {
    reset();
  }

  @override
  void reset() {
    _navigationIndex = 0;
    _torrents = [];
    _sort = RTorrentSort.name;
    _statusFilter = RTorrentStatusFilter.all;
    _labelFilter = '';
    _fetching = false;
    _error = false;
    _errorMessage = '';
    notifyListeners();
  }

  List<RTorrentTorrentData> get torrents {
    List<RTorrentTorrentData> filtered = List.from(_torrents);
    
    // Apply Status Filter
    switch (_statusFilter) {
      case RTorrentStatusFilter.downloading:
        filtered = filtered.where((t) => t.isDownloading).toList();
        break;
      case RTorrentStatusFilter.seeding:
        filtered = filtered.where((t) => t.isSeeding).toList();
        break;
      case RTorrentStatusFilter.active:
        filtered = filtered.where((t) => t.isActive).toList();
        break;
      case RTorrentStatusFilter.inactive:
        filtered = filtered.where((t) => !t.isActive).toList();
        break;
      case RTorrentStatusFilter.all:
      default:
        break;
    }

    // Apply Label Filter
    if (_labelFilter.isNotEmpty) {
      filtered = filtered.where((t) => t.label == _labelFilter).toList();
    }

    // Apply Sorting
    switch (_sort) {
      case RTorrentSort.name:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case RTorrentSort.status:
        filtered.sort((a, b) => a.status.compareTo(b.status));
        break;
      case RTorrentSort.size:
        filtered.sort((a, b) => b.size.compareTo(a.size));
        break;
      case RTorrentSort.dateDone:
        filtered.sort((a, b) => b.dateDone.compareTo(a.dateDone));
        break;
      case RTorrentSort.dateAdded:
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case RTorrentSort.percentDownloaded:
        filtered.sort((a, b) => b.percentageDone.compareTo(a.percentageDone));
        break;
      case RTorrentSort.downloadSpeed:
        filtered.sort((a, b) => b.downRate.compareTo(a.downRate));
        break;
      case RTorrentSort.uploadSpeed:
        filtered.sort((a, b) => b.upRate.compareTo(a.upRate));
        break;
      case RTorrentSort.ratio:
        filtered.sort((a, b) => b.ratio.compareTo(a.ratio));
        break;
    }
    return filtered;
  }

  List<String> get uniqueLabels {
    final labels = _torrents.map((t) => t.label).where((label) => label.isNotEmpty).toSet().toList();
    labels.sort();
    return labels;
  }

  RTorrentSort get sort => _sort;
  set sort(RTorrentSort value) {
    _sort = value;
    notifyListeners();
  }
  
  RTorrentStatusFilter get statusFilter => _statusFilter;
  set statusFilter(RTorrentStatusFilter value) {
    _statusFilter = value;
    notifyListeners();
  }

  String get labelFilter => _labelFilter;
  set labelFilter(String value) {
    _labelFilter = value;
    notifyListeners();
  }
  bool get fetching => _fetching;
  bool get error => _error;
  String get errorMessage => _errorMessage;

  Future<void> fetchTorrents({bool silent = false}) async {
    if (!silent) {
      _fetching = true;
      _error = false;
      notifyListeners();
    }

    try {
      final api = RTorrentAPI.from(LunaProfile.current);
      _torrents = await api.getTorrents();
      _error = false;
      _errorMessage = '';
    } catch (e) {
      _error = true;
      _errorMessage = e.toString();
      LunaLogger().error('RTorrentState: Failed to fetch torrents', e, StackTrace.current);
    } finally {
      _fetching = false;
      notifyListeners();
    }
  }

  Future<bool> pauseTorrent(String hash) async {
    final api = RTorrentAPI.from(LunaProfile.current);
    if (await api.pauseTorrent(hash)) {
      await fetchTorrents(silent: true);
      return true;
    }
    return false;
  }

  Future<bool> stopTorrent(String hash) async {
    final api = RTorrentAPI.from(LunaProfile.current);
    if (await api.stopTorrent(hash)) {
      await fetchTorrents(silent: true);
      return true;
    }
    return false;
  }

  Future<bool> resumeTorrent(String hash) async {
    final api = RTorrentAPI.from(LunaProfile.current);
    if (await api.resumeTorrent(hash)) {
      await fetchTorrents(silent: true);
      return true;
    }
    return false;
  }

  Future<bool> removeTorrent(String hash, {bool deleteData = false}) async {
    final api = RTorrentAPI.from(LunaProfile.current);
    if (await api.removeTorrent(hash, deleteData: deleteData)) {
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchTorrents(silent: true);
      return true;
    }
    return false;
  }

  Future<bool> addTorrentByUrl(String url) async {
    final api = RTorrentAPI.from(LunaProfile.current);
    if (await api.addTorrentByUrl(url)) {
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchTorrents(silent: true);
      return true;
    }
    return false;
  }

  Future<bool> addTorrentByFile(Uint8List bytes) async {
    final api = RTorrentAPI.from(LunaProfile.current);
    if (await api.addTorrentByFile(bytes)) {
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchTorrents(silent: true);
      return true;
    }
    return false;
  }

  int _navigationIndex = 0;
  int get navigationIndex => _navigationIndex;
  set navigationIndex(int index) {
    _navigationIndex = index;
    notifyListeners();
  }
}
