import '../models/nutrition_profile.dart';
import 'nutrition_database.dart';

/// Provenance is selected by the person, never supplied by recognition JSON.
/// Legacy diary entries have no provenance; they are not upgraded by guessing.
class NutritionProvenance {
  const NutritionProvenance({
    required this.kind,
    required this.reference,
    this.recordId,
    this.url,
  });
  final String kind;
  final String reference;
  final String? recordId;
  final String? url;

  void validate() {
    if (!['catalogue', 'label'].contains(kind) ||
        reference.trim().isEmpty ||
        reference.length > 240) {
      throw const FormatException('Invalid nutrition source');
    }
    if (kind == 'catalogue') {
      final uri = Uri.tryParse(url ?? '');
      if (recordId == null ||
          recordId!.trim().isEmpty ||
          uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const FormatException('Missing catalogue reference');
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'kind': kind,
    'reference': reference,
    if (recordId != null) 'recordId': recordId,
    if (url != null) 'url': url,
  };
  factory NutritionProvenance.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported nutrition source');
    }
    final source = NutritionProvenance(
      kind: json['kind'] as String,
      reference: json['reference'] as String,
      recordId: json['recordId'] as String?,
      url: json['url'] as String?,
    );
    source.validate();
    return source;
  }
}

class NutritionSource {
  const NutritionSource({
    required this.name,
    required this.profile,
    required this.provenance,
    required this.fiberKnown,
  });
  final String name;
  final NutritionProfile profile;
  final NutritionProvenance provenance;
  final bool fiberKnown;

  factory NutritionSource.catalogue(NutritionFoodRecord record) =>
      NutritionSource(
        name: record.name,
        profile: record.profile,
        fiberKnown: record.hasKnownFiber,
        provenance: NutritionProvenance(
          kind: 'catalogue',
          reference: record.source,
          recordId: record.id,
          url: record.sourceUrl,
        ),
      );
}

/// No model, lookup or energy formula fills absent facts. Values are taken from
/// the selected source per 100 g and scaled once by edible portion mass.
class NutritionEngine {
  static NutritionProfile portion(NutritionSource source, double grams) {
    source.provenance.validate();
    if (source.name.trim().isEmpty ||
        source.name.length > 80 ||
        !grams.isFinite ||
        grams <= 0 ||
        grams > 3000) {
      throw const FormatException('Invalid food or portion');
    }
    final p = source.profile;
    final nutrients = [p.protein, p.fat, p.carbs, p.fiber];
    if (!p.kcal.isFinite ||
        p.kcal < 0 ||
        p.kcal > 1000 ||
        nutrients.any((n) => !n.isFinite || n < 0 || n > 100) ||
        p.protein + p.fat + p.carbs > 105 ||
        (!source.fiberKnown && p.fiber != 0)) {
      throw const FormatException('Invalid source nutrition');
    }
    return p.portion(grams);
  }
}
