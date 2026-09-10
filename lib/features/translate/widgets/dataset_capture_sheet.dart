import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../../../core/widgets/clay_components.dart';
import '../services/landmark_dataset_service.dart';

class DatasetCaptureSheet extends StatefulWidget {
  const DatasetCaptureSheet({required this.handsProvider, super.key});

  final List<Hand> Function() handsProvider;

  @override
  State<DatasetCaptureSheet> createState() => _DatasetCaptureSheetState();
}

class _DatasetCaptureSheetState extends State<DatasetCaptureSheet> {
  static const _labels = ['A', 'B', 'C', 'D', 'E'];
  static const _targetPerSeries = 30;

  final _dataset = LandmarkDatasetService();
  String _selectedLabel = _labels.first;
  String _handSide = 'Derecha';
  DatasetStats _stats = const DatasetStats(total: 0, byLabel: {});
  bool _isLoading = true;
  bool _isCapturingSeries = false;
  int _seriesProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _isCapturingSeries = false;
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _dataset.getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      if (mounted) _showMessage('No se pudo leer el conjunto de datos.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _captureOne({bool showFeedback = true}) async {
    final hands = widget.handsProvider();
    if (hands.length != 1 || hands.first.landmarks.length < 21) {
      if (showFeedback) {
        _showMessage('Coloca solamente una mano completa frente a la cámara.');
      }
      return false;
    }

    try {
      await _dataset.saveSample(
        label: _selectedLabel,
        handSide: _handSide,
        landmarks: hands.first.landmarks,
      );
      await _loadStats();
      if (showFeedback && mounted) _showMessage('Muestra guardada.');
      return true;
    } catch (_) {
      if (showFeedback && mounted) {
        _showMessage('No se pudo guardar la muestra.');
      }
      return false;
    }
  }

  Future<void> _captureSeries() async {
    setState(() {
      _isCapturingSeries = true;
      _seriesProgress = 0;
    });

    var attempts = 0;
    while (mounted &&
        _isCapturingSeries &&
        _seriesProgress < _targetPerSeries &&
        attempts < 90) {
      attempts++;
      final saved = await _captureOne(showFeedback: false);
      if (saved && mounted) setState(() => _seriesProgress++);
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    if (!mounted) return;
    final completed = _seriesProgress == _targetPerSeries;
    setState(() => _isCapturingSeries = false);
    _showMessage(
      completed
          ? 'Serie de $_targetPerSeries muestras completada.'
          : 'Serie detenida en $_seriesProgress muestras.',
    );
  }

  Future<void> _export() async {
    if (_stats.total == 0) {
      _showMessage('Primero captura al menos una muestra.');
      return;
    }
    try {
      final path = await _dataset.export();
      if (mounted) _showMessage('Archivo exportado en $path');
    } catch (_) {
      if (mounted) _showMessage('No se pudo exportar el archivo.');
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar muestras'),
        content: const Text(
          'Se eliminarán todas las muestras guardadas en este teléfono.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _dataset.clear();
    await _loadStats();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: ClaySurface(
          borderRadius: 28,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Crear muestras',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: _isCapturingSeries
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Text(
                  'Realiza la seña y mueve ligeramente la mano entre muestras. Usa una sola mano y buena iluminación.',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLabel,
                        decoration: const InputDecoration(labelText: 'Seña'),
                        items: [
                          for (final label in _labels)
                            DropdownMenuItem(value: label, child: Text(label)),
                        ],
                        onChanged: _isCapturingSeries
                            ? null
                            : (value) => setState(
                                () => _selectedLabel = value ?? _selectedLabel,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _handSide,
                        decoration: const InputDecoration(labelText: 'Mano'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Derecha',
                            child: Text('Derecha'),
                          ),
                          DropdownMenuItem(
                            value: 'Izquierda',
                            child: Text('Izquierda'),
                          ),
                        ],
                        onChanged: _isCapturingSeries
                            ? null
                            : (value) => setState(
                                () => _handSide = value ?? _handSide,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClayButton(
                  label: _isCapturingSeries
                      ? 'Capturando $_seriesProgress/$_targetPerSeries'
                      : 'Capturar una muestra',
                  icon: Icons.add_a_photo_rounded,
                  isLoading: _isCapturingSeries,
                  onPressed: _captureOne,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _isCapturingSeries
                      ? () => setState(() => _isCapturingSeries = false)
                      : _captureSeries,
                  icon: Icon(
                    _isCapturingSeries
                        ? Icons.stop_circle_outlined
                        : Icons.burst_mode_outlined,
                  ),
                  label: Text(
                    _isCapturingSeries
                        ? 'Detener serie'
                        : 'Capturar serie de $_targetPerSeries',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isLoading
                      ? 'Leyendo muestras…'
                      : '${_stats.total} muestras guardadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in _labels)
                      Chip(
                        label: Text('$label: ${_stats.byLabel[label] ?? 0}'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isCapturingSeries ? null : _export,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Exportar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Borrar todas las muestras',
                      onPressed: _isCapturingSeries ? null : _confirmClear,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
