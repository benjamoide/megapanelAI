@echo off
echo Deploying v1.0.1+45...
git add .
git commit -m "v1.0.1+45 fix: reorder commands Brightness -> Time -> Pulse"
git push origin main
echo Deployment checks completed.
pause
