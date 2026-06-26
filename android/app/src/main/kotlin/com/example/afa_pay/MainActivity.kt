package com.example.afa_pay

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var attachmentPickerManager: AttachmentPickerManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val manager = AttachmentPickerManager(this)
        attachmentPickerManager = manager
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AttachmentPickerManager.CHANNEL_NAME,
        ).setMethodCallHandler(manager)
    }
}
