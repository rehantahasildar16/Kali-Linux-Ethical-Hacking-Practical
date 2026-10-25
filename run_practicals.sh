#!/usr/bin/env bash
# Ethical Hacking Practical Runner — menu mode
# Runs local/benign demonstrations and read-only checks only.
# Use only on your own Kali Linux machine or an authorized lab.

set -u

OUT_DIR="$HOME/ethical_hacking_practical_results"
mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG="$OUT_DIR/session_$STAMP.log"

run_cmd() {
    echo
    echo ">>> $*"
    echo ">>> $*" >> "$LOG"
    "$@" 2>&1 | tee -a "$LOG"
    local status=${PIPESTATUS[0]}
    echo "[exit status: $status]" | tee -a "$LOG"
}

pause() {
    echo
    read -r -p "Press Enter to return to the menu..." _
}

check_tools() {
    local tools=(ping traceroute nslookup host dig whois curl openssl nmap searchsploit sqlite3 gcc ip ss iptables lsof)
    echo "Tool availability:"
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf "[AVAILABLE] %s\n" "$tool"
        else
            printf "[NOT FOUND] %s\n" "$tool"
        fi
    done
    pause
}

practical_1() {
    echo "Practical 1: Reconnaissance (public-domain examples)"
    run_cmd ping -c 4 google.com
    run_cmd traceroute -m 12 google.com
    run_cmd nslookup google.com
    run_cmd host google.com
    run_cmd dig google.com
    run_cmd whois google.com
    run_cmd curl -I --max-time 10 https://google.com
    echo "TLS details (may take a moment):"
    if command -v timeout >/dev/null 2>&1; then
        timeout 10 openssl s_client -connect google.com:443 -brief </dev/null 2>&1 | tee -a "$LOG" || true
    else
        echo "timeout command not found; TLS check skipped."
    fi
    pause
}

practical_2() {
    echo "Practical 2: Local network/system monitoring (non-flooding)"
    run_cmd ping -c 3 127.0.0.1
    run_cmd ss -lnt
    run_cmd ss -tan
    run_cmd ss -s
    run_cmd ip -s link
    if [[ -r /proc/net/tcp ]]; then run_cmd cat /proc/net/tcp; fi
    run_cmd ps aux
    if command -v iptables >/dev/null 2>&1; then
        echo "Firewall rules (sudo may prompt for password):"
        sudo iptables -L -n 2>&1 | tee -a "$LOG" || true
    fi
    pause
}

practical_3() {
    echo "Practical 3: Vulnerability research — authorized scan target only"
    echo "This menu uses Nmap's explicitly provided public test host scanme.nmap.org."
    echo "Only continue if you accept the host's published scanning policy."
    read -r -p "Continue with basic/version detection against scanme.nmap.org? (y/N): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        run_cmd nmap scanme.nmap.org
        run_cmd nmap -sV scanme.nmap.org
    else
        echo "Skipped target scanning."
    fi
    echo "SearchSploit lookups are local database searches:"
    if command -v searchsploit >/dev/null 2>&1; then
        run_cmd searchsploit "Apache 2.4.41"
        run_cmd searchsploit CVE-2021-41773
    else
        echo "searchsploit is not installed; skipped."
    fi
    pause
}

practical_4() {
    echo "Practical 4: SQL injection concepts in a temporary local SQLite database"
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "sqlite3 is not installed."
        pause
        return
    fi
    local db
    db="$(mktemp "$OUT_DIR/sqlite_lab_XXXXXX.db")"
    echo "Temporary database: $db"
    sqlite3 "$db" "CREATE TABLE users(id INTEGER, username TEXT, password TEXT);"
    sqlite3 "$db" "INSERT INTO users VALUES(1,'admin','demo123'),(2,'student','demo456');"
    echo "--- Normal query ---"
    sqlite3 "$db" "SELECT id, username FROM users WHERE username='admin';" | tee -a "$LOG"
    echo "--- Always-true condition demo (local toy data only) ---"
    sqlite3 "$db" "SELECT id, username FROM users WHERE username='' OR '1'='1';" | tee -a "$LOG"
    echo "--- Parameterized query concept (placeholder is explained, not executed without binding) ---"
    echo "In an application, bind the username value separately to a prepared statement."
    chmod 600 "$db"
    echo "Lab database retained at $db for inspection; delete it yourself when finished."
    pause
}

practical_5() {
    echo "Practical 5: DNS record types"
    run_cmd nslookup -type=A google.com
    run_cmd nslookup -type=NS google.com
    run_cmd nslookup -type=MX google.com
    run_cmd nslookup -type=TXT google.com
    run_cmd nslookup -type=CNAME google.com
    pause
}

practical_6() {
    echo "Practical 6: Social engineering awareness — harmless local simulation"
    local bait="$OUT_DIR/bait_demo.txt"
    printf '%s\n' 'FreeGift-ClickHere' > "$bait"
    echo "--- Sample text ---"
    run_cmd cat "$bait"
    echo "--- Search suspicious words (extended regex) ---"
    grep -E -i 'free|gift|click' "$bait" | tee -a "$LOG" || true
    run_cmd file "$bait"
    run_cmd stat "$bait"
    run_cmd sha256sum "$bait"
    echo "--- Simulated phishing warning text (display only) ---"
    echo 'URGENT: Verify your account immediately!' | tee -a "$LOG"
    echo "No messages are sent and no real accounts or websites are contacted."
    pause
}

practical_7() {
    echo "Practical 7: Local buffer-overflow prevention concepts"
    if ! command -v gcc >/dev/null 2>&1; then
        echo "gcc is not installed."
        pause
        return
    fi
    local src="$OUT_DIR/overflow_demo.c"
    local bin="$OUT_DIR/overflow_demo"
    cat > "$src" <<'EOF'
#include <stdio.h>
#include <string.h>

int main(void) {
    char input[128];
    char buffer[8];
    if (!fgets(input, sizeof(input), stdin)) return 1;
    input[strcspn(input, "\n")] = '\0';
    snprintf(buffer, sizeof(buffer), "%s", input);
    printf("Safely stored (truncated if needed): %s\n", buffer);
    return 0;
}
EOF
    echo "Compiling a SAFE example using snprintf (no intentional overflow)."
    gcc -Wall -Wextra -fstack-protector-strong -o "$bin" "$src" 2>&1 | tee -a "$LOG"
    if [[ -x "$bin" ]]; then
        echo "Enter sample text below and press Enter:"
        "$bin" 2>&1 | tee -a "$LOG"
    fi
    echo "Source saved at: $src"
    pause
}

while true; do
    clear 2>/dev/null || true
    echo "=============================================="
    echo " ETHICAL HACKING PRACTICAL RUNNER (MENU MODE)"
    echo "=============================================="
    echo "1) Reconnaissance and information gathering"
    echo "2) DoS concepts: local network/system monitoring"
    echo "3) Vulnerability research (authorized test host)"
    echo "4) SQL injection concepts (local SQLite lab)"
    echo "5) DNS enumeration and record types"
    echo "6) Phishing/baiting awareness simulation"
    echo "7) Buffer overflow prevention (safe C demo)"
    echo "8) Check required tools"
    echo "0) Exit"
    echo
    read -r -p "Select practical number: " choice
    case "$choice" in
        1) practical_1 ;;
        2) practical_2 ;;
        3) practical_3 ;;
        4) practical_4 ;;
        5) practical_5 ;;
        6) practical_6 ;;
        7) practical_7 ;;
        8) check_tools ;;
        0) echo "Results saved in: $OUT_DIR"; exit 0 ;;
        *) echo "Invalid choice."; sleep 1 ;;
    esac
done
