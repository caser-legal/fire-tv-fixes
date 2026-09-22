package com.example.firetvhome;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public final class BootReceiver extends BroadcastReceiver {
    private static final String TARGET_PACKAGE = "me.efesser.flauncher";

    @Override
    public void onReceive(Context context, Intent intent) {
        Intent target = context.getPackageManager().getLeanbackLaunchIntentForPackage(TARGET_PACKAGE);
        if (target == null) {
            target = context.getPackageManager().getLaunchIntentForPackage(TARGET_PACKAGE);
        }
        if (target != null) {
            target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
            context.startActivity(target);
        }
    }
}
