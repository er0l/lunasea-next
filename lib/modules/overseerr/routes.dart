import 'package:flutter/material.dart';
import 'package:lunasea/modules.dart';
import 'package:lunasea/modules/overseerr/routes/overseerr.dart';
import 'package:lunasea/modules/overseerr/routes/search.dart';
import 'package:lunasea/router/routes.dart';
import 'package:lunasea/vendor.dart';

enum OverseerrRoutes with LunaRoutesMixin {
  HOME('/overseerr'),
  SEARCH('search');

  @override
  final String path;
  const OverseerrRoutes(this.path);

  @override
  LunaModule get module => LunaModule.OVERSEERR;

  @override
  GoRoute get routes {
    switch (this) {
      case OverseerrRoutes.HOME:
        return route(widget: const OverseerrPage());
      case OverseerrRoutes.SEARCH:
        return route(widget: const OverseerrSearchPage());
    }
  }

  @override
  List<GoRoute> get subroutes {
    switch (this) {
      case OverseerrRoutes.HOME:
        return [
          OverseerrRoutes.SEARCH.routes,
        ];
      default:
        return const [];
    }
  }

  @override
  bool isModuleEnabled(BuildContext context) => LunaModule.OVERSEERR.isEnabled;
}
