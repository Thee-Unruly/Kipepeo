import 'dart:math';
import '../models/credit_profile.dart';
import 'database_service.dart';

class VectorSearchService {
  final DatabaseService _db = DatabaseService();

  /// Since SQLite (standard) doesn't natively support vector types, 
  /// we implement an on-device Cosine Similarity scan for initial prototyping.
  /// For larger datasets (>10k profiles), we would integrate a native C extension or 
  /// use a specialized local library like 'faiss-mobile'.
  Future<List<Map<String, dynamic>>> findSimilarProfiles(
    List<double> queryEmbedding, {
    int topK = 5,
  }) async {
    final profiles = await _db.getAllProfiles();
    
    List<Map<String, dynamic>> results = [];

    for (var profile in profiles) {
      if (profile.embedding.length == queryEmbedding.length) {
        double similarity = _calculateCosineSimilarity(queryEmbedding, profile.embedding);
        results.add({
          'profile': profile,
          'similarity': similarity,
        });
      }
    }

    // Sort by similarity descending
    results.sort((a, b) => b['similarity'].compareTo(a['similarity']));

    return results.take(topK).toList();
  }

  double _calculateCosineSimilarity(List<double> vecA, List<double> vecB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
