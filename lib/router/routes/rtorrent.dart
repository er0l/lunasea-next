import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent/routes.dart';

class rTorrentRoutesRouter {
  rTorrentRoutesRouter._();

  static List<GoRoute> get routes => [
    rTorrentRoutes.HOME.routes,
  ];
}
