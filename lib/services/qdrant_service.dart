import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<List<dynamic>> getCollections() async {
    final response = await http.get(
      Uri.parse('$url/collections'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result']['collections'] ?? [];
    } else {
      throw Exception('Failed to get collections: ${response.body}');
    }
  }

  // Create a new collection
  Future<void> createCollection(String collectionName, int vectorSize) async {
    final response = await http.put(
      Uri.parse('$url/collections/$collectionName'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
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
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
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
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'vector': vector, 'limit': limit}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? [];
    } else {
      throw Exception('Failed to search: ${response.body}');
    }
  }

  // Add more methods as needed, e.g., deleteCollection, getPoints, etc.

  // Test method to verify connection
  Future<void> testConnection() async {
    try {
      final collections = await getCollections();
      print('Successfully connected to Qdrant. Collections: $collections');
    } catch (e) {
      print('Failed to connect to Qdrant: $e');
    }
  }
}
