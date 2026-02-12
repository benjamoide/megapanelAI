@echo off
echo Deploying v1.0.1+38...
git add .
git commit -m "v1.0.1+38 fix: force 2-byte pulse payload"
git push origin main
echo Deployment checks completed.
pause
