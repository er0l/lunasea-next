import 'package:lunasea/core.dart';

part 'rootfolder.g.dart';

@HiveType(typeId: 8, adapterName: 'LidarrRootFolderAdapter')
class LidarrRootFolder {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String path;
  @HiveField(2)
  final int freeSpace;

  LidarrRootFolder({
    this.id = -1,
    this.path = '',
    this.freeSpace = 0,
  });

  factory LidarrRootFolder.empty() => LidarrRootFolder();
}
