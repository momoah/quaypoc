Quay Proof of Concept - Containerised
=====================================

This document runs a proof of concept Quay registry using minimal configuration and setup.

Steps:
------
* Setup your directory structure the way you want. This guide uses /data/quayroot.
* Create self signed certificates (or proper ones) in /data/quayroot/config/ (ssl.cert, ssl.key)
* Copy config.yaml to /data/quayroot/config/
* Run setup_quay.sh (which sets up all the directories, ensure you use the correct quayroot)

Added: run_quay_3.15.2.sh which replaces the need for systemd 

Before running, make sure you see:
```bash
# ls /data/quayroot/config
ssl.cert  ssl.key
```

