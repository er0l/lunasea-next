import 'package:lunasea/core.dart';
import 'package:lunasea/extensions/int/bytes.dart';

class RTorrentTorrentData {
  final String hash;
  final String name;
  final int size;
  final int completed;
  final int downRate;
  final int upRate;
  final bool isActive;
  final int state;
  final String message;
  final int dateAdded;
  final int dateDone;
  final double ratio;
  final String label;

  RTorrentTorrentData({
    required this.hash,
    required this.name,
    required this.size,
    required this.completed,
    required this.downRate,
    required this.upRate,
    required this.isActive,
    required this.state,
    required this.message,
    required this.dateAdded,
    required this.dateDone,
    required this.ratio,
    required this.label,
  });

  int get percentageDone {
    return size == 0 ? 0 : ((completed / size) * 100).clamp(0, 100).round();
  }

  bool get isCompleted {
    return completed >= size;
  }

  bool get isSeeding {
    return isCompleted && isActive;
  }

  bool get isFinished {
    return isCompleted && !isActive;
  }

  bool get isDownloading {
    return !isCompleted && isActive;
  }

  bool get isError {
    return message.isNotEmpty;
  }

  bool get isPaused {
    return !isCompleted && !isActive && state == 1;
  }

  bool get isStopped {
    return state == 0;
  }

  String get status {
    if (isError) return 'Error: $message';
    if (isSeeding) return 'Seeding';
    if (isFinished) return 'Finished';
    if (isDownloading) return 'Downloading';
    if (isPaused) return 'Paused';
    if (isStopped) return 'Stopped';
    return 'Stopped';
  }

  String get subtitle {
    String sizeStr = '${completed.asBytes()} / ${size.asBytes()}';
    String downStr = downRate > 0 ? ' (↓ ${downRate.asBytes()}/s)' : '';
    String upStr = upRate > 0 ? ' (↑ ${upRate.asBytes()}/s)' : '';
    String labelStr = label.isNotEmpty ? ' • [$label]' : '';
    return '$status$labelStr - $sizeStr$downStr$upStr';
  }
}

class RTorrentTrackerData {
  final String url;
  final int type;

  RTorrentTrackerData({
    required this.url,
    required this.type,
  });
}

class RTorrentFileData {
  final String path;
  final int size;           // total size in bytes (f.size_bytes)
  final int completedChunks; // completed chunks (f.completed_chunks)
  final int sizeChunks;     // total chunks (f.size_chunks)

  RTorrentFileData({
    required this.path,
    required this.size,
    required this.completedChunks,
    required this.sizeChunks,
  });

  int get percentageDone {
    return sizeChunks == 0 ? 0 : ((completedChunks / sizeChunks) * 100).clamp(0, 100).round();
  }

  // Approximate completed bytes from chunk ratio
  int get completedBytes {
    return sizeChunks == 0 ? 0 : (size * completedChunks ~/ sizeChunks);
  }

  bool get isCompleted {
    return completedChunks >= sizeChunks && sizeChunks > 0;
  }
}
