package com.example.afa_pay

import android.Manifest
import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

sealed class NativeAttachmentState {
    data object Idle : NativeAttachmentState()
    data object Picking : NativeAttachmentState()
    data object Recording : NativeAttachmentState()
    data class Selected(val payload: Map<String, Any?>) : NativeAttachmentState()
    data class Failed(val message: String) : NativeAttachmentState()
}

class AttachmentPickerManager(
    private val activity: FlutterFragmentActivity,
) : MethodChannel.MethodCallHandler {
    private val resolver: ContentResolver = activity.contentResolver
    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(activity)
    private val _attachmentStateFlow = MutableStateFlow<NativeAttachmentState>(NativeAttachmentState.Idle)

    val attachmentStateFlow: StateFlow<NativeAttachmentState> = _attachmentStateFlow

    private var pendingResult: MethodChannel.Result? = null
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingAudioStartResult: MethodChannel.Result? = null
    private var recorder: MediaRecorder? = null
    private var recordingFile: File? = null
    private var recordingStartedAtMs: Long = 0

    private val documentLauncher: ActivityResultLauncher<Array<String>> =
        activity.registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            finishPending(uri?.let(::documentPayload))
        }

    private val photoPickerLauncher =
        activity.registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            finishImage(uri)
        }

    private val imageFallbackLauncher =
        activity.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            finishImage(result.data?.data)
        }

    private val contactLauncher =
        activity.registerForActivityResult(ActivityResultContracts.PickContact()) { uri ->
            finishPending(uri?.let(::contactPayload))
        }

    private val locationPermissionLauncher =
        activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            val result = pendingLocationResult
            pendingLocationResult = null
            if (result == null) return@registerForActivityResult
            if (granted) {
                fetchCurrentLocation(result)
            } else {
                fail(result, "LOCATION_DENIED", "Location permission denied.")
            }
        }

    private val audioPermissionLauncher =
        activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            val result = pendingAudioStartResult
            pendingAudioStartResult = null
            if (result == null) return@registerForActivityResult
            if (granted) {
                startRecorder(result)
            } else {
                fail(result, "AUDIO_DENIED", "Audio recording permission denied.")
            }
        }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDocument" -> pickDocument(result)
            "pickImage" -> pickImage(result)
            "pickContact" -> pickContact(result)
            "pickCurrentLocation" -> pickCurrentLocation(result)
            "startAudioRecording" -> startAudioRecording(result)
            "stopAudioRecording" -> stopAudioRecording(result)
            else -> result.notImplemented()
        }
    }

    private fun pickDocument(result: MethodChannel.Result) {
        if (!beginPending(result)) return
        documentLauncher.launch(
            arrayOf(
                "application/pdf",
                "text/*",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ),
        )
    }

    private fun pickImage(result: MethodChannel.Result) {
        if (!beginPending(result)) return
        if (ActivityResultContracts.PickVisualMedia.isPhotoPickerAvailable(activity)) {
            photoPickerLauncher.launch(
                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
            )
        } else {
            val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                type = "image/*"
                putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf("image/jpeg", "image/jpg", "image/png", "image/webp"),
                )
            }
            imageFallbackLauncher.launch(intent)
        }
    }

    private fun pickContact(result: MethodChannel.Result) {
        if (!beginPending(result)) return
        contactLauncher.launch(null)
    }

    private fun pickCurrentLocation(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            fetchCurrentLocation(result)
            return
        }
        pendingLocationResult = result
        locationPermissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
    }

    private fun startAudioRecording(result: MethodChannel.Result) {
        if (recorder != null) {
            result.success(null)
            return
        }
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            startRecorder(result)
            return
        }
        pendingAudioStartResult = result
        audioPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
    }

    private fun stopAudioRecording(result: MethodChannel.Result) {
        val activeRecorder = recorder
        val file = recordingFile
        if (activeRecorder == null || file == null) {
            result.success(null)
            return
        }
        recorder = null
        recordingFile = null
        try {
            activeRecorder.stop()
            activeRecorder.release()
            val durationMs = System.currentTimeMillis() - recordingStartedAtMs
            val payload = mapOf(
                "uri" to Uri.fromFile(file).toString(),
                "path" to file.absolutePath,
                "durationMs" to durationMs,
                "fileSizeBytes" to file.length(),
                "mimeType" to "audio/mp4",
            )
            _attachmentStateFlow.value = NativeAttachmentState.Selected(payload)
            result.success(payload)
        } catch (error: RuntimeException) {
            activeRecorder.release()
            file.delete()
            fail(result, "AUDIO_FAILED", "Audio recording failed.")
        } finally {
            _attachmentStateFlow.value = NativeAttachmentState.Idle
        }
    }

    @SuppressLint("MissingPermission")
    private fun fetchCurrentLocation(result: MethodChannel.Result) {
        fusedLocationClient.lastLocation
            .addOnSuccessListener { location ->
                if (location != null) {
                    result.success(
                        mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude,
                        ),
                    )
                    return@addOnSuccessListener
                }
                fusedLocationClient
                    .getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null)
                    .addOnSuccessListener { current ->
                        if (current == null) {
                            fail(result, "LOCATION_UNAVAILABLE", "Current location unavailable.")
                        } else {
                            result.success(
                                mapOf(
                                    "latitude" to current.latitude,
                                    "longitude" to current.longitude,
                                ),
                            )
                        }
                    }
                    .addOnFailureListener {
                        fail(result, "LOCATION_FAILED", "Unable to retrieve current location.")
                    }
            }
            .addOnFailureListener {
                fail(result, "LOCATION_FAILED", "Unable to retrieve current location.")
            }
    }

    private fun startRecorder(result: MethodChannel.Result) {
        val output = File(activity.cacheDir, "afapay_audio_${System.currentTimeMillis()}.m4a")
        val mediaRecorder = createRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setOutputFile(output.absolutePath)
            prepare()
            start()
        }
        recorder = mediaRecorder
        recordingFile = output
        recordingStartedAtMs = System.currentTimeMillis()
        _attachmentStateFlow.value = NativeAttachmentState.Recording
        result.success(null)
    }

    @Suppress("DEPRECATION")
    private fun createRecorder(): MediaRecorder {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(activity)
        } else {
            MediaRecorder()
        }
    }

    private fun beginPending(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            fail(result, "PICKER_BUSY", "Another attachment picker is already open.")
            return false
        }
        pendingResult = result
        _attachmentStateFlow.value = NativeAttachmentState.Picking
        return true
    }

    private fun finishPending(payload: Map<String, Any?>?) {
        val result = pendingResult ?: return
        pendingResult = null
        _attachmentStateFlow.value = if (payload == null) {
            NativeAttachmentState.Idle
        } else {
            NativeAttachmentState.Selected(payload)
        }
        result.success(payload)
    }

    private fun finishImage(uri: Uri?) {
        if (uri == null) {
            finishPending(null)
            return
        }
        try {
            val payload = imagePayload(uri)
            finishPending(payload)
        } catch (error: IllegalArgumentException) {
            val result = pendingResult
            pendingResult = null
            if (result != null) {
                fail(result, "IMAGE_UNSUPPORTED", error.message ?: "Unsupported image.")
            }
        }
    }

    private fun documentPayload(uri: Uri): Map<String, Any?> {
        val openable = queryOpenable(uri)
        val mimeType = resolver.getType(uri) ?: "application/octet-stream"
        val cacheFile = copyToCache(uri, openable.name, "afapay_document")
        return mapOf(
            "uri" to uri.toString(),
            "cachePath" to cacheFile.absolutePath,
            "fileName" to openable.name,
            "fileSizeBytes" to if (openable.size > 0) openable.size else cacheFile.length(),
            "mimeType" to mimeType,
        )
    }

    private fun imagePayload(uri: Uri): Map<String, Any?> {
        val mimeType = resolver.getType(uri) ?: inferImageMimeType(queryOpenable(uri).name)
        val allowed = setOf("image/jpeg", "image/jpg", "image/png", "image/webp")
        if (mimeType !in allowed) {
            throw IllegalArgumentException("Only JPG, PNG, and WEBP images are supported.")
        }
        val dimensions = imageDimensions(uri)
        val cacheFile = copyImageToCache(uri, mimeType)
        val openable = queryOpenable(uri)
        val size = if (openable.size > 0) openable.size else cacheFile.length()
        return mapOf(
            "uri" to uri.toString(),
            "cachePath" to cacheFile.absolutePath,
            "fileName" to openable.name,
            "mimeType" to mimeType,
            "fileSizeBytes" to size,
            "width" to dimensions.first,
            "height" to dimensions.second,
        )
    }

    private fun contactPayload(uri: Uri): Map<String, Any?> {
        var contactId = ""
        var name = "Contact"
        resolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idIndex = cursor.getColumnIndex(ContactsContract.Contacts._ID)
                val nameIndex = cursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME)
                if (idIndex >= 0) contactId = cursor.getString(idIndex) ?: ""
                if (nameIndex >= 0) name = cursor.getString(nameIndex) ?: name
            }
        }

        var phoneNumber = ""
        if (contactId.isNotEmpty()) {
            resolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER),
                "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
                arrayOf(contactId),
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val phoneIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                    if (phoneIndex >= 0) phoneNumber = cursor.getString(phoneIndex) ?: ""
                }
            }
        }

        return mapOf("name" to name, "phoneNumber" to phoneNumber)
    }

    private fun queryOpenable(uri: Uri): OpenableInfo {
        var name = uri.lastPathSegment ?: "attachment"
        var size = 0L
        resolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (nameIndex >= 0) name = cursor.getString(nameIndex) ?: name
                if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
            }
        }
        return OpenableInfo(name, size)
    }

    private fun imageDimensions(uri: Uri): Pair<Int, Int> {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, options) }
        return options.outWidth.coerceAtLeast(0) to options.outHeight.coerceAtLeast(0)
    }

    private fun copyImageToCache(uri: Uri, mimeType: String): File {
        val extension = when (mimeType) {
            "image/png" -> "png"
            "image/webp" -> "webp"
            else -> "jpg"
        }
        return copyToCache(uri, "image.$extension", "afapay_image")
    }

    private fun copyToCache(uri: Uri, displayName: String, prefix: String): File {
        val extension = displayName.substringAfterLast('.', "").ifEmpty { "bin" }
        val output = File(activity.cacheDir, "${prefix}_${System.currentTimeMillis()}.$extension")
        resolver.openInputStream(uri)?.use { input ->
            FileOutputStream(output).use { outputStream -> input.copyTo(outputStream) }
        } ?: throw IllegalArgumentException("Unable to open selected file.")
        return output
    }

    private fun inferImageMimeType(name: String): String {
        return when (name.substringAfterLast('.', "").lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "webp" -> "image/webp"
            else -> "application/octet-stream"
        }
    }

    private fun fail(result: MethodChannel.Result, code: String, message: String) {
        _attachmentStateFlow.value = NativeAttachmentState.Failed(message)
        result.error(code, message, null)
    }

    data class OpenableInfo(val name: String, val size: Long)

    companion object {
        const val CHANNEL_NAME = "afapay/attachments"
    }
}
