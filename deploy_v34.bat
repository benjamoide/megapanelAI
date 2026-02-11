@echo off
echo Deploying v1.0.1+34...
git add .
git commit -m "v1.0.1+34 fix: shotgun brightness mapping"
git push origin main
echo Deployment checks completed.
pause
