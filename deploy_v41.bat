@echo off
echo Deploying v1.0.1+41...
git add .
git commit -m "v1.0.1+41 fix: shotgun mapping + lava protocol"
git push origin main
echo Deployment checks completed.
pause
