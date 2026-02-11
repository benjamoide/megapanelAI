@echo off
echo Deploying v1.0.1+37...
git add .
git commit -m "v1.0.1+37 fix: restore v35 mapping [S1,S2,S3,0,0,S4,S5]"
git push origin main
echo Deployment checks completed.
pause
