import 'dart:convert';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/rtorrent/core/api/data.dart';

class RTorrentAPI {
  final Dio _dio;
  final String _endpoint;

  RTorrentAPI._internal(this._dio, this._endpoint);

  factory RTorrentAPI.from(LunaProfile profile) {
    // rTorrent XML-RPC endpoint is at /RPC2
    // The user provides the base path (e.g. http://192.168.0.4:8080/r)
    // We POST directly to the full RPC2 URL
    String host = profile.rtorrentHost.trim();
    if (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    final String endpoint = '$host/RPC2';

    Dio client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'text/xml',
          ...profile.rtorrentHeaders,
        },
        followRedirects: true,
        maxRedirects: 5,
        responseType: ResponseType.plain,
      ),
    );

    if (profile.rtorrentUsername.isNotEmpty && profile.rtorrentPassword.isNotEmpty) {
      String auth = 'Basic ${base64.encode(utf8.encode('${profile.rtorrentUsername}:${profile.rtorrentPassword}'))}';
      client.options.headers['Authorization'] = auth;
    }

    return RTorrentAPI._internal(client, endpoint);
  }

  void logError(String text, Object error, StackTrace trace) =>
      LunaLogger().error('rTorrent: $text', error, trace);

  Future<Response> _xmlRpc(String methodName, [List<dynamic> params = const []]) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('methodCall', nest: () {
      builder.element('methodName', nest: methodName);
      if (params.isNotEmpty) {
        builder.element('params', nest: () {
          for (final param in params) {
            builder.element('param', nest: () {
              builder.element('value', nest: () => _buildXmlValue(builder, param));
            });
          }
        });
      }
    });

    try {
      final xmlString = builder.buildDocument().toXmlString();
      final response = await _dio.post(_endpoint, data: xmlString);

      final document = XmlDocument.parse(response.data);
      final fault = document.findAllElements('fault').firstOrNull;
      if (fault != null) {
        final members = fault.findAllElements('member').toList();
        String faultString = 'Unknown rTorrent Fault';
        for (final member in members) {
          if (member.getElement('name')?.innerText == 'faultString') {
            faultString = member.getElement('value')?.innerText ?? faultString;
            break;
          }
        }
        LunaLogger().warning('rTorrent: XML-RPC Fault ($methodName): $faultString');
        throw Exception(faultString);
      }
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error: Ensure rTorrent is reachable and CORS security is disabled if on Web.');
      }
      rethrow;
    }
  }

  void _buildXmlValue(XmlBuilder builder, dynamic value) {
    if (value is String) {
      builder.element('string', nest: value);
    } else if (value is int) {
      builder.element('i4', nest: value.toString());
    } else if (value is bool) {
      builder.element('boolean', nest: value ? '1' : '0');
    } else if (value is Uint8List) {
      // Must check Uint8List BEFORE List, since Uint8List extends List<int>
      builder.element('base64', nest: base64.encode(value));
    } else if (value is List) {
      builder.element('array', nest: () {
        builder.element('data', nest: () {
          for (final item in value) {
            builder.element('value', nest: () => _buildXmlValue(builder, item));
          }
        });
      });
    } else if (value is Map) {
      builder.element('struct', nest: () {
        value.forEach((key, val) {
          builder.element('member', nest: () {
            builder.element('name', nest: key);
            builder.element('value', nest: () => _buildXmlValue(builder, val));
          });
        });
      });
    }
  }

  Future<dynamic> testConnection() async => _xmlRpc('system.listMethods');

  Future<List<RTorrentTorrentData>> getTorrents() async {
    try {
      final response = await _xmlRpc('d.multicall2', [
        '',
        'main',
        'd.hash=',
        'd.name=',
        'd.size_bytes=',
        'd.completed_bytes=',
        'd.down.rate=',
        'd.up.rate=',
        'd.is_active=',
        'd.state=',
        'd.message=',
        'd.creation_date=',
        'd.timestamp.finished=',
        'd.ratio=',
        'd.custom1=', // Used commonly for labels
      ]);

      final document = XmlDocument.parse(response.data);
      final results = document.findAllElements('value').where((e) => e.parentElement?.name.local == 'data');
      
      List<RTorrentTorrentData> torrents = [];
      for (final result in results) {
        final values = result.findAllElements('value').toList();
        if (values.length >= 13) {
          torrents.add(RTorrentTorrentData(
            hash: _parseXmlValue(values[0]),
            name: _parseXmlValue(values[1]),
            size: int.tryParse(_parseXmlValue(values[2])) ?? 0,
            completed: int.tryParse(_parseXmlValue(values[3])) ?? 0,
            downRate: int.tryParse(_parseXmlValue(values[4])) ?? 0,
            upRate: int.tryParse(_parseXmlValue(values[5])) ?? 0,
            isActive: _parseXmlValue(values[6]) == '1',
            state: int.tryParse(_parseXmlValue(values[7])) ?? 0,
            message: _parseXmlValue(values[8]),
            dateAdded: int.tryParse(_parseXmlValue(values[9])) ?? 0,
            dateDone: int.tryParse(_parseXmlValue(values[10])) ?? 0,
            ratio: (int.tryParse(_parseXmlValue(values[11])) ?? 0) / 1000.0, // Ratio is sent as int * 1000
            label: _parseXmlValue(values[12]),
          ));
        }
      }
      return torrents;
    } catch (error, stack) {
      logError('Failed to fetch torrents', error, stack);
      return [];
    }
  }

  String _parseXmlValue(XmlElement element) {
    final types = ['string', 'i4', 'int', 'boolean', 'double'];
    for (final type in types) {
      final node = element.getElement(type);
      if (node != null) return node.innerText;
    }
    return element.innerText;
  }

  Future<bool> stopTorrent(String hash) async {
    final String h = hash.trim();
    LunaLogger().warning('rTorrent: Stopping torrent ($h)');
    try {
      await _xmlRpc('d.stop', [h]);
      await _xmlRpc('d.close', [h]);
      return true;
    } catch (error, stack) {
      logError('Failed to stop torrent ($h)', error, stack);
      return false;
    }
  }

  Future<bool> pauseTorrent(String hash) async {
    try {
      await _xmlRpc('d.stop', [hash]);
      return true;
    } catch (error, stack) {
      logError('Failed to pause torrent ($hash)', error, stack);
      return false;
    }
  }

  Future<bool> resumeTorrent(String hash) async {
    try {
      await _xmlRpc('d.start', [hash]);
      return true;
    } catch (error, stack) {
      logError('Failed to resume torrent ($hash)', error, stack);
      return false;
    }
  }

  Future<bool> removeTorrent(String hash, {bool deleteData = false}) async {
    final String h = hash.trim().toLowerCase();
    LunaLogger().warning('rTorrent: Removing torrent ($h), Delete Data: $deleteData');
    try {
      // 1. Ensure it's stopped and closed
      try {
        await _xmlRpc('d.stop', [h]);
        await _xmlRpc('d.close', [h]);
      } catch (e) {
        LunaLogger().warning('rTorrent: Error during stop/close before removal ($h): $e');
      }

      // 2. Perform removal
      if (deleteData) {
        // Attempt to delete files via execute commands
        try {
          String? path;
          // Try d.base_path first
          try {
            final response = await _xmlRpc('d.base_path', [h]);
            path = _parseXmlValue(XmlDocument.parse(response.data).rootElement).trim();
          } catch (_) {}
          
          // Try d.directory if base_path is empty or failed
          if (path == null || path.isEmpty) {
            try {
              final response = await _xmlRpc('d.directory', [h]);
              path = _parseXmlValue(XmlDocument.parse(response.data).rootElement).trim();
            } catch (_) {}
          }

          if (path != null && path.isNotEmpty && path != '/') {
            LunaLogger().debug('rTorrent: Extracted deletion path: "$path"');
            final commandsWithTarget = ['', 'rm', '-rf', path];
            final commandsWithoutTarget = ['rm', '-rf', path];
            
            bool deleted = false;
            for (final method in ['execute.throw.bg', 'execute2', 'execute']) {
              if (deleted) break;
              try {
                final res = await _xmlRpc(method, commandsWithTarget);
                LunaLogger().debug('rTorrent: $method (with target) result: ${res.data}');
                deleted = true;
              } catch (e) {
                LunaLogger().warning('rTorrent: $method (with target) failed: $e');
                try {
                  final res = await _xmlRpc(method, commandsWithoutTarget);
                  LunaLogger().debug('rTorrent: $method (without target) result: ${res.data}');
                  deleted = true;
                } catch (e2) {
                  LunaLogger().warning('rTorrent: $method (without target) failed: $e2');
                }
              }
            }
            if (!deleted) {
              LunaLogger().error('rTorrent: All execution methods failed for path deletion ("$path")', Exception('Execution failed'), StackTrace.current);
            }
          }
        } catch (e) {
          LunaLogger().warning('rTorrent: Failed to delete data physically ($h): $e');
        }

        // Set d.custom5 to '1' - this is a common convention (ruTorrent/custom scripts)
        // to signal that data should be deleted upon d.erase.
        try {
          await _xmlRpc('d.custom.set', [h, 'custom5', '1']);
          await _xmlRpc('d.custom.set', [h, 'delete_data', '1']);
        } catch (e) {
          LunaLogger().warning('rTorrent: Failed to set deletion flags ($h): $e');
        }

        // Also try d.delete_tied which specifically deletes the .torrent file
        try {
          await _xmlRpc('d.delete_tied', [h]);
        } catch (e) {
          LunaLogger().warning('rTorrent: d.delete_tied failed ($h): $e');
        }
      }

      LunaLogger().warning('rTorrent: Calling d.erase for torrent ($h)');
      await _xmlRpc('d.erase', [h]);
      
      LunaLogger().warning('rTorrent: Removal command executed successfully ($h)');
      return true;
    } catch (error, stack) {
      logError('Failed to remove torrent ($h)', error, stack);
      return false;
    }
  }

  Future<bool> addTorrentByUrl(String url) async {
    try {
      await _xmlRpc('load.start', ['', url]);
      return true;
    } catch (error, stack) {
      logError('Failed to add torrent by URL', error, stack);
      return false;
    }
  }

  Future<bool> addTorrentByFile(Uint8List bytes) async {
    try {
      // Some versions expect ['', bytes], others just [bytes]
      // We'll try the more common single argument for "raw" loading
      await _xmlRpc('load.raw_start', ['', bytes]);
      return true;
    } catch (error, stack) {
      logError('Failed to add torrent by file', error, stack);
      return false;
    }
  }

  Future<List<RTorrentTrackerData>> getTrackers(String hash) async {
    try {
      final response = await _xmlRpc('t.multicall', [
        hash,
        '',
        't.url=',
        't.type=',
      ]);

      final document = XmlDocument.parse(response.data);
      final results = document.findAllElements('value').where((e) => e.parentElement?.name.local == 'data');
      
      List<RTorrentTrackerData> trackers = [];
      for (final result in results) {
        final values = result.findAllElements('value').toList();
        if (values.length >= 2) {
          trackers.add(RTorrentTrackerData(
            url: _parseXmlValue(values[0]),
            type: int.tryParse(_parseXmlValue(values[1])) ?? 0,
          ));
        }
      }
      return trackers;
    } catch (error, stack) {
      logError('Failed to fetch trackers for $hash', error, stack);
      return [];
    }
  }

  Future<List<RTorrentFileData>> getFiles(String hash) async {
    try {
      final response = await _xmlRpc('f.multicall', [
        hash,
        '',
        'f.path=',
        'f.size_bytes=',
        'f.completed_chunks=',
        'f.size_chunks=',
      ]);

      final document = XmlDocument.parse(response.data);
      final results = document.findAllElements('value').where((e) => e.parentElement?.name.local == 'data');
      
      List<RTorrentFileData> files = [];
      for (final result in results) {
        final values = result.findAllElements('value').toList();
        if (values.length >= 4) {
          files.add(RTorrentFileData(
            path: _parseXmlValue(values[0]),
            size: int.tryParse(_parseXmlValue(values[1])) ?? 0,
            completedChunks: int.tryParse(_parseXmlValue(values[2])) ?? 0,
            sizeChunks: int.tryParse(_parseXmlValue(values[3])) ?? 0,
          ));
        }
      }
      return files;
    } catch (error, stack) {
      logError('Failed to fetch files for $hash', error, stack);
      return [];
    }
  }

  Future<bool> setLabel(String hash, String label) async {
    try {
      await _xmlRpc('d.custom1.set', [hash, label]);
      return true;
    } catch (error, stack) {
      logError('Failed to set label for $hash', error, stack);
      return false;
    }
  }

  Future<bool> checkTorrent(String hash) async {
    try {
      await _xmlRpc('d.check_hash', [hash]);
      return true;
    } catch (error, stack) {
      logError('Failed to check torrent $hash', error, stack);
      return false;
    }
  }
}
