#!/bin/sh
# Install the aur-audit pacman hook. Run with: sudo ./install.sh
set -e
cd "$(dirname "$0")"
install -Dm755 aur-audit /usr/local/bin/aur-audit
install -Dm755 aur-audit-makepkg /usr/local/bin/aur-audit-makepkg
install -Dm644 01-aur-audit.hook /etc/pacman.d/hooks/01-aur-audit.hook
if [ ! -f /etc/aur-audit/allowlist ]; then
    install -Dm644 /dev/null /etc/aur-audit/allowlist
    cat > /etc/aur-audit/allowlist <<'LIST'
# Packages you have reviewed and trust despite BLOCK findings.
# One per line: <pkgname> <version>   (only that exact version is allowed,
# so every update gets audited again)
LIST
fi
echo "aur-audit installed. Uninstall with (and turn off the yay wrapper: yay -Y --makepkg makepkg --save):"
echo "  sudo rm /usr/local/bin/aur-audit /usr/local/bin/aur-audit-makepkg /etc/pacman.d/hooks/01-aur-audit.hook"
echo
echo "To audit AUR packages before yay builds them or asks to import keys, run (as yourself, not root):"
echo "  yay -Y --makepkg /usr/local/bin/aur-audit-makepkg --save"
