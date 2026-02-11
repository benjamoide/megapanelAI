@echo off
echo Deploying v1.0.1+36...
git add .
git commit -m "v1.0.1+36 fix: correct brightness mapping [S1,0,0,S2,S3,S4,S5]"
git push origin main
echo Deployment checks completed.
pause
