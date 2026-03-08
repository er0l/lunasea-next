import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent.dart';
import 'package:lunasea/router/routes/settings.dart';

class ConfigurationRTorrentRoute extends StatefulWidget {
  const ConfigurationRTorrentRoute({
    Key? key,
  }) : super(key: key);

  @override
  State<ConfigurationRTorrentRoute> createState() => _State();
}

class _State extends State<ConfigurationRTorrentRoute>
    with LunaScrollControllerMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: _appBar(),
      body: _body(),
    );
  }

  PreferredSizeWidget _appBar() {
    return LunaAppBar(
      title: LunaModule.RTORRENT.title,
      scrollControllers: [scrollController],
    );
  }

  Widget _body() {
    return LunaListView(
      controller: scrollController,
      children: [
        LunaModule.RTORRENT.informationBanner(),
        _enabledToggle(),
        _connectionDetailsPage(),
      ],
    );
  }

  Widget _enabledToggle() {
    return LunaBox.profiles.listenableBuilder(
      builder: (context, _) => LunaBlock(
        title: 'settings.EnableModule'.tr(args: [LunaModule.RTORRENT.title]),
        trailing: LunaSwitch(
          value: LunaProfile.current.rtorrentEnabled,
          onChanged: (value) {
            LunaProfile.current.rtorrentEnabled = value;
            LunaProfile.current.save();
            context.read<RTorrentState>().reset();
          },
        ),
      ),
    );
  }

  Widget _connectionDetailsPage() {
    return LunaBlock(
      title: 'settings.ConnectionDetails'.tr(),
      body: [
        TextSpan(
          text: 'settings.ConnectionDetailsDescription'.tr(
            args: [LunaModule.RTORRENT.title],
          ),
        )
      ],
      trailing: const LunaIconButton.arrow(),
      onTap: SettingsRoutes.CONFIGURATION_RTORRENT_CONNECTION_DETAILS.go,
    );
  }
}
