/// Grammar task data model — mapped from `level_assets.grammar` API response.
class GrammarTask {
  final int id;
  final String taskId;
  final String taskName;
  final String sentence;
  final List<String> words;
  final String? imageUrl;
  final List<String>? nonRelated1;
  final List<String>? nonRelated2;
  final List<String>? nonRelated3;

  const GrammarTask({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.sentence,
    required this.words,
    this.imageUrl,
    this.nonRelated1,
    this.nonRelated2,
    this.nonRelated3,
  });

  factory GrammarTask.fromMap(Map<String, dynamic> map) {
    return GrammarTask(
      id: map['id'] as int,
      taskId: map['task_id']?.toString() ?? '',
      taskName: map['task_name']?.toString() ?? '',
      sentence: map['sentence']?.toString() ?? '',
      words: _parseWords(map['words']),
      imageUrl: _pickImage(map),
      nonRelated1: _parsePostgresArray(map['non_related_1']),
      nonRelated2: _parsePostgresArray(map['non_related_2']),
      nonRelated3: _parsePostgresArray(map['non_related_3']),
    );
  }

  // ------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------

  /// words can arrive as a JSON array ["a","b"] or a raw List
  static List<String> _parseWords(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    // fallback: split sentence by space
    return raw.toString().split(' ');
  }

  /// Pick the first non-null, non-empty image URL from image_url_1/2/3
  static String? _pickImage(Map<String, dynamic> map) {
    for (final key in ['image_url_1', 'image_url_2', 'image_url_3']) {
      final v = map[key]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Postgres text-array format: `{"a","b"}` → List<String>
  static List<String>? _parsePostgresArray(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final s = raw.toString().trim();
    if (s == '{}' || s.isEmpty) return [];
    // strip `{` and `}`, then split by `,` and clean quotes
    final inner = s.replaceAll(RegExp(r'^\{|\}$'), '');
    return inner
        .split(',')
        .map((e) => e.trim().replaceAll('"', ''))
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
