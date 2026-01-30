import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class QdrantService {
  final String url;
  final String apiKey;

  QdrantService({required this.url, required this.apiKey});

  // Factory to create instance with provided credentials
  factory QdrantService.withCredentials() {
    return QdrantService(
      url:
          'https://faed6125-410f-4337-94a9-8378d825ea21.europe-west3-0.gcp.cloud.qdrant.io',
      apiKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3MiOiJtIn0.TvhmKGu6jSw75KIkLRLYUGI0r1eebtJjsu7MyoPsqWs',
    );
  }

  // Factory to use a proxy base URL (the proxy will inject the real api-key server-side)
  factory QdrantService.withProxy(String proxyBaseUrl) {
    return QdrantService(url: proxyBaseUrl, apiKey: '');
  }

  // Auto factory: if running on Web and a proxy is provided, use proxy; otherwise use credentials
  factory QdrantService.auto({String? proxyBaseUrl}) {
    if (kIsWeb) {
      // If a proxy is provided, use it. For local development, default to localhost proxy.
      final base = (proxyBaseUrl != null && proxyBaseUrl.isNotEmpty)
          ? proxyBaseUrl
          : 'http://localhost:3000/qdrant';
      return QdrantService.withProxy(base);
    }
    return QdrantService.withCredentials();
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (apiKey.isNotEmpty) {
      headers['api-key'] = apiKey;
    }
    return headers;
  }

  Future<List<dynamic>> getCollections() async {
    final response = await http.get(
      Uri.parse('$url/collections'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result']['collections'] ?? [];
    } else {
      final errorMessage =
          'Failed to get collections: ${response.statusCode} - ${response.body}';
      print(errorMessage);
      throw Exception(errorMessage);
    }
  }

  // Create a new collection
  Future<void> createCollection(String collectionName, int vectorSize) async {
    final response = await http.put(
      Uri.parse('$url/collections/$collectionName'),
      headers: _headers(),
      body: jsonEncode({
        'vectors': {
          'size': vectorSize,
          'distance': 'Cosine', // or 'Euclid', 'Dot'
        },
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create collection: ${response.body}');
    }
  }

  // Upsert points (insert or update)
  Future<void> upsertPoints(
    String collectionName,
    List<Map<String, dynamic>> points,
  ) async {
    final response = await http.put(
      Uri.parse('$url/collections/$collectionName/points'),
      headers: _headers(),
      body: jsonEncode({'points': points}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upsert points: ${response.body}');
    }
  }

  // Search for similar vectors
  Future<List<dynamic>> search(
    String collectionName,
    List<double> vector,
    int limit,
  ) async {
    final response = await http.post(
      Uri.parse('$url/collections/$collectionName/points/search'),
      headers: _headers(),
      body: jsonEncode({'vector': vector, 'limit': limit}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? [];
    } else {
      throw Exception('Failed to search: ${response.body}');
    }
  }

  // Delete a collection
  Future<void> deleteCollection(String collectionName) async {
    final response = await http.delete(
      Uri.parse('$url/collections/$collectionName'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete collection: ${response.body}');
    }
  }

  // Get points from a collection
  Future<List<dynamic>> getPoints(String collectionName) async {
    final response = await http.post(
      Uri.parse('$url/collections/$collectionName/points/scroll'),
      headers: _headers(),
      body: jsonEncode({
        'limit': 100,
        'with_payload': true,
        'with_vectors': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result']['points'] ?? [];
    } else {
      throw Exception('Failed to get points: ${response.body}');
    }
  }

  // Get information about a specific collection
  Future<Map<String, dynamic>> getCollectionInfo(String collectionName) async {
    final response = await http.get(
      Uri.parse('$url/collections/$collectionName'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? {};
    } else {
      throw Exception('Failed to get collection info: ${response.body}');
    }
  }

  // Test method to verify connection
  Future<void> testConnection() async {
    try {
      if (kIsWeb) {
        // On web, browser fetches may be blocked by CORS or preflight issues.
        print(
          'Running on Web: Qdrant requests may be blocked by CORS. If you see "Failed to fetch", consider using a server-side proxy or enable CORS for your Qdrant Cloud cluster.',
        );
      }

      final collections = await getCollections();
      print('Successfully connected to Qdrant. Collections: $collections');
    } catch (e) {
      // Provide actionable guidance for common web/browser errors
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        print('Failed to connect to Qdrant from browser (CORS or network).');
        print('Options:');
        print('- Enable CORS / Allow your web origin in Qdrant Cloud admin.');
        print('- Use a small server-side proxy to forward requests to Qdrant.');
        print('- Run the app on mobile/desktop where CORS is not enforced.');
      }

      print('Failed to connect to Qdrant: $e');
    }
  }
}

/// Documentation for QdrantService
/// 
/// This service provides a comprehensive interface for interacting with Qdrant,
/// a vector similarity search engine. It supports both direct API access and
/// proxy-based access for web environments.
/// 
/// Key Features:
/// - Collection management (create, delete, list, get info)
/// - Vector operations (upsert, search)
/// - Point retrieval and management
/// - Automatic handling of API keys and headers
/// - Web-compatible proxy support
/// 
/// Usage Example:
/// ```dart
/// // Direct API access
/// final qdrant = QdrantService.withCredentials();
/// 
/// // Proxy-based access (for web)
/// final qdrant = QdrantService.withProxy('http://localhost:3000/qdrant');
/// 
/// // Auto-detect (recommended)
/// final qdrant = QdrantService.auto();
/// 
/// // Create a collection
/// await qdrant.createCollection('my_collection', 128);
/// 
/// // Upsert points
/// await qdrant.upsertPoints('my_collection', [
///   {
///     'id': '1',
///     'vector': [0.1, 0.2, 0.3],
///     'payload': {'name': 'example'}
///   }
/// ]);
/// 
/// // Search for similar vectors
/// final results = await qdrant.search('my_collection', [0.1, 0.2, 0.3], 5);
/// ```
/// 
/// Note: For web usage, ensure CORS is properly configured or use a server-side proxy.
/// The service automatically handles API key injection and content-type headers.
