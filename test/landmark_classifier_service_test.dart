import 'package:flutter_test/flutter_test.dart';
import 'package:signspeak/features/translate/services/landmark_classifier_service.dart';
import 'package:signspeak/features/translate/services/spatial_landmark_classifier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carga el modelo estático y produce una predicción válida', () async {
    final classifier = LandmarkClassifierService();
    await classifier.initialize();

    final prediction = classifier.predictFeatures(List<double>.filled(63, 0));

    expect(classifier.isInitialized, isTrue);
    expect(
      prediction.label,
      isIn(const [
        'A',
        'B',
        'C',
        'D',
        'E',
        'L',
        'M',
        'N',
        'O',
        'P',
        'R',
        'U',
        'V',
        'W',
        'Y',
      ]),
    );
    expect(prediction.confidence, inInclusiveRange(0, 1));
  });

  test('carga el modelo espacial G, H, I, K y T', () async {
    final classifier = SpatialLandmarkClassifierService();

    await classifier.initialize();

    expect(classifier.isInitialized, isTrue);
  });
}
