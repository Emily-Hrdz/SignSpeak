import '../models/sign_model.dart';

class DictionaryRepository {
  const DictionaryRepository();

  static const String _videoPath = 'assets/dictionary/videos';

  List<SignModel> getSigns() => const [
    SignModel(
      name: 'A',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_a.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'B',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_b.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'C',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_c.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'D',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_d.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'E',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_e.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'F',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_f.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'G',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_g.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'H',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_h.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'I',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_i.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'J',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_j.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'K',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_k.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'L',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_l.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'M',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_m.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'N',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_n.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'Ñ',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_enie.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'O',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_o.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'P',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_p.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'Q',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_q.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'R',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_r.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'S',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_s.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'T',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_t.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'U',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_u.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'V',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_v.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'W',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_w.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'X',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_x.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'Y',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_y.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: 'Z',
      category: SignCategory.alphabet,
      videoAsset: '$_videoPath/letra_z.mp4',
      instructions: _alphabetInstructions,
    ),
    SignModel(
      name: '1',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_1.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '2',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_2.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '3',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_3.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '4',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_4.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '5',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_5.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '6',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_6.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '7',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_7.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '8',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_8.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '9',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_9.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: '10',
      category: SignCategory.numbers,
      videoAsset: '$_videoPath/numero_10.mp4',
      instructions: _numberInstructions,
    ),
    SignModel(
      name: 'Hola',
      category: SignCategory.phrases,
      videoAsset: '$_videoPath/hola.mp4',
      instructions: _phraseInstructions,
    ),
    SignModel(
      name: 'Adiós',
      category: SignCategory.phrases,
      videoAsset: '$_videoPath/adios.mp4',
      instructions: _phraseInstructions,
    ),
    SignModel(
      name: 'Buenos días',
      category: SignCategory.phrases,
      videoAsset: '$_videoPath/buenos_dias.mp4',
      instructions: _phraseInstructions,
    ),
    SignModel(
      name: '¿Cómo estás?',
      category: SignCategory.phrases,
      videoAsset: '$_videoPath/como_estas.mp4',
      instructions: _phraseInstructions,
    ),
    SignModel(
      name: 'Gracias',
      category: SignCategory.phrases,
      videoAsset: '$_videoPath/gracias.mp4',
      instructions: _phraseInstructions,
    ),
    SignModel(
      name: 'Por favor',
      category: SignCategory.phrases,
      videoAsset: '$_videoPath/por_favor.mp4',
      instructions: _phraseInstructions,
    ),
    SignModel(
      name: 'Mi nombre es',
      category: SignCategory.phrases,
      videoAsset: '$_videoPath/mi_nombre_es.mp4',
      instructions: _phraseInstructions,
    ),
  ];

  static const _alphabetInstructions =
      'Observa la forma de la mano y la posición de cada dedo. Reproduce el video varias veces y practica frente a la cámara.';
  static const _numberInstructions =
      'Observa con atención los dedos levantados, la orientación de la palma y cualquier movimiento mostrado en el video.';
  static const _phraseInstructions =
      'Mira la posición inicial, el movimiento y la posición final. Practica lentamente y luego repite la seña con naturalidad.';
}
