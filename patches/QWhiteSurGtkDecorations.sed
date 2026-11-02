# 20px traffic lights for Qt apps, matching the GTK theme.
# Upstream draws the circle at a fixed 16px, 4px away from its click area.
s/ceButtonWidth = 16;/ceButtonWidth = 20;/
s/ceButtonMarginLeft = 10;/ceButtonMarginLeft = 14;/
# 28px between button centres, like GTK (20px button + 1px margins + 6px spacing).
s/ceButtonSpacing = 6;/ceButtonSpacing = 8;/
s/ceButtonMarginBottom = 4;/ceButtonMarginBottom = 0;/
s/setSize(QSize(16, 16))/setSize(QSize(ceButtonWidth, ceButtonWidth))/
/adjustedBtnRect.translate(4, 4);/d
# Dark title bars in the wallpaper's navy, matching the GTK title bar.
s/QColor(0x2e2e32)/QColor(0x202f46)/g
s/QColor(0x222226)/QColor(0x162132)/
