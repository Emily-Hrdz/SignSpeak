package com.example.signspeak

import android.graphics.Bitmap
import android.graphics.BitmapFactory
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

                else -> result.notImplemented()
            }
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