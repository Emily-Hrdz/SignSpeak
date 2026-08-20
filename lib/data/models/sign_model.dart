enum SignCategory {
  alphabet('Abecedario'),
  numbers('Números'),
  phrases('Frases básicas');

  const SignCategory(this.label);

  final String label;
}

class SignModel {
  const SignModel({
    required this.name,
    required this.category,
    required this.videoAsset,
    required this.instructions,
  });

  final String name;
  final SignCategory category;
  final String videoAsset;
  final String instructions;
}
