package com.example.asset_pt_timah

import android.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "asset_pt_timah/exif"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "addGpsExif" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    val altitude = call.argument<Double>("altitude")
                    val timestamp = call.argument<Long>("timestamp")

                    if (imagePath != null && latitude != null && longitude != null && altitude != null && timestamp != null) {
                        val success = addGpsExifData(imagePath, latitude, longitude, altitude, timestamp)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun addGpsExifData(imagePath: String, latitude: Double, longitude: Double, altitude: Double, timestamp: Long): Boolean {
        return try {
            val exif = ExifInterface(imagePath)

            // Convert decimal degrees to DMS (Degrees, Minutes, Seconds)
            val latDMS = convertToDMS(Math.abs(latitude))
            val lonDMS = convertToDMS(Math.abs(longitude))

            // Set GPS data
            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, latDMS)
            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, if (latitude >= 0) "N" else "S")
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, lonDMS)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, if (longitude >= 0) "E" else "W")
            exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE, "${(altitude * 1000).toInt()}/1000")
            exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE_REF, if (altitude >= 0) "0" else "1")

            // Set GPS timestamp
            val date = Date(timestamp)
            val dateFormat = SimpleDateFormat("yyyy:MM:dd", Locale.US)
            val timeFormat = SimpleDateFormat("HH:mm:ss", Locale.US)
            exif.setAttribute(ExifInterface.TAG_GPS_DATESTAMP, dateFormat.format(date))
            exif.setAttribute(ExifInterface.TAG_GPS_TIMESTAMP, timeFormat.format(date))

            // Set GPS processing method and version
            exif.setAttribute(ExifInterface.TAG_GPS_PROCESSING_METHOD, "GPS")
            exif.setAttribute(ExifInterface.TAG_GPS_VERSION_ID, "2.3.0.0")
            exif.setAttribute(ExifInterface.TAG_GPS_MAP_DATUM, "WGS-84")

            // Save changes
            exif.saveAttributes()

            println("GPS EXIF data berhasil ditambahkan ke $imagePath")
            println("Format Display: Lat: ${latitude}°, Long: ${longitude}°")
            println("Koordinat Decimal: $latitude, $longitude")
            println("Latitude: ${convertToDMSReadable(Math.abs(latitude))} ${if (latitude >= 0) "N" else "S"}")
            println("Longitude: ${convertToDMSReadable(Math.abs(longitude))} ${if (longitude >= 0) "E" else "W"}")
            println("Altitude: $altitude m")
            println("Format DMS untuk EXIF: Lat=${convertToDMS(Math.abs(latitude))}, Lng=${convertToDMS(Math.abs(longitude))}")

            true
        } catch (e: IOException) {
            println("Error menambahkan GPS EXIF: ${e.message}")
            false
        }
    }

    private fun convertToDMS(coordinate: Double): String {
        val degrees = coordinate.toInt()
        val minutesFloat = (coordinate - degrees) * 60.0
        val minutes = minutesFloat.toInt()
        val secondsFloat = (minutesFloat - minutes) * 60.0

        // Format: degrees/1,minutes/1,seconds*10000/10000 untuk presisi yang lebih baik
        val secondsNumerator = (secondsFloat * 10000).toInt()
        return "$degrees/1,$minutes/1,$secondsNumerator/10000"
    }

    private fun convertToDMSReadable(coordinate: Double): String {
        val degrees = coordinate.toInt()
        val minutesFloat = (coordinate - degrees) * 60.0
        val minutes = minutesFloat.toInt()
        val secondsFloat = (minutesFloat - minutes) * 60.0

        return "${degrees}°${minutes}'${String.format("%.2f", secondsFloat)}\""
    }
}
