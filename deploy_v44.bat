@echo off
echo Deploying v1.0.1+44...
git add .
git commit -m "v1.0.1+44 fix: restore v37 mapping [S1..S3, 0, 0, S4, S5] and Standard seq"
git push origin main
echo Deployment checks completed.
pause
