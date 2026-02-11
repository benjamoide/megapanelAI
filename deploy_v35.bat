@echo off
echo Deploying v1.0.1+35...
git add .
git commit -m "v1.0.1+35 fix: final brightness mapping"
git push origin main
echo Deployment checks completed.
pause
