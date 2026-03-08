import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/settings.dart';

class OverseerrConnectionDetailsPage extends StatefulWidget {
  const OverseerrConnectionDetailsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<OverseerrConnectionDetailsPage> createState() => _State();
}

class _State extends State<OverseerrConnectionDetailsPage>
    with LunaScrollControllerMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
          _key(),
        ],
      ),
    );
  }

  Widget _host() {
    String host = LunaProfile.current.overseerrHost;
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
          LunaProfile.current.overseerrHost = _values.item2;
          LunaProfile.current.save();
          _showSavedSnackbar();
        }
      },
    );
  }

  Widget _key() {
    String key = LunaProfile.current.overseerrKey;
    return LunaBlock(
      title: 'settings.APIKey'.tr(),
      body: [
        TextSpan(
          text: key.isEmpty
              ? 'lunasea.NotSet'.tr()
              : LunaUI.TEXT_OBFUSCATED_PASSWORD,
        ),
      ],
      trailing: const LunaIconButton.arrow(),
      onTap: () async {
        Tuple2<bool, String> _values = await LunaDialogs().editPassword(
          context,
          'settings.APIKey'.tr(),
          prefill: key,
        );
        if (_values.item1) {
          LunaProfile.current.overseerrKey = _values.item2;
          LunaProfile.current.save();
          _showSavedSnackbar();
        }
      },
    );
  }

  void _showSavedSnackbar() {
    showLunaSnackBar(
      title: 'settings.ProfileSaved'.tr(),
      message: 'settings.ProfileSavedDescription'.tr(),
      type: LunaSnackbarType.SUCCESS,
    );
  }
}
