import 'package:lunasea/core.dart';

part 'metadata.g.dart';

@HiveType(typeId: 10, adapterName: 'LidarrMetadataProfileAdapter')
class LidarrMetadataProfile {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;

  LidarrMetadataProfile({
    this.id = -1,
    this.name = '',
  });
}
