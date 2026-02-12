@echo off
echo Deploying v1.0.1+48...
git add .
git commit -m "v1.0.1+48 fix: linear mapping + quick start 0x21"
git push origin main
echo Deployment checks completed.
pause
