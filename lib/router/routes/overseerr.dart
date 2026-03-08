import 'package:lunasea/core.dart';
import 'package:lunasea/modules/overseerr/routes.dart';

class OverseerrRoutesRouter {
  OverseerrRoutesRouter._();

  static List<GoRoute> get routes => [
    OverseerrRoutes.HOME.routes,
    OverseerrRoutes.SEARCH.routes,
  ];
}
