package com.example.firetvhome;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

public final class HomeActivity extends Activity {
    private static final String TARGET_PACKAGE = "me.efesser.flauncher";

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        launchTarget();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        launchTarget();
    }

    private void launchTarget() {
        Intent target = getPackageManager().getLeanbackLaunchIntentForPackage(TARGET_PACKAGE);
        if (target == null) {
            target = getPackageManager().getLaunchIntentForPackage(TARGET_PACKAGE);
        }
        if (target != null) {
            target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
            startActivity(target);
        }
        finish();
    }
}
