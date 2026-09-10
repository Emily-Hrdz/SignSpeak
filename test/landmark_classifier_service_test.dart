import 'package:flutter_test/flutter_test.dart';
import 'package:signspeak/features/translate/services/landmark_classifier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carga el modelo A-E y reproduce una predicción conocida', () async {
    final classifier = LandmarkClassifierService();
    await classifier.initialize();

    final prediction = classifier.predictFeatures(List<double>.filled(63, 0));

    expect(classifier.isInitialized, isTrue);
    expect(prediction.label, 'B');
    expect(prediction.confidence, closeTo(0.9772400741, 0.000001));
  });
}
