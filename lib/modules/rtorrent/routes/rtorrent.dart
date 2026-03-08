import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent.dart';
import 'package:lunasea/modules/rtorrent/widgets/torrent_tile.dart';
import 'package:file_picker/file_picker.dart';

class rTorrentPage extends StatefulWidget {
  final bool showDrawer;

  const rTorrentPage({
    super.key,
    this.showDrawer = true,
  });

  @override
  State<rTorrentPage> createState() => _RTorrentPageState();
}

class _RTorrentPageState extends State<rTorrentPage> with LunaScrollControllerMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _profileState = LunaProfile.current.toString();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchIfEnabled());
  }

  void _fetchIfEnabled() {
    if (LunaProfile.current.rtorrentEnabled) {
      context.read<RTorrentState>().fetchTorrents(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: _appBar() as PreferredSizeWidget?,
      body: _body(),
      drawer: widget.showDrawer ? LunaDrawer(page: LunaModule.RTORRENT.key) : null,
      floatingActionButton: LunaProfile.current.rtorrentEnabled ? _fab() : null,
      onProfileChange: (_) {
        if (_profileState != LunaProfile.current.toString()) {
          _profileState = LunaProfile.current.toString();
          context.read<RTorrentState>().reset();
          _fetchIfEnabled();
        }
      },
    );
  }

  Widget _appBar() {
    List<String> profiles = LunaBox.profiles.keys.fold([], (value, element) {
      if (LunaBox.profiles.read(element)?.rtorrentEnabled ?? false)
        value.add(element);
      return value;
    });
    return LunaAppBar.dropdown(
      title: LunaModule.RTORRENT.title,
      useDrawer: widget.showDrawer,
      hideLeading: !widget.showDrawer,
      profiles: profiles,
      actions: _actions(),
      scrollControllers: [scrollController],
    );
  }

  List<Widget> _actions() {
    return [
      LunaIconButton.appBar(
        icon: Icons.refresh_rounded,
        onPressed: () => context.read<RTorrentState>().fetchTorrents(silent: false),
      ),
      LunaIconButton.appBar(
        icon: Icons.filter_list_rounded,
        onPressed: _showFilterMenu,
      ),
      LunaIconButton.appBar(
        icon: Icons.sort_rounded,
        onPressed: _showSortMenu,
      ),
    ];
  }

  void _showSortMenu() {
    final state = context.read<RTorrentState>();
    LunaDialog.dialog(
      context: context,
      title: 'Sort Torrents',
      content: [
        _sortTile(state, 'Name', Icons.sort_by_alpha_rounded, RTorrentSort.name),
        _sortTile(state, 'Status', Icons.info_outline_rounded, RTorrentSort.status),
        _sortTile(state, 'Date Done', Icons.done_all_rounded, RTorrentSort.dateDone),
        _sortTile(state, 'Date Added', Icons.add_circle_outline_rounded, RTorrentSort.dateAdded),
        _sortTile(state, 'Percent Downloaded', Icons.percent_rounded, RTorrentSort.percentDownloaded),
        _sortTile(state, 'Download Speed', Icons.arrow_downward_rounded, RTorrentSort.downloadSpeed),
        _sortTile(state, 'Upload Speed', Icons.arrow_upward_rounded, RTorrentSort.uploadSpeed),
        _sortTile(state, 'Ratio', Icons.compare_arrows_rounded, RTorrentSort.ratio),
        _sortTile(state, 'Size', Icons.storage_rounded, RTorrentSort.size),
      ],
      contentPadding: LunaDialog.listDialogContentPadding(),
    );
  }

  Widget _sortTile(RTorrentState state, String text, IconData icon, RTorrentSort sortType) {
    return LunaDialog.tile(
      text: text,
      icon: icon,
      onTap: () {
        state.sort = sortType;
        Navigator.of(context).pop();
      },
      trailing: state.sort == sortType ? Icon(LunaIcons.CHECK_MARK) : null,
    );
  }

  void _showFilterMenu() {
    final state = context.read<RTorrentState>();
    LunaDialog.dialog(
      context: context,
      title: 'Filter Torrents',
      content: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text('Status', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        _statusFilterTile(state, 'All', RTorrentStatusFilter.all),
        _statusFilterTile(state, 'Downloading', RTorrentStatusFilter.downloading),
        _statusFilterTile(state, 'Seeding', RTorrentStatusFilter.seeding),
        _statusFilterTile(state, 'Active', RTorrentStatusFilter.active),
        _statusFilterTile(state, 'Inactive', RTorrentStatusFilter.inactive),
        if (state.uniqueLabels.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text('Labels', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          _labelFilterTile(state, 'All Labels', ''),
          for (final label in state.uniqueLabels)
            _labelFilterTile(state, label, label),
        ],
      ],
      contentPadding: LunaDialog.listDialogContentPadding(),
    );
  }

  Widget _statusFilterTile(RTorrentState state, String text, RTorrentStatusFilter filterType) {
    return LunaDialog.tile(
      text: text,
      icon: Icons.filter_alt_outlined,
      onTap: () {
        state.statusFilter = filterType;
        Navigator.of(context).pop();
      },
      trailing: state.statusFilter == filterType ? Icon(LunaIcons.CHECK_MARK) : null,
    );
  }

  Widget _labelFilterTile(RTorrentState state, String text, String labelType) {
    return LunaDialog.tile(
      text: text,
      icon: Icons.label_outline_rounded,
      onTap: () {
        state.labelFilter = labelType;
        Navigator.of(context).pop();
      },
      trailing: state.labelFilter == labelType ? Icon(LunaIcons.CHECK_MARK) : null,
    );
  }

  Widget _body() {
    if (!LunaProfile.current.rtorrentEnabled) {
      return LunaMessage.moduleNotEnabled(
        context: context,
        module: LunaModule.RTORRENT.title,
      );
    }

    final state = context.watch<RTorrentState>();

    if (state.fetching && state.torrents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error) {
      return LunaMessage(
        text: 'Error: ${state.errorMessage}',
        buttonText: 'lunasea.TryAgain'.tr(),
        onTap: () => state.fetchTorrents(silent: false),
      );
    }

    if (state.torrents.isEmpty) {
      return LunaMessage(
        text: 'No Torrents Found',
        buttonText: 'Refresh',
        onTap: () => state.fetchTorrents(silent: false),
      );
    }

    return RefreshIndicator(
      onRefresh: () => state.fetchTorrents(silent: true),
      child: LunaListView(
        controller: scrollController,
        children: state.torrents.map((t) => RTorrentTorrentTile(data: t)).toList(),
      ),
    );
  }

  Widget _fab() {
    return FloatingActionButton(
      child: const Icon(LunaIcons.ADD, color: Colors.white),
      backgroundColor: const Color(0xFF5AB444),
      onPressed: _addTorrent,
    );
  }

  Future<void> _addTorrent() async {
    final state = context.read<RTorrentState>();

    await LunaDialog.dialog(
      context: context,
      title: 'Add Torrent',
      content: [
        LunaDialog.tile(
          text: 'Add by URL',
          icon: Icons.link_rounded,
          onTap: () async {
            Navigator.of(context).pop();
            final values = await LunaDialogs().editText(
              context,
              'Add Torrent by URL',
              prefill: '',
            );
            if (values.item1) {
              if (await state.addTorrentByUrl(values.item2)) {
                showLunaSuccessSnackBar(title: 'Torrent Added', message: 'Successfully added torrent by URL');
              } else {
                showLunaErrorSnackBar(title: 'Failed to Add', message: 'Failed to add torrent by URL');
              }
            }
          },
        ),
        LunaDialog.tile(
          text: 'Upload File',
          icon: Icons.upload_file_rounded,
          onTap: () async {
            Navigator.of(context).pop();
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['torrent'],
              withData: true,
            );
            if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
              if (await state.addTorrentByFile(result.files.first.bytes!)) {
                showLunaSuccessSnackBar(title: 'Torrent Added', message: 'Successfully uploaded torrent file');
              } else {
                showLunaErrorSnackBar(title: 'Failed to Add', message: 'Failed to upload torrent file');
              }
            }
          },
        ),
      ],
      contentPadding: LunaDialog.listDialogContentPadding(),
    );
  }
}
