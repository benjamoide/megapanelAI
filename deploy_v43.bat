@echo off
echo Deploying v1.0.1+43...
git add .
git commit -m "v1.0.1+43 fix: inverse sequence (Start->Params) for Mode 0"
git push origin main
echo Deployment checks completed.
pause
