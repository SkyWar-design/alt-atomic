if [ -n "$DISTROBOX_ENTER_PATH" ]; then
    echo "Switching to bash inside Distrobox..."
    stty sane 2>/dev/null || true
    exec /bin/bash --noprofile --norc
    exit 0
fi