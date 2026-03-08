import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent.dart';
import 'package:lunasea/modules/rtorrent/routes/details.dart';

class RTorrentTorrentTile extends StatelessWidget {
  final RTorrentTorrentData data;

  const RTorrentTorrentTile({
    required this.data,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LunaBlock(
      title: data.name,
      body: [TextSpan(text: data.subtitle)],
      bottom: LunaLinearPercentIndicator(
        percent: data.percentageDone / 100,
        progressColor: _statusColor,
      ),
      onTap: () => _handleTap(context),
    );
  }

  Color get _statusColor {
    if (data.isError) return LunaColours.red;
    if (data.isSeeding) return LunaColours.accent; // Green
    if (data.isFinished) return LunaColours.blue;
    if (data.isDownloading) return LunaColours.accent; // Green
    if (data.isPaused) return LunaColours.orange;
    if (data.isStopped) return LunaColours.red;
    return LunaColours.red;
  }

  Future<void> _handleTap(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RTorrentDetailsPage(data: data),
      ),
    );
  }
}
