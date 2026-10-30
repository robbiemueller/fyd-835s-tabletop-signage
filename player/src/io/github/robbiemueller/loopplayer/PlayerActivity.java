package io.github.robbiemueller.loopplayer;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.view.GestureDetector;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.VideoView;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

/**
 * Full-screen, control-free video loop for FYD-835S tabletop signs (and any old Android 5+ screen).
 *
 * Plays every video in /sdcard/Movies/loop/ in name order and loops forever (a single file
 * loops seamlessly inside the media player). Double-tap toggles the sound; holding a finger down for
 * 3 seconds closes the player. From a PC:
 *   adb shell am start -n io.github.robbiemueller.loopplayer/.PlayerActivity --ez reload true   rescan the folder
 *   adb shell am start -n io.github.robbiemueller.loopplayer/.PlayerActivity --ez mute true     (or false)
 */
public class PlayerActivity extends Activity {
    private static final long EXIT_HOLD_MS = 3000;
    // View.SYSTEM_UI_FLAG_* values, written out so this builds against any SDK level.
    private static final int IMMERSIVE = 0x00000100 | 0x00000200 | 0x00000400 | 0x00000002 | 0x00000004 | 0x00001000;

    private final Handler handler = new Handler();
    private VideoView video;
    private TextView notice;
    private MediaPlayer player;
    private List<File> playlist = new ArrayList<>();
    private int index;
    private boolean muted;
    private SharedPreferences prefs;
    private float downX, downY;

    private final Runnable exitAfterHold = new Runnable() {
        @Override
        public void run() {
            finish();
        }
    };
    private final Runnable hideNotice = new Runnable() {
        @Override
        public void run() {
            notice.setVisibility(View.GONE);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setVolumeControlStream(AudioManager.STREAM_MUSIC);
        prefs = getSharedPreferences("player", MODE_PRIVATE);
        muted = prefs.getBoolean("muted", false);

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);
        video = new VideoView(this);
        root.addView(video, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT, Gravity.CENTER));
        notice = new TextView(this);
        notice.setTextColor(Color.rgb(0xe8, 0xdc, 0xc2));
        notice.setBackgroundColor(Color.argb(0xc0, 0, 0, 0));
        notice.setTextSize(22);
        notice.setPadding(36, 20, 36, 20);
        notice.setVisibility(View.GONE);
        root.addView(notice, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER));
        setContentView(root);

        final GestureDetector gestures = new GestureDetector(this, new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onDoubleTap(MotionEvent e) {
                setMuted(!muted);
                showNotice(muted ? "Sound off" : "Sound on");
                return true;
            }
        });
        final int slop = ViewConfiguration.get(this).getScaledTouchSlop();
        root.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent e) {
                gestures.onTouchEvent(e);
                switch (e.getActionMasked()) {
                    case MotionEvent.ACTION_DOWN:
                        downX = e.getX();
                        downY = e.getY();
                        handler.postDelayed(exitAfterHold, EXIT_HOLD_MS);
                        break;
                    case MotionEvent.ACTION_MOVE:
                        if (Math.abs(e.getX() - downX) > slop || Math.abs(e.getY() - downY) > slop) {
                            handler.removeCallbacks(exitAfterHold);
                        }
                        break;
                    case MotionEvent.ACTION_UP:
                    case MotionEvent.ACTION_CANCEL:
                        handler.removeCallbacks(exitAfterHold);
                        break;
                }
                return true;
            }
        });

        video.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
            @Override
            public void onPrepared(MediaPlayer mp) {
                player = mp;
                mp.setLooping(playlist.size() == 1);
                applyVolume();
                video.start();
            }
        });
        video.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {
                playNext();
            }
        });
        video.setOnErrorListener(new MediaPlayer.OnErrorListener() {
            @Override
            public boolean onError(MediaPlayer mp, int what, int extra) {
                // Skip a file the decoder can't handle instead of showing a dialog.
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        playNext();
                    }
                }, 1000);
                return true;
            }
        });

        handleIntent(getIntent());
        loadAndPlay();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (handleIntent(intent)) loadAndPlay();
    }

    /** Applies PC-sent extras; returns true when the playlist should be reloaded. */
    private boolean handleIntent(Intent intent) {
        if (intent == null) return false;
        if (intent.hasExtra("mute")) setMuted(intent.getBooleanExtra("mute", false));
        return intent.getBooleanExtra("reload", false);
    }

    @Override
    protected void onResume() {
        super.onResume();
        hideSystemUi();
        if (!video.isPlaying() && !playlist.isEmpty()) video.start();
    }

    @Override
    protected void onPause() {
        super.onPause();
        handler.removeCallbacks(exitAfterHold);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideSystemUi();
    }

    private void hideSystemUi() {
        getWindow().getDecorView().setSystemUiVisibility(IMMERSIVE);
    }

    private void loadAndPlay() {
        File dir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "loop");
        File[] files = dir.listFiles();
        playlist = new ArrayList<>();
        if (files != null) {
            Arrays.sort(files);
            for (File f : files) {
                String name = f.getName().toLowerCase(Locale.US);
                if (f.isFile() && (name.endsWith(".mp4") || name.endsWith(".mkv") || name.endsWith(".webm"))) {
                    playlist.add(f);
                }
            }
        }
        if (playlist.isEmpty()) {
            video.stopPlayback();
            showNotice("No videos in\n" + dir.getPath());
            handler.removeCallbacks(hideNotice);
            return;
        }
        index = 0;
        playCurrent();
    }

    private void playNext() {
        if (playlist.isEmpty()) return;
        index = (index + 1) % playlist.size();
        playCurrent();
    }

    private void playCurrent() {
        video.setVideoURI(Uri.fromFile(playlist.get(index)));
    }

    private void setMuted(boolean value) {
        muted = value;
        prefs.edit().putBoolean("muted", muted).apply();
        applyVolume();
    }

    private void applyVolume() {
        if (player == null) return;
        try {
            float v = muted ? 0f : 1f;
            player.setVolume(v, v);
        } catch (IllegalStateException ignored) {
            // The player was released between files; the next onPrepared applies it.
        }
    }

    private void showNotice(String text) {
        notice.setText(text);
        notice.setVisibility(View.VISIBLE);
        handler.removeCallbacks(hideNotice);
        handler.postDelayed(hideNotice, 1500);
    }
}
