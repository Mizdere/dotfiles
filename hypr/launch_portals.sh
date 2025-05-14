#!/bin/bash
sleep 2
killall -q xdg-desktop-portal-hyprland
killall -q xdg-desktop-portal
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
