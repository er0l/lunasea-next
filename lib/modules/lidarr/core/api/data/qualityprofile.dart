import 'package:lunasea/core.dart';

part 'qualityprofile.g.dart';

@HiveType(typeId: 9, adapterName: 'LidarrQualityProfileAdapter')
class LidarrQualityProfile {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;

  LidarrQualityProfile({
    this.id = -1,
    this.name = '',
  });
}
