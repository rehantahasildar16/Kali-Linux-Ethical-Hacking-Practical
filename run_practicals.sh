#!/usr/bin/env bash
# Ethical Hacking practical menu matched to the handwritten question list
# and the supplied "ethical hacking practical" PDF.
# Only run tests on your own system or with explicit authorization.

set -u
OUT="$HOME/ethical_hacking_practical_results"
mkdir -p "$OUT" || { echo "Cannot create $OUT"; exit 1; }
LOG="$OUT/session_$(date +%Y%m%d_%H%M%S).log"
touch "$LOG" || { echo "Cannot create log file"; exit 1; }

has(){ command -v "$1" >/dev/null 2>&1; }
pause(){ echo; read -r -p "Press Enter to return to menu..." _ || true; }
run(){
  echo
  printf '$'; printf ' %q' "$@"; echo
  printf '\\n$' >> "$LOG"; printf ' %q' "$@" >> "$LOG"; printf '\\n' >> "$LOG"
  "$@" 2>&1 | tee -a "$LOG"
  local rc=${PIPESTATUS[0]}
  echo "[exit status: $rc]" | tee -a "$LOG"
  return 0
}
heading(){
  clear 2>/dev/null || true
  echo "=========================================================="
  echo " ETHICAL HACKING PRACTICALS — QUESTION-WISE MENU"
  echo "=========================================================="
  echo "Log file: $LOG"
  echo
}

q1(){
  heading
  echo "Q1. Passive and Active Reconnaissance / OSINT"
  echo "Source: PDF Practical No. 03 — commands preserved from PDF."
  run ping -c 4 google.com
  if has traceroute; then run traceroute google.com; else echo "traceroute is not installed; command skipped."; fi
  if has nslookup; then run nslookup google.com; else echo "nslookup is not installed; command skipped."; fi
  if has host; then run host google.com; else echo "host is not installed; command skipped."; fi
  if has dig; then run dig google.com; else echo "dig is not installed; command skipped."; fi
  if has whois; then run whois google.com; else echo "whois is not installed; command skipped."; fi
  run curl -I google.com
  echo
  echo "PDF command: openssl s_client -connect google.com:443"
  if has openssl; then
    if has timeout; then timeout 10 openssl s_client -connect google.com:443 -brief </dev/null 2>&1 | tee -a "$LOG" || true
    else openssl s_client -connect google.com:443 </dev/null 2>&1 | tee -a "$LOG" || true
    fi
  else echo "openssl is not installed; command skipped."; fi
  pause
}

q2(){
  heading
  echo "Q2. Types of DoS attack including SYN synchronization/flooding"
  echo "Source: PDF section 'Denial of Service and Botnet Architecture'."
  echo "This runs the PDF's local monitoring commands only; it does NOT launch a DoS attack."
  run ping -c 3 127.0.0.1
  if has ss; then
    run ss -lnt
    run ss -tan
    run ss -s
  else echo "ss is not installed; socket commands skipped."; fi
  if has ip; then run ip -s link; fi
  if [[ -r /proc/net/tcp ]]; then run cat /proc/net/tcp; fi
  run bash -c 'ps aux | head'
  if has iptables; then
    echo '$ sudo iptables -L -n'
    sudo iptables -L -n 2>&1 | tee -a "$LOG" || true
  else echo "iptables is not installed; firewall listing skipped."; fi
  echo
  echo "Viva note: SYN flooding abuses the TCP connection setup by sending many SYN requests."
  echo "Mitigations: SYN cookies, rate limiting, firewall/filtering, monitoring and DDoS protection."
  pause
}

q3(){
  heading
  echo "Q3. Vulnerability Research and Disclosure (PDF Practical No. 02)"
  echo "The PDF lists Nmap commands against scanme.nmap.org and SearchSploit lookups."
  echo "Only scan a host when you have authorization and have checked its current policy."
  if has nmap; then
    read -r -p "Run the basic Nmap checks against scanme.nmap.org? (y/N): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      run ping -c 4 scanme.nmap.org
      run nmap scanme.nmap.org
      run nmap -sV scanme.nmap.org
      echo
      echo "PDF also lists these more intrusive commands:"
      echo "  sudo nmap -O scanme.nmap.org"
      echo "  sudo nmap --script vuln scanme.nmap.org"
      echo "They are displayed for reference only and are NOT executed by this script."
    else echo "Network scans skipped."; fi
  else echo "nmap is not installed; scan commands skipped."; fi
  if has searchsploit; then
    run searchsploit "Apache 2.4.41"
    run searchsploit CVE-2021-41773
    echo "PDF command 'searchsploit -u' updates the local database; not run automatically."
  else echo "searchsploit is not installed; SearchSploit commands skipped."; fi
  pause
}

q4(){
  heading
  echo "Q4. SQL Injection — PDF Practical 4"
  echo "Runs the PDF's SQLite examples only against a local practice database."
  if ! has sqlite3; then
    echo "sqlite3 is missing. In Kali, install it with: sudo apt install sqlite3"
    pause; return
  fi
  db="$OUT/test.db"
  if [[ -e "$db" ]]; then
    echo "Existing $db found. To avoid overwriting it, choose another practice folder or move the file first."
    pause; return
  fi
  run sqlite3 "$db" "CREATE TABLE users(id INTEGER, username TEXT, password TEXT);"
  run sqlite3 "$db" "INSERT INTO users VALUES(1,'admin','1234'),(2,'student','5678');"
  run sqlite3 "$db" "SELECT * FROM users WHERE username='admin';"
  run sqlite3 "$db" "SELECT * FROM users WHERE username='' OR '1'='1';"
  run sqlite3 "$db" "SELECT * FROM users WHERE username='admin'--';"
  run sqlite3 "$db" "SELECT * FROM users WHERE username='admin' AND password='wrong';"
  run sqlite3 "$db" "SELECT username FROM users UNION SELECT password FROM users;"
  run sqlite3 "$db" "PRAGMA table_info(users);"
  run sqlite3 "$db" "SELECT * FROM users WHERE username='admin' AND length(username)<=20;"
  echo
  echo "PDF parameterized query example: SELECT * FROM users WHERE username=?;"
  echo "Use prepared statements and bind parameters in real applications."
  run chmod 600 "$db"
  echo "Database kept at: $db"
  echo "After practice, delete it with: rm -f '$db'"
  pause
}

q5(){
  heading
  echo "Q5. DNS Structure and Record Types — PDF Practical No. 04"
  if ! has nslookup; then echo "nslookup is not installed; DNS commands skipped."; pause; return; fi
  run nslookup -type=A google.com
  run nslookup -type=NS google.com
  run nslookup -type=MX google.com
  run nslookup -type=TXT google.com
  run nslookup -type=CNAME google.com
  if has whois; then run whois google.com; fi
  pause
}

q6(){
  heading
  echo "Q6. Types of DoS Attack"
  echo "This is the same DoS topic as Q2 in the handwritten list."
  echo "PDF commands below are local monitoring commands only; no attack traffic is generated."
  run ping -c 3 127.0.0.1
  if has ss; then run ss -lnt; run ss -tan; run ss -s; fi
  if has ip; then run ip -s link; fi
  [[ -r /proc/net/tcp ]] && run cat /proc/net/tcp
  run bash -c 'ps aux | head'
  if has iptables; then sudo iptables -L -n 2>&1 | tee -a "$LOG" || true; fi
  echo
  echo "Types mentioned for viva: DoS, DDoS, SYN flooding and Smurf attack."
  echo "Botnet: a group of compromised devices controlled together."
  echo "Mitigation: filtering, rate limits, firewall rules, monitoring and DDoS protection."
  pause
}

q7(){
  heading
  echo "Q7. Phishing and Baiting — PDF Practical No. 05"
  work="$OUT/bait.txt"
  echo "1. Create bait.txt with the PDF's sample text."
  printf '%s\n' 'FreeGift-ClickHere' > "$work"
  echo "2. cat bait.txt"; run cat "$work"
  echo "3. grep -i 'free|gift|click' bait.txt (literal basic grep, as in PDF)"
  grep -i 'free|gift|click' "$work" 2>&1 | tee -a "$LOG" || true
  echo "For matching any of those words, the PDF's later grep -Ei example is used below:"
  grep -Ei 'free|gift|click' "$work" 2>&1 | tee -a "$LOG" || true
  has file && run file "$work"
  has stat && run stat "$work"
  has sha256sum && run sha256sum "$work"
  echo "curl -I https://example.com (safe header check):"
  run curl -I --max-time 10 https://example.com
  echo 'URGENT: Verify your account immediately!' | tee -a "$LOG"
  echo
  echo "PDF practical5 folder/file commands:"
  mkdir -p "$OUT/practical5"
  touch "$OUT/practical5/prac5.txt"
  printf 'Currently|iamdoing|practical5\n' > "$OUT/practical5/prac5.txt"
  run cat "$OUT/practical5/prac5.txt"
  grep -i 'currently|iamdoing|practical5' "$OUT/practical5/prac5.txt" 2>&1 | tee -a "$LOG" || true
  grep -Ei 'currently|iamdoing|practical5' "$OUT/practical5/prac5.txt" 2>&1 | tee -a "$LOG" || true
  has file && run file "$OUT/practical5/prac5.txt"
  has stat && run stat "$OUT/practical5/prac5.txt"
  has sha256sum && run sha256sum "$OUT/practical5/prac5.txt"
  echo "No messages are sent and no real login pages are opened."
  pause
}

q8(){
  heading
  echo "Q8. The handwritten image does not show a readable question for number 8."
  echo "I have not invented a practical for this slot. Please check the teacher's question sheet."
  pause
}

tools(){
  heading
  for t in ping traceroute nslookup host dig whois curl openssl nmap searchsploit sqlite3 ip ss iptables file stat sha256sum timeout; do
    has "$t" && echo "[AVAILABLE] $t" || echo "[MISSING] $t"
  done
  pause
}

while true; do
  heading
  echo "1) Passive and Active Reconnaissance / OSINT"
  echo "2) DoS attack types including SYN flooding — monitoring demo"
  echo "3) Vulnerability Research (PDF Practical 02)"
  echo "4) SQL Injection (PDF Practical 4)"
  echo "5) DNS structure and record types (PDF Practical 04)"
  echo "6) Types of DoS attack (repeated question)"
  echo "7) Phishing and Baiting (PDF Practical 05)"
  echo "8) Unclear in handwritten question image"
  echo "9) Check installed commands/tools"
  echo "0) Exit"
  read -r -p "Select question/practical: " choice || exit 0
  case "$choice" in
    1) q1;; 2) q2;; 3) q3;; 4) q4;; 5) q5;; 6) q6;; 7) q7;; 8) q8;; 9) tools;; 0) echo "Logs saved in $OUT"; exit 0;; *) echo "Invalid option."; sleep 1;;
  esac
done
