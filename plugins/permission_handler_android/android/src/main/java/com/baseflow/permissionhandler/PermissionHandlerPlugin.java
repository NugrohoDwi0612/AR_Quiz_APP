package com.baseflow.permissionhandler;

import android.app.Activity;
import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Platform implementation of the permission_handler Flutter plugin. */
public final class PermissionHandlerPlugin implements FlutterPlugin, ActivityAware {

    private final PermissionManager permissionManager;
    private MethodChannel methodChannel;
    private ActivityPluginBinding pluginBinding;
    private MethodCallHandlerImpl methodCallHandler;

    public PermissionHandlerPlugin() {
        this.permissionManager = new PermissionManager();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        startListening(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        stopListening();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.pluginBinding = binding;
        startListeningToActivity(binding.getActivity());
        registerListeners();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        stopListeningToActivity();
        deregisterListeners();
        this.pluginBinding = null;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    private void startListening(Context context, BinaryMessenger messenger) {
        methodChannel = new MethodChannel(messenger, "flutter.baseflow.com/permissions/methods");
        methodCallHandler = new MethodCallHandlerImpl(
                context,
                new AppSettingsManager(),
                this.permissionManager,
                new ServiceManager()
        );
        methodChannel.setMethodCallHandler(methodCallHandler);
    }

    private void stopListening() {
        if (methodChannel != null) {
            methodChannel.setMethodCallHandler(null);
            methodChannel = null;
        }
        methodCallHandler = null;
    }

    private void startListeningToActivity(Activity activity) {
        if (methodCallHandler != null) {
            methodCallHandler.setActivity(activity);
        }
    }

    private void stopListeningToActivity() {
        if (methodCallHandler != null) {
            methodCallHandler.setActivity(null);
        }
    }

    private void registerListeners() {
        if (pluginBinding != null) {
            pluginBinding.addActivityResultListener(permissionManager);
            pluginBinding.addRequestPermissionsResultListener(permissionManager);
        }
    }

    private void deregisterListeners() {
        if (pluginBinding != null) {
            pluginBinding.removeActivityResultListener(permissionManager);
            pluginBinding.removeRequestPermissionsResultListener(permissionManager);
        }
    }
}
