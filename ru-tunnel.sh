#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash ru-tunnel.sh"
    exit 1
fi

OS="$(uname -s)"
case "$OS" in
    Darwin) OS_NAME="macOS" ;;
    Linux)  OS_NAME="Linux" ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

if [ "$OS_NAME" = "macOS" ]; then
    GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway/ {print $2}')
else
    GATEWAY=$(ip route | awk '/default/ {print $3; exit}')
fi

echo ""
echo "Detected gateway: $GATEWAY"
echo "If this is wrong, type the correct one. Otherwise press Enter."
echo ""
read -p "Gateway [$GATEWAY]: " CONFIRM
if [ -n "$CONFIRM" ]; then
    GATEWAY=$CONFIRM
fi

echo ""
read -p "Install routes? [Y/N]: " CHOICE
if [[ ! "$CHOICE" =~ ^[Yy]$ ]]; then
    exit 0
fi

echo ""
echo "Downloading..."
echo ""

TMPFILE=$(mktemp)
curl -s https://www.ipdeny.com/ipblocks/data/countries/ru.zone -o "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
    echo "Failed to download IP list. Check your internet connection."
    rm -f "$TMPFILE"
    exit 1
fi

TOTAL=$(wc -l < "$TMPFILE")
COUNT=0

while IFS= read -r range; do
    [ -z "$range" ] && continue
    COUNT=$((COUNT + 1))
    printf "\rProgress: %d / %d" "$COUNT" "$TOTAL"

    if [ "$OS_NAME" = "macOS" ]; then
        route -q delete -net "$range" 2>/dev/null
        route -q add -net "$range" "$GATEWAY" 2>/dev/null
    else
        ip route delete "$range" 2>/dev/null
        ip route add "$range" via "$GATEWAY" 2>/dev/null
    fi
done < "$TMPFILE"

rm -f "$TMPFILE"

echo ""
echo ""
echo "Done."
echo ""

if [ "$OS_NAME" = "macOS" ]; then
    read -p "Set up autostart on boot? [Y/N]: " AUTOSTART
    if [[ "$AUTOSTART" =~ ^[Yy]$ ]]; then
        SCRIPT_PATH="/usr/local/bin/ru-tunnel-startup.sh"
        cat > "$SCRIPT_PATH" << STARTUP
#!/bin/bash
sleep 15
gateway="$GATEWAY"
curl -s https://www.ipdeny.com/ipblocks/data/countries/ru.zone | while read range; do
    route -q delete -net "\$range" 2>/dev/null
    route -q add -net "\$range" "\$gateway" 2>/dev/null
done
STARTUP
        chmod +x "$SCRIPT_PATH"
        cat > /Library/LaunchDaemons/com.ru.tunnel.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ru.tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
        launchctl load /Library/LaunchDaemons/com.ru.tunnel.plist 2>/dev/null
        echo "Autostart configured."
    fi
fi
