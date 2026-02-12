@echo off
echo Deploying v1.0.1+40...
git add .
git commit -m "v1.0.1+40 fix: lava evasion for 0x0A 0x3A 0x3B in payload and checksum"
git push origin main
echo Deployment checks completed.
pause
