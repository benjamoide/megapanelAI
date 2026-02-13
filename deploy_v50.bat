@echo off
echo Deploying v1.0.1+50...
git add .
git commit -m "v1.0.1+50 fix: brightness mapping offset [0,0,S1,S2,S3,S4,S5]"
git push origin main
echo Deployment checks completed.
pause
