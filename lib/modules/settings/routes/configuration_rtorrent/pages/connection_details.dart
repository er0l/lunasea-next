import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent.dart';
import 'package:lunasea/modules/settings.dart';

class ConfigurationRTorrentConnectionDetailsRoute extends StatefulWidget {
  const ConfigurationRTorrentConnectionDetailsRoute({
    Key? key,
  }) : super(key: key);

  @override
  State<ConfigurationRTorrentConnectionDetailsRoute> createState() => _State();
}

class _State extends State<ConfigurationRTorrentConnectionDetailsRoute>
    with LunaScrollControllerMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: _appBar() as PreferredSizeWidget?,
      body: _body(),
    );
  }

  Widget _appBar() {
    return LunaAppBar(
      title: 'settings.ConnectionDetails'.tr(),
      scrollControllers: [scrollController],
    );
  }

  Widget _body() {
    return LunaBox.profiles.listenableBuilder(
      builder: (context, _) => LunaListView(
        controller: scrollController,
        children: [
          _host(),
          _username(),
          _password(),
        ],
      ),
    );
  }

  Widget _host() {
    String host = LunaProfile.current.rtorrentHost;
    return LunaBlock(
      title: 'settings.Host'.tr(),
      body: [TextSpan(text: host.isEmpty ? 'lunasea.NotSet'.tr() : host)],
      trailing: const LunaIconButton.arrow(),
      onTap: () async {
        Tuple2<bool, String> _values = await SettingsDialogs().editHost(
          context,
          prefill: host,
        );
        if (_values.item1) {
          LunaProfile.current.rtorrentHost = _values.item2;
          LunaProfile.current.save();
          context.read<RTorrentState>().reset();
        }
      },
    );
  }

  Widget _username() {
    String username = LunaProfile.current.rtorrentUsername;
    return LunaBlock(
      title: 'settings.Username'.tr(),
      body: [TextSpan(text: username.isEmpty ? 'lunasea.NotSet'.tr() : username)],
      trailing: const LunaIconButton.arrow(),
      onTap: () async {
        Tuple2<bool, String> _values = await LunaDialogs().editText(
          context,
          'settings.Username'.tr(),
          prefill: username,
        );
        if (_values.item1) {
          LunaProfile.current.rtorrentUsername = _values.item2;
          LunaProfile.current.save();
          context.read<RTorrentState>().reset();
        }
      },
    );
  }

  Widget _password() {
    String password = LunaProfile.current.rtorrentPassword;
    return LunaBlock(
      title: 'settings.Password'.tr(),
      body: [
        TextSpan(
          text: password.isEmpty
              ? 'lunasea.NotSet'.tr()
              : LunaUI.TEXT_OBFUSCATED_PASSWORD,
        ),
      ],
      trailing: const LunaIconButton.arrow(),
      onTap: () async {
        Tuple2<bool, String> _values = await LunaDialogs().editPassword(
          context,
          'settings.Password'.tr(),
          prefill: password,
        );
        if (_values.item1) {
          LunaProfile.current.rtorrentPassword = _values.item2;
          LunaProfile.current.save();
          context.read<RTorrentState>().reset();
        }
      },
    );
  }
}
