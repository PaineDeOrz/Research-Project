// -----------------------------------------------------------------------------
// MUSICBRAINZ SERVICE
// -----------------------------------------------------------------------------
//
// Pure HTTP client for MusicBrainz, Wikidata, and Wikipedia APIs.
// Handles rate limiting so 2s between requests and retries with fresh connections
//
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:musik_app/core/log_debug.dart';

class MusicBrainzService {
  static const String _userAgent = 'MuskMusicPlayer/1.0.0 (Flutter Android client)';
  static const Duration _mbRateLimit = Duration(seconds: 2);

  DateTime _lastMbRequest = DateTime.fromMillisecondsSinceEpoch(0);

  /// Ensures at least 2 seconds between MusicBrainz requests.
  Future<void> _throttle() async {
    final elapsed = DateTime.now().difference(_lastMbRequest);
    if (elapsed < _mbRateLimit) {
      await Future.delayed(_mbRateLimit - elapsed);
    }
    _lastMbRequest = DateTime.now();
  }

  Map<String, String> get _mbHeaders => {
    'User-Agent': _userAgent,
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // MusicBrainz
  // ---------------------------------------------------------------------------

  /// Searches MusicBrainz for an artist by name and returns the MBID, or null.
  /// Searches with aliases to handle artists with non-Latin names.
  Future<String?> searchArtistMbid(String artistName) async {
    final searchTerm = artistName.toLowerCase();
    final uri = Uri.parse(
      'https://musicbrainz.org/ws/2/artist/'
    ).replace(queryParameters: {
      'query': 'artist:$artistName OR alias:$artistName',
      'fmt': 'json',
      'limit': '10',
    });

    // Retry up to 3 times with fresh connections
    for (var attempt = 1; attempt <= 3; attempt++) {
      await _throttle();
      final client = http.Client();
      try {
        final response = await client.get(uri, headers: _mbHeaders);
        if (response.statusCode != 200) return null;
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final artists = json['artists'] as List<dynamic>?;
        if (artists == null || artists.isEmpty) return null;

        // Find best match: exact name match, alias match, or first result
        for (final artist in artists) {
          final name = (artist['name'] as String?)?.toLowerCase();
          final sortName = (artist['sort-name'] as String?)?.toLowerCase();

          // Check primary name or sort name
          if (name == searchTerm || sortName == searchTerm) {
            return artist['id'] as String?;
          }

          // Check aliases
          final aliases = artist['aliases'] as List<dynamic>? ?? [];
          for (final alias in aliases) {
            final aliasName = (alias['name'] as String?)?.toLowerCase();
            final aliasSortName = (alias['sort-name'] as String?)?.toLowerCase();
            if (aliasName == searchTerm || aliasSortName == searchTerm) {
              return artist['id'] as String?;
            }
          }
        }

        // Fall back to first result if no exact match
        return artists.first['id'] as String?;
      } catch (exception) {
        if (attempt == 3) {
          logDebug('MusicBrainz: search failed for "$artistName": $exception');
          return null;
        }
      } finally {
        client.close();
      }
    }
    return null;
  }

  /// Looks up an artist by MBID and returns relations
  Future<({String? wikidataUrl, String? wikipediaTitle})> lookupArtistRelations(
    String mbid,
  ) async {
    final uri = Uri.parse(
      'https://musicbrainz.org/ws/2/artist/$mbid?inc=url-rels&fmt=json',
    );

    // Retry up to 3 times with fresh connections
    for (var attempt = 1; attempt <= 3; attempt++) {
      await _throttle();
      final client = http.Client();
      try {
        final response = await client.get(uri, headers: _mbHeaders);
        if (response.statusCode != 200) {
          return (wikidataUrl: null, wikipediaTitle: null);
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final relations = json['relations'] as List<dynamic>? ?? [];

        String? wikidataUrl;
        String? wikipediaTitle;

        for (final relation in relations) {
          final type = relation['type'] as String?;
          final urlObj = relation['url'] as Map<String, dynamic>?;
          final resource = urlObj?['resource'] as String?;
          if (resource == null) continue;

          if (type == 'wikidata' && wikidataUrl == null) {
            wikidataUrl = resource;
          }
          if (type == 'wikipedia' && wikipediaTitle == null) {
            final wikiUri = Uri.tryParse(resource);
            if (wikiUri != null && wikiUri.host == 'en.wikipedia.org') {
              final segments = wikiUri.pathSegments;
              if (segments.length >= 2 && segments[0] == 'wiki') {
                wikipediaTitle = segments.sublist(1).join('/');
              }
            }
          }
        }

        return (wikidataUrl: wikidataUrl, wikipediaTitle: wikipediaTitle);
      } catch (exception) {
        if (attempt == 3) {
          logDebug('MusicBrainz: lookup failed for $mbid: $exception');
          return (wikidataUrl: null, wikipediaTitle: null);
        }
      } finally {
        client.close();
      }
    }
    return (wikidataUrl: null, wikipediaTitle: null);
  }

  // ---------------------------------------------------------------------------
  // Wikidata
  // ---------------------------------------------------------------------------

  /// Fetches the image filename and english wikipedia title from a wikidata entity.
  Future<({String? imageFilename, String? wikipediaTitle})> fetchWikidataEntity(
    String wikidataId,
  ) async {
    final uri = Uri.parse(
      'https://www.wikidata.org/wiki/Special:EntityData/$wikidataId.json',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return (imageFilename: null, wikipediaTitle: null);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final entities = json['entities'] as Map<String, dynamic>?;
      if (entities == null) {
        return (imageFilename: null, wikipediaTitle: null);
      }

      final entity = entities[wikidataId] as Map<String, dynamic>?;

      // Get P18 (image filename)
      String? imageFilename;
      final claims = entity?['claims'] as Map<String, dynamic>?;
      final p18 = claims?['P18'] as List<dynamic>?;
      if (p18 != null && p18.isNotEmpty) {
        final mainsnak = p18.first['mainsnak'] as Map<String, dynamic>?;
        final datavalue = mainsnak?['datavalue'] as Map<String, dynamic>?;
        imageFilename = datavalue?['value'] as String?;
      }

      // Get English Wikipedia title from sitelinks
      String? wikipediaTitle;
      final sitelinks = entity?['sitelinks'] as Map<String, dynamic>?;
      final enwiki = sitelinks?['enwiki'] as Map<String, dynamic>?;
      wikipediaTitle = enwiki?['title'] as String?;

      logDebug('Wikidata: image=$imageFilename, wiki=$wikipediaTitle');
      return (imageFilename: imageFilename, wikipediaTitle: wikipediaTitle);
    } catch (exception) {
      logDebug('Wikidata: fetch error: $exception');
      return (imageFilename: null, wikipediaTitle: null);
    }
  }

  // ---------------------------------------------------------------------------
  // Wikipedia
  // ---------------------------------------------------------------------------

  /// Fetches a short bio extract from the wikipedia summary API.
  Future<String?> fetchWikipediaSummary(String title) async {
    final uri = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['extract'] as String?;
    } catch (exception) {
      logDebug('Wikipedia: summary error: $exception');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Image download
  // ---------------------------------------------------------------------------

  /// Downloads full resolution image from Wikimedia Commons.
  Future<bool> downloadImage(String filename, String savePath) async {
    final normalised = filename.replaceAll(' ', '_');
    final url = 'https://upload.wikimedia.org/wikipedia/commons/'
        '${_commonsHashPath(normalised)}/$normalised';

    return _downloadFromUrl(url, savePath);
  }

  /// Downloads thumbnail image from Wikimedia Commons at specified width.
  Future<bool> downloadImageThumbnail(
    String filename,
    String savePath, {
    int width = 200,
  }) async {
    final normalised = filename.replaceAll(' ', '_');
    // Thumbnail URL format: /thumb/{hash}/{filename}/{width}px-{filename}
    final hashPath = _commonsHashPath(normalised);
    final url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/'
        '$hashPath/$normalised/${width}px-$normalised';

    return _downloadFromUrl(url, savePath);
  }

  Future<bool> _downloadFromUrl(String url, String savePath) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        logDebug('ImageDownload: failed ${response.statusCode} for $url');
        return false;
      }
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return true;
    } catch (exception) {
      logDebug('ImageDownload: error: $exception');
      return false;
    }
  }

  /// Computes the two level hash path wikimedia Commons uses.
  String _commonsHashPath(String filename) {
    final bytes = utf8.encode(filename);
    final hash = _md5Hex(bytes);
    return '${hash[0]}/${hash[0]}${hash[1]}';
  }

  /// Minimal MD5 hex digest implementation for wikimedia Commons paths.
  String _md5Hex(List<int> data) {
    int leftRotate(int value, int count) =>
        ((value << count) | (value >> (32 - count))) & 0xFFFFFFFF;

    final shiftAmounts = <int>[
      7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
      5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
      4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
      6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    ];

    final constants = <int>[
      0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
      0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
      0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
      0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
      0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
      0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
      0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
      0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
      0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
      0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
      0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
      0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
      0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
      0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
      0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
      0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
    ];

    // MD5 state registers
    var stateA = 0x67452301;
    var stateB = 0xefcdab89;
    var stateC = 0x98badcfe;
    var stateD = 0x10325476;

    // Adding padding bits
    final message = List<int>.from(data);
    final originalLength = data.length;
    message.add(0x80);
    while (message.length % 64 != 56) {
      message.add(0);
    }

    // Append original length in bits as 64 bit little endian
    final bitLength = originalLength * 8;
    for (var byteIndex = 0; byteIndex < 8; byteIndex++) {
      message.add((bitLength >> (byteIndex * 8)) & 0xFF);
    }

    // Process each 512 bit chunk
    for (var chunkOffset = 0; chunkOffset < message.length; chunkOffset += 64) {
      final words = List<int>.generate(16, (wordIndex) {
        final byteOffset = chunkOffset + wordIndex * 4;
        return message[byteOffset] |
            (message[byteOffset + 1] << 8) |
            (message[byteOffset + 2] << 16) |
            (message[byteOffset + 3] << 24);
      });

      var tempA = stateA;
      var tempB = stateB;
      var tempC = stateC;
      var tempD = stateD;

      for (var round = 0; round < 64; round++) {
        int func, wordIdx;
        if (round < 16) {
          func = (tempB & tempC) | ((~tempB) & tempD);
          wordIdx = round;
        } else if (round < 32) {
          func = (tempD & tempB) | ((~tempD) & tempC);
          wordIdx = (5 * round + 1) % 16;
        } else if (round < 48) {
          func = tempB ^ tempC ^ tempD;
          wordIdx = (3 * round + 5) % 16;
        } else {
          func = tempC ^ (tempB | (~tempD));
          wordIdx = (7 * round) % 16;
        }

        func = (func + tempA + constants[round] + words[wordIdx]) & 0xFFFFFFFF;
        tempA = tempD;
        tempD = tempC;
        tempC = tempB;
        tempB = (tempB + leftRotate(func, shiftAmounts[round])) & 0xFFFFFFFF;
      }

      stateA = (stateA + tempA) & 0xFFFFFFFF;
      stateB = (stateB + tempB) & 0xFFFFFFFF;
      stateC = (stateC + tempC) & 0xFFFFFFFF;
      stateD = (stateD + tempD) & 0xFFFFFFFF;
    }

    String toHexLittleEndian(int value) {
      final bytes = [
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ];
      return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    }

    return '${toHexLittleEndian(stateA)}${toHexLittleEndian(stateB)}'
        '${toHexLittleEndian(stateC)}${toHexLittleEndian(stateD)}';
  }
}
