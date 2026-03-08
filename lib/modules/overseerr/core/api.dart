import 'package:lunasea/core.dart';
import 'package:lunasea/modules/overseerr/core/models/media_request.dart';
import 'package:lunasea/modules/overseerr/core/models/search_result.dart';

class OverseerrAPI {
  final Dio _dio;
  final String _endpoint;

  OverseerrAPI._internal(this._dio, this._endpoint);

  factory OverseerrAPI.from(LunaProfile profile) {
    String host = profile.overseerrHost.trim();
    if (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    // Overseerr API is usually at /api/v1
    final String endpoint = '$host/api/v1';

    String key = profile.overseerrKey.replaceAll(RegExp(r'[\u0000-\u001f\x7f-\x9f]'), '').trim();

    Dio client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': key,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x86) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          ...profile.overseerrHeaders,
        },
        followRedirects: true,
        maxRedirects: 5,
        responseType: ResponseType.json,
      ),
    );

    client.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.next(options);
      },
    ));

    return OverseerrAPI._internal(client, endpoint);
  }

  void logError(String text, Object error, StackTrace trace) =>
      LunaLogger().error('Overseerr: $text', error, trace);

  Future<dynamic> testConnection() async {
    try {
      return await _dio.get('$_endpoint/status');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error: Ensure Overseerr is reachable.');
      }
      rethrow;
    }
  }

  Future<List<OverseerrMediaRequest>> getRequests() async {
    try {
      final response = await _dio.get(
        '$_endpoint/request',
      );
      
      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        for (var r in results) {
          LunaLogger().debug('DEBUG: Overseerr Full Request JSON: $r');
        }
        return results.map((json) => OverseerrMediaRequest.fromJson(json)).toList();
      }
      return [];
    } catch (error, stack) {
      logError('Failed to fetch requests', error, stack);
      return [];
    }
  }

  Future<List<OverseerrSearchResult>> search(String query) async {
    try {
      final response = await _dio.get(
        '$_endpoint/search',
        queryParameters: {
          'query': query,
        },
      );
      LunaLogger().debug('Overseerr Search Status: ${response.statusCode}');
      return (response.data['results'] as List).map((result) => OverseerrSearchResult.fromJson(result)).toList();
    } catch (error, stack) {
      logError('Failed to search Overseerr', error, stack);
      return [];
    }
  }

  Future<bool> requestMedia({
    required int tmdbId,
    required String mediaType,
    required int is4k,
  }) async {
    try {
      await _dio.post('$_endpoint/request', data: {
        'mediaId': tmdbId,
        'mediaType': mediaType,
        'is4k': is4k == 1,
      });
      return true;
    } catch (error, stack) {
      logError('Failed to request media', error, stack);
      return false;
    }
  }
}
