@echo off
echo Deploying v1.0.1+32...
git add .
git commit -m "v1.0.1+32 fix: spread brightness mapping"
git push origin main
echo Deployment checks completed.
pause
