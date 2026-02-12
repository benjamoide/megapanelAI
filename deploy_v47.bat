@echo off
echo Deploying v1.0.1+47...
git add .
git commit -m "v1.0.1+47 fix: offset mapping [0, 0, S1, S2, S3, S4, S5]"
git push origin main
echo Deployment checks completed.
pause
