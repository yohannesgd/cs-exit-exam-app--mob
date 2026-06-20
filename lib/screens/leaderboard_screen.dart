import 'package:hive/hive.dart';

List<Map<String, dynamic>> getTopScores() {
  final box = Hive.box('results_box');
  final allResults = box.values.map((e) => Map<String, dynamic>.from(e)).toList();

  // Sort by score (highest first), then take the top 10
  allResults.sort((a, b) => b['score'].compareTo(a['score']));
  return allResults.take(10).toList();
}