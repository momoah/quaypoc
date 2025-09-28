Quay Proof of Concept - Containerised
=====================================

This document runs a proof of concept Quay registry using minimal configuration and setup.

Steps:
------
1- Setup your directory structure the way you want. This guide uses /data/quayroot.
2- Create self signed certificates (or proper ones) in /data/quayroot/config/ (ssl.cert, ssl.key)
3- Copy config.yaml to /data/quayroot/config/
4- Run setup_quay.sh (which sets up all the directories, ensure you use the correct quayroot)

