# 20px traffic lights for Qt apps, matching the GTK theme.
# Upstream draws the circle at a fixed 16px, 4px away from its click area.
s/ceButtonWidth = 16;/ceButtonWidth = 20;/
s/ceButtonMarginLeft = 10;/ceButtonMarginLeft = 14;/
s/ceButtonMarginBottom = 4;/ceButtonMarginBottom = 0;/
s/setSize(QSize(16, 16))/setSize(QSize(ceButtonWidth, ceButtonWidth))/
/adjustedBtnRect.translate(4, 4);/d
