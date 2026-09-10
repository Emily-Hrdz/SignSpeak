package com.example.signspeak

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.Category
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker.HandLandmarkerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    private val CHANNEL = "signspeak/mediapipe"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "loadMediaPipe" -> {
                    try {
                        val baseOptions = BaseOptions.builder()
                            .setModelAssetPath("hand_landmarker.task")
                            .build()

                        val options = HandLandmarkerOptions.builder()
                            .setBaseOptions(baseOptions)
                            .setRunningMode(RunningMode.IMAGE)
                            .setNumHands(1)
                            .setMinHandDetectionConfidence(0.5f)
                            .setMinHandPresenceConfidence(0.5f)
                            .setMinTrackingConfidence(0.5f)
                            .build()

                        val handLandmarker = HandLandmarker.createFromOptions(
                            this,
                            options
                        )

                        handLandmarker.close()

                        result.success("MediaPipe cargó correctamente")

                    } catch (t: Throwable) {
                        result.error(
                            "MEDIAPIPE_ERROR",
                            t.message ?: "Error desconocido",
                            null
                        )
                    }
                }

                "detectHandFromImage" -> {
                    try {
                        val imagePath = call.argument<String>("imagePath")

                        if (imagePath.isNullOrEmpty()) {
                            result.error("IMAGE_ERROR", "Ruta de imagen vacía", null)
                            return@setMethodCallHandler
                        }

                        val file = File(imagePath)
                        if (!file.exists()) {
                            result.error("IMAGE_ERROR", "La imagen no existe", null)
                            return@setMethodCallHandler
                        }

                        val bitmap: Bitmap = BitmapFactory.decodeFile(imagePath)
                            ?: run {
                                result.error("IMAGE_ERROR", "No se pudo leer la imagen", null)
                                return@setMethodCallHandler
                            }

                        val mpImage = BitmapImageBuilder(bitmap).build()

                        val baseOptions = BaseOptions.builder()
                            .setModelAssetPath("hand_landmarker.task")
                            .build()

                        val options = HandLandmarkerOptions.builder()
                            .setBaseOptions(baseOptions)
                            .setRunningMode(RunningMode.IMAGE)
                            .setNumHands(1)
                            .setMinHandDetectionConfidence(0.5f)
                            .setMinHandPresenceConfidence(0.5f)
                            .setMinTrackingConfidence(0.5f)
                            .build()

                        val handLandmarker = HandLandmarker.createFromOptions(this, options)
                        val detectionResult = handLandmarker.detect(mpImage)
                        handLandmarker.close()

                        val handsCount = detectionResult.landmarks().size

                        if (handsCount == 0) {
                            result.success("No se detectó mano")
                            return@setMethodCallHandler
                        }

                        val landmarks = detectionResult.landmarks()[0]
                        val handednessList = detectionResult.handedness()[0]
                        val handLabel = getHandLabel(handednessList)

                        val fingerCount = countRaisedFingers(landmarks, handLabel)
                        val basicSign = classifyBasicSign(fingerCount)

                        result.success(
                            "Mano detectada | Dedos arriba: $fingerCount | Posible seña: $basicSign"
                        )

                    } catch (t: Throwable) {
                        result.error(
                            "DETECTION_ERROR",
                            t.message ?: "Error desconocido al detectar mano",
                            null
                        )
                    }
                }

                "appendDatasetSample" -> {
                    try {
                        val label = call.argument<String>("label")?.trim().orEmpty()
                        val handSide = call.argument<String>("handSide")?.trim().orEmpty()
                        val landmarks = call.argument<List<Double>>("landmarks")

                        if (label.isEmpty() || landmarks == null || landmarks.size != 63) {
                            result.error(
                                "DATASET_ERROR",
                                "La etiqueta y los 63 valores de la mano son obligatorios",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val sample = JSONObject().apply {
                            put("version", 1)
                            put("label", label)
                            put("handSide", handSide)
                            put("capturedAt", System.currentTimeMillis())
                            put("landmarks", JSONArray(landmarks))
                        }
                        val datasetFile = getDatasetFile()
                        datasetFile.appendText(sample.toString() + "\n")
                        result.success(countDatasetLines(datasetFile))
                    } catch (t: Throwable) {
                        result.error("DATASET_ERROR", t.message, null)
                    }
                }

                "getDatasetStats" -> {
                    try {
                        val counts = linkedMapOf<String, Int>()
                        val datasetFile = getDatasetFile()
                        if (datasetFile.exists()) {
                            datasetFile.forEachLine { line ->
                                if (line.isNotBlank()) {
                                    val label = JSONObject(line).optString("label")
                                    if (label.isNotBlank()) {
                                        counts[label] = (counts[label] ?: 0) + 1
                                    }
                                }
                            }
                        }
                        result.success(
                            mapOf(
                                "total" to counts.values.sum(),
                                "labels" to counts
                            )
                        )
                    } catch (t: Throwable) {
                        result.error("DATASET_ERROR", t.message, null)
                    }
                }

                "clearDataset" -> {
                    try {
                        val datasetFile = getDatasetFile()
                        if (datasetFile.exists()) datasetFile.delete()
                        result.success(null)
                    } catch (t: Throwable) {
                        result.error("DATASET_ERROR", t.message, null)
                    }
                }

                "deleteLastDatasetSample" -> {
                    try {
                        val datasetFile = getDatasetFile()
                        val samples = readDatasetLines(datasetFile).toMutableList()
                        if (samples.isEmpty()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }

                        val deletedLabel = JSONObject(samples.removeAt(samples.lastIndex))
                            .optString("label")
                        writeDatasetLines(datasetFile, samples)
                        result.success(
                            mapOf(
                                "label" to deletedLabel,
                                "total" to samples.size
                            )
                        )
                    } catch (t: Throwable) {
                        result.error("DATASET_ERROR", t.message, null)
                    }
                }

                "deleteDatasetSamplesForLabel" -> {
                    try {
                        val label = call.argument<String>("label")?.trim().orEmpty()
                        if (label.isEmpty()) {
                            result.error("DATASET_ERROR", "La etiqueta es obligatoria", null)
                            return@setMethodCallHandler
                        }

                        val datasetFile = getDatasetFile()
                        val samples = readDatasetLines(datasetFile)
                        val remaining = samples.filter { line ->
                            !JSONObject(line).optString("label").equals(label, ignoreCase = true)
                        }
                        writeDatasetLines(datasetFile, remaining)
                        result.success(
                            mapOf(
                                "removed" to samples.size - remaining.size,
                                "total" to remaining.size
                            )
                        )
                    } catch (t: Throwable) {
                        result.error("DATASET_ERROR", t.message, null)
                    }
                }

                "exportDataset" -> {
                    try {
                        val datasetFile = getDatasetFile()
                        if (!datasetFile.exists() || datasetFile.length() == 0L) {
                            result.error("DATASET_EMPTY", "No hay muestras para exportar", null)
                            return@setMethodCallHandler
                        }

                        val exportName = "lensegua_landmarks_${System.currentTimeMillis()}.jsonl"
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val values = ContentValues().apply {
                                put(MediaStore.Downloads.DISPLAY_NAME, exportName)
                                put(MediaStore.Downloads.MIME_TYPE, "application/json")
                                put(
                                    MediaStore.Downloads.RELATIVE_PATH,
                                    "${Environment.DIRECTORY_DOWNLOADS}/SignSpeak"
                                )
                            }
                            val uri = contentResolver.insert(
                                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                values
                            ) ?: throw IllegalStateException("No se pudo crear el archivo")
                            contentResolver.openOutputStream(uri)?.use { output ->
                                datasetFile.inputStream().use { input -> input.copyTo(output) }
                            } ?: throw IllegalStateException("No se pudo abrir el archivo")
                            result.success("Descargas/SignSpeak/$exportName")
                        } else {
                            val exportDirectory = File(
                                getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS),
                                "SignSpeak"
                            ).apply { mkdirs() }
                            val exportedFile = File(exportDirectory, exportName)
                            datasetFile.copyTo(exportedFile, overwrite = true)
                            result.success(exportedFile.absolutePath)
                        }
                    } catch (t: Throwable) {
                        result.error("DATASET_ERROR", t.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getDatasetFile(): File {
        val directory = File(filesDir, "datasets").apply { mkdirs() }
        return File(directory, "lensegua_landmarks.jsonl")
    }

    private fun countDatasetLines(file: File): Int {
        if (!file.exists()) return 0
        return file.useLines { lines -> lines.count { it.isNotBlank() } }
    }

    private fun readDatasetLines(file: File): List<String> {
        if (!file.exists()) return emptyList()
        return file.readLines().filter { it.isNotBlank() }
    }

    private fun writeDatasetLines(file: File, lines: List<String>) {
        if (lines.isEmpty()) {
            if (file.exists()) file.delete()
            return
        }

        val temporaryFile = File(file.parentFile, "${file.name}.tmp")
        temporaryFile.writeText(lines.joinToString(separator = "\n", postfix = "\n"))
        if (file.exists() && !file.delete()) {
            temporaryFile.delete()
            throw IllegalStateException("No se pudo actualizar el conjunto de datos")
        }
        if (!temporaryFile.renameTo(file)) {
            temporaryFile.copyTo(file, overwrite = true)
            temporaryFile.delete()
        }
    }

    private fun getHandLabel(handednessList: List<Category>): String {
        return if (handednessList.isNotEmpty()) {
            handednessList[0].categoryName()
        } else {
            "Unknown"
        }
    }

    private fun countRaisedFingers(
        landmarks: List<NormalizedLandmark>,
        handLabel: String
    ): Int {
        var count = 0

        // Pulgar
        val thumbTip = landmarks[4]
        val thumbIp = landmarks[3]

        val thumbIsOpen = if (handLabel == "Right") {
            thumbTip.x() < thumbIp.x()
        } else {
            thumbTip.x() > thumbIp.x()
        }

        if (thumbIsOpen) count++

        // Índice
        if (landmarks[8].y() < landmarks[6].y()) count++

        // Medio
        if (landmarks[12].y() < landmarks[10].y()) count++

        // Anular
        if (landmarks[16].y() < landmarks[14].y()) count++

        // Meñique
        if (landmarks[20].y() < landmarks[18].y()) count++

        return count
    }

    private fun classifyBasicSign(fingerCount: Int): String {
        return when (fingerCount) {
            0 -> "Puño"
            1 -> "Uno"
            2 -> "Dos"
            3 -> "Tres"
            4 -> "Cuatro"
            5 -> "Cinco"
            else -> "No reconocida"
        }
    }
}
