import 'lib/services/qdrant_service.dart';

void main() async {
  final qdrantService = QdrantService.withCredentials();
  await qdrantService.testConnection();
}
