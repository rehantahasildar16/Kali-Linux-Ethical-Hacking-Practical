# Kali Linux Ethical Hacking Practical Runner

A menu-based Bash script for educational cybersecurity demonstrations and read-only checks.

## Menu
1. Reconnaissance and information gathering
2. Local system/network monitoring (non-flooding)
3. Vulnerability research (optional scan of Nmap's public test host; follow its policy)
4. SQL injection concepts using a local SQLite demo
5. DNS record types
6. Phishing/baiting awareness simulation (local text only)
7. Buffer-overflow prevention concept using safe C string handling
8. Check required tools
0. Exit

## Run in Kali Linux
```bash
chmod +x run_practicals.sh
./run_practicals.sh
```

Logs are saved in `~/ethical_hacking_practical_results/`.

## Notes
Some options require tools such as `nmap`, `sqlite3`, or `gcc`; use option 8 to check availability. Internet access is needed for public DNS/website examples. Use only on your own system or an authorized lab. The script does not perform DoS/flooding or send phishing messages.

This educational helper may not cover every college practical exactly as specified in your instructor's PDF.
