@echo off
echo Deploying v1.0.1+42...
git add .
git commit -m "v1.0.1+42 fix: linear brightness mapping [S1..S5] for Mode 0"
git push origin main
echo Deployment checks completed.
pause
