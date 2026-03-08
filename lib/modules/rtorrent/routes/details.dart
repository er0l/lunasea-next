import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent.dart';
import 'package:lunasea/modules/rtorrent/core/api/api.dart';
import 'package:lunasea/extensions/int/bytes.dart';

class RTorrentDetailsPage extends StatefulWidget {
  final RTorrentTorrentData data;

  const RTorrentDetailsPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<RTorrentDetailsPage> createState() => _RTorrentDetailsPageState();
}

class _RTorrentDetailsPageState extends State<RTorrentDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _fetchingExtraInfo = true;
  List<RTorrentTrackerData> _trackers = [];
  List<RTorrentFileData> _files = [];
  
  late RTorrentTorrentData _currentData; // Keep a local reference in case we refresh from state later.

  @override
  void initState() {
    super.initState();
    _currentData = widget.data;
    _tabController = TabController(length: 3, vsync: this);
    _fetchExtraInfo();
  }

  Future<void> _fetchExtraInfo() async {
    final api = RTorrentAPI.from(LunaProfile.current);
    try {
      final trackers = await api.getTrackers(_currentData.hash);
      final files = await api.getFiles(_currentData.hash);
      if (mounted) {
        setState(() {
          _trackers = trackers;
          _files = files;
          _fetchingExtraInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fetchingExtraInfo = false);
      }
      LunaLogger().warning('rTorrent Details: Failed to fetch extra info: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optionally grab the latest data from the state if you want real-time updates while page is open
    final state = context.watch<RTorrentState>();
    final updatedData = state.torrents.where((t) => t.hash == _currentData.hash).firstOrNull;
    if (updatedData != null) _currentData = updatedData;

    return Scaffold(
      appBar: LunaAppBar(
        title: _currentData.name,
      ) as PreferredSizeWidget?,
      body: Column(
        children: [
          _buildInfoCard(),
          _buildActionRow(state),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Trackers'),
              Tab(text: 'Files'),
            ],
            indicatorColor: LunaColours.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildTrackersTab(),
                _buildFilesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            _currentData.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _currentData.status,
            style: TextStyle(
              color: _currentData.isError
                  ? LunaColours.red
                  : (_currentData.isSeeding || _currentData.isDownloading)
                      ? LunaColours.accent
                      : (_currentData.isFinished ? LunaColours.blue : LunaColours.orange),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LunaLinearPercentIndicator(
            percent: _currentData.percentageDone / 100,
            progressColor: (_currentData.isSeeding || _currentData.isDownloading) ? LunaColours.accent : LunaColours.blue,
          ),
          const SizedBox(height: 8),
          Text(
            _currentData.subtitle,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(RTorrentState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12.0,
        children: [
          if (_currentData.isPaused || _currentData.isStopped)
            _buildActionButton(Icons.play_arrow, 'Resume', () async {
              if (await state.resumeTorrent(_currentData.hash)) {
                showLunaSuccessSnackBar(title: 'Resumed', message: 'Torrent resumed');
              } else {
                showLunaErrorSnackBar(title: 'Error', message: 'Failed to resume');
              }
            }),
          if (_currentData.isDownloading || _currentData.isSeeding)
            _buildActionButton(Icons.pause, 'Pause', () async {
              if (await state.pauseTorrent(_currentData.hash)) {
                showLunaSuccessSnackBar(title: 'Paused', message: 'Torrent paused');
              } else {
                showLunaErrorSnackBar(title: 'Error', message: 'Failed to pause');
              }
            }),
          if (!_currentData.isStopped)
            _buildActionButton(Icons.stop, 'Stop', () async {
              if (await state.stopTorrent(_currentData.hash)) {
                showLunaSuccessSnackBar(title: 'Stopped', message: 'Torrent stopped');
              } else {
                showLunaErrorSnackBar(title: 'Error', message: 'Failed to stop');
              }
            }),
          _buildActionButton(Icons.sync, 'Check', () async {
            final api = RTorrentAPI.from(LunaProfile.current);
            if (await api.checkTorrent(_currentData.hash)) {
              showLunaSuccessSnackBar(title: 'Checking', message: 'Forcing recheck');
              state.fetchTorrents(silent: true);
            } else {
              showLunaErrorSnackBar(title: 'Error', message: 'Failed to force check');
            }
          }),
          _buildActionButton(Icons.label, 'Label', () async {
            final values = await LunaDialogs().editText(
              context,
              'Set Label',
              prefill: _currentData.label,
            );
            if (values.item1) {
              final api = RTorrentAPI.from(LunaProfile.current);
              if (await api.setLabel(_currentData.hash, values.item2)) {
                showLunaSuccessSnackBar(title: 'Label Set', message: 'Torrent label updated');
                state.fetchTorrents(silent: true);
              } else {
                showLunaErrorSnackBar(title: 'Error', message: 'Failed to update label');
              }
            }
          }),
          _buildActionButton(Icons.delete, 'Delete', () => _promptDelete(state), color: LunaColours.red),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color ?? Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _promptDelete(RTorrentState state) async {
    bool _deleteData = false;
    bool? confirm = await LunaDialog.dialog<bool>(
      context: context,
      title: 'Remove Torrent',
      customContent: StatefulBuilder(
        builder: (context, setStateBuilder) => LunaDialog.content(
          children: [
            LunaDialog.textContent(text: 'Are you sure you want to remove this torrent?'),
            const SizedBox(height: 12.0),
            LunaDialog.checkbox(
              title: 'Also delete data',
              value: _deleteData,
              onChanged: (value) => setStateBuilder(() => _deleteData = value ?? false),
            ),
          ],
        ),
      ),
      buttons: [
        LunaDialog.button(
          text: 'Remove',
          textColor: LunaColours.red,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      contentPadding: LunaDialog.textDialogContentPadding(),
    ) as bool?;

    if (confirm == true) {
      if (await state.removeTorrent(_currentData.hash, deleteData: _deleteData)) {
        showLunaSuccessSnackBar(title: 'Removed', message: 'Torrent has been removed');
        if (mounted) Navigator.of(context).pop(); // Go back to list
      } else {
        showLunaErrorSnackBar(title: 'Error', message: 'Failed to remove torrent');
      }
    }
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _detailRow('Date Added', _formatTimestamp(_currentData.dateAdded)),
        _detailRow('Date Completed', _formatTimestamp(_currentData.dateDone)),
        _detailRow('Ratio', _currentData.ratio.toStringAsFixed(2)),
        _detailRow('Total Size', _currentData.size.asBytes()),
        _detailRow('Completed', _currentData.completed.asBytes()),
        _detailRow('Download Speed', '${_currentData.downRate.asBytes()}/s'),
        _detailRow('Upload Speed', '${_currentData.upRate.asBytes()}/s'),
        _detailRow('Label', _currentData.label.isNotEmpty ? _currentData.label : 'None'),
      ],
    );
  }

  String _formatTimestamp(int ts) {
    if (ts <= 0) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrackersTab() {
    if (_fetchingExtraInfo) return const Center(child: CircularProgressIndicator());
    if (_trackers.isEmpty) return const Center(child: Text('No trackers found'));

    return ListView.builder(
      itemCount: _trackers.length,
      itemBuilder: (context, index) {
        final t = _trackers[index];
        return ListTile(
          title: Text(t.url, style: const TextStyle(fontSize: 14)),
          subtitle: Text('Type: ${t.type}', style: const TextStyle(color: Colors.white54)),
        );
      },
    );
  }

  Widget _buildFilesTab() {
    if (_fetchingExtraInfo) return const Center(child: CircularProgressIndicator());
    if (_files.isEmpty) return const Center(child: Text('No files found'));

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final f = _files[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.path, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${f.completedBytes.asBytes()} / ${f.size.asBytes()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${f.percentageDone}%', style: TextStyle(color: f.isCompleted ? LunaColours.accent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              LunaLinearPercentIndicator(
                percent: f.percentageDone / 100,
                progressColor: f.isCompleted ? LunaColours.accent : LunaColours.blue,
              ),
              const Divider(color: Colors.white12),
            ],
          ),
        );
      },
    );
  }
}
