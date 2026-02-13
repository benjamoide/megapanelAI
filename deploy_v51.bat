@echo off
echo Deploying v1.0.1+51...
git add .
git commit -m "v1.0.1+51 fix: remove stop() and change padding 0->1"
git push origin main
echo Deployment checks completed.
pause
