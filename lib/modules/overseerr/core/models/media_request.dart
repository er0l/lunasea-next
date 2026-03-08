import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';

class OverseerrMediaRequest {
  final int id;
  final int status; // 1: PENDING, 2: APPROVED, 3: DECLINED
  final String mediaType; // movie, tv
  final int tmdbId;
  final String title;
  final String overview;
  final String posterPath;
  final String requestedBy;
  final DateTime createdAt;

  OverseerrMediaRequest({
    required this.id,
    required this.status,
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.requestedBy,
    required this.createdAt,
  });

  factory OverseerrMediaRequest.fromJson(Map<String, dynamic> json) {
    LunaLogger().debug('Overseerr: Raw JSON for ID ${json['id']}: ${jsonEncode(json)}');
    return OverseerrMediaRequest(
      id: json['id'] ?? 0,
      status: json['status'] ?? 0,
      mediaType: json['media']?['mediaType'] ?? json['type'] ?? '',
      tmdbId: json['media']?['tmdbId'] ?? 0,
      title: _extractTitle(json),
      overview: _extractOverview(json),
      posterPath: json['media']?['posterPath'] ?? '',
      requestedBy: json['requestedBy']?['displayName'] ?? 'Unknown',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static String _extractOverview(Map<String, dynamic> json) {
    if (json['overview'] != null && json['overview'].toString().isNotEmpty) return json['overview'];

    if (json['media'] != null) {
      if (json['media']['overview'] != null && json['media']['overview'].toString().isNotEmpty) return json['media']['overview'];
      
      final movie = json['media']['movie'];
      if (movie != null && movie['overview'] != null && movie['overview'].toString().isNotEmpty) return movie['overview'];
      
      final tv = json['media']['tv'];
      if (tv != null && tv['overview'] != null && tv['overview'].toString().isNotEmpty) return tv['overview'];
    }
    return '';
  }

  String get statusText {
    switch (status) {
      case 1: return 'Pending';
      case 2: return 'Approved';
      case 3: return 'Declined';
      default: return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 1: return LunaColours.orange;
      case 2: return LunaColours.accent; // Green
      case 3: return LunaColours.red;
      default: return LunaColours.grey;
    }
  }

  static String _extractTitle(Map<String, dynamic> json) {
    // Check root and direct title/name properties
    if (json['title'] != null && json['title'].toString().isNotEmpty) return json['title'];
    if (json['name'] != null && json['name'].toString().isNotEmpty) return json['name'];

    if (json['media'] != null) {
      // Check media-level nested movie/tv titles
      final movie = json['media']['movie'];
      final tv = json['media']['tv'];
      if (movie != null) {
        if (movie['title'] != null && movie['title'].toString().isNotEmpty) return movie['title'];
      }
      if (tv != null) {
        if (tv['name'] != null && tv['name'].toString().isNotEmpty) return tv['name'];
      }

      // Check media-specific titles
      if (json['media']['title'] != null && json['media']['title'].toString().isNotEmpty) return json['media']['title'];
      if (json['media']['name'] != null && json['media']['name'].toString().isNotEmpty) return json['media']['name'];

      // Fallback to slug (e.g., 'the-boroughs' -> 'The Boroughs')
      final slug = json['media']['externalServiceSlug'] as String?;
      if (slug != null && slug.isNotEmpty) {
        // If it's just a number (like a TMDB ID), prefix it for context
        if (RegExp(r'^\d+$').hasMatch(slug)) {
          return '${json['media']['mediaType'] == 'movie' ? 'Movie' : 'TV Show'} $slug';
        }
        return slug.split('-').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : '');
        }).join(' ');
      }

      // Final fallback to ID
      if (json['media']['tmdbId'] != null) {
        return '${json['media']['mediaType'] == 'movie' ? 'Movie' : 'TV Show'} ${json['media']['tmdbId']}';
      }
    }

    return 'Request ${json['id'] ?? 'Unknown'}';
  }
}
