import 'package:flutter/material.dart';
import 'package:lunasea/modules.dart';
import 'package:lunasea/modules/rtorrent/routes/rtorrent.dart';
import 'package:lunasea/router/routes.dart';
import 'package:lunasea/vendor.dart';

enum rTorrentRoutes with LunaRoutesMixin {
  HOME('home');

  final String name;
  const rTorrentRoutes(this.name);

  @override
  LunaModule get module => LunaModule.RTORRENT;

  @override
  String get path => '/rtorrent/$name';

  @override
  GoRoute get routes => route(widget: const rTorrentPage());

  @override
  bool isModuleEnabled(BuildContext context) => LunaModule.RTORRENT.isEnabled;
}
