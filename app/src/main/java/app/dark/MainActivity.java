package app.dark;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

/**
 * dark —— 打开后只做一件事：显示纯黑。
 *
 * 纯黑窗口 + 沉浸式全屏（隐藏状态栏/导航栏）+ 屏幕亮度锁 0 + 保持常亮。
 * 在 OLED 屏幕上，纯黑像素点不发光；在 LCD 上则把背光压到最低。
 */
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Window window = getWindow();

        // 1. 窗口背景直接设为纯黑（在任何内容绘制之前）
        window.setBackgroundDrawable(new ColorDrawable(Color.BLACK));

        // 2. 亮度压到最低：OLED 上黑像素本身不发光，LCD 上背光降到最低
        WindowManager.LayoutParams params = window.getAttributes();
        params.screenBrightness = 0f;
        window.setAttributes(params);

        // 3. 一个纯黑 View 铺满全屏
        View black = new View(this);
        black.setBackgroundColor(Color.BLACK);
        setContentView(black);

        // 4. 保持屏幕常亮，持续显示黑屏（而不是息屏）
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        // 5. 沉浸式全屏：隐藏系统栏，边缘滑动可临时唤出
        hideSystemBars();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            hideSystemBars();
        }
    }

    private void hideSystemBars() {
        Window window = getWindow();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false);
            WindowInsetsController controller = window.getInsetsController();
            if (controller != null) {
                controller.hide(WindowInsets.Type.systemBars());
                controller.setSystemBarsBehavior(
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            View decorView = window.getDecorView();
            decorView.setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }
}
