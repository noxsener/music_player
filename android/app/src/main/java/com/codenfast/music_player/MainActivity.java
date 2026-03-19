package com.codenfast.music_player;

import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.codenfast.music_player/intent";

    private String pendingUri = null;
    private MethodChannel methodChannel = null;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        methodChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        );

        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {

                // Flutter calls this on startup to get the launch URI
                case "getInitialUri": {
                    result.success(pendingUri);
                    pendingUri = null;
                    break;
                }

                // Flutter calls this to copy a content:// URI to the
                // app cache so audioplayers / media_kit can open it
                case "copyContentUri": {
                    String uriString = call.argument("uri");
                    if (uriString == null) {
                        result.error("NULL_URI", "URI argument was null", null);
                        return;
                    }
                    try {
                        String cachedPath = copyUriToCache(Uri.parse(uriString));
                        result.success(cachedPath);
                    } catch (Exception e) {
                        result.error("COPY_FAILED", e.getMessage(), null);
                    }
                    break;
                }

                default:
                    result.notImplemented();
            }
        });

        // Capture URI from the intent that launched this activity
        extractUriFromIntent(getIntent());
    }

    // Called when the app is already running and a new intent arrives
    // (e.g. user taps another file while app is in the background)
    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        String uri = extractUriFromIntent(intent);
        if (uri != null && methodChannel != null) {
            methodChannel.invokeMethod("onNewUri", uri);
        }
    }

    /**
     * Reads the ACTION_VIEW URI from an intent and stores it in pendingUri.
     * Returns the URI string, or null if the intent is not ACTION_VIEW.
     */
    private String extractUriFromIntent(Intent intent) {
        if (intent == null) return null;
        if (!Intent.ACTION_VIEW.equals(intent.getAction())) return null;
        Uri data = intent.getData();
        if (data == null) return null;
        pendingUri = data.toString();
        return pendingUri;
    }

    /**
     * Copies a content:// URI to the app's cache directory.
     * Returns the absolute path of the cached file.
     *
     * audioplayers and media_kit cannot open content:// URIs directly —
     * they need a real file path. This copies the bytes once to cache.
     */
    private String copyUriToCache(Uri uri) throws Exception {
        // Try to get the original display name
        String fileName = "media_" + System.currentTimeMillis();
        Cursor cursor = getContentResolver().query(uri, null, null, null, null);
        if (cursor != null) {
            try {
                int nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                if (cursor.moveToFirst() && nameIndex >= 0) {
                    fileName = cursor.getString(nameIndex);
                }
            } finally {
                cursor.close();
            }
        }

        File cacheFile = new File(getCacheDir(), fileName);

        InputStream input = getContentResolver().openInputStream(uri);
        if (input == null) {
            throw new Exception("Could not open input stream for: " + uri);
        }

        try (FileOutputStream output = new FileOutputStream(cacheFile)) {
            byte[] buffer = new byte[8192];
            int len;
            while ((len = input.read(buffer)) != -1) {
                output.write(buffer, 0, len);
            }
        } finally {
            input.close();
        }

        return cacheFile.getAbsolutePath();
    }
}