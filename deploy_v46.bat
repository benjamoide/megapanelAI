@echo off
echo Deploying v1.0.1+46...
git add .
git commit -m "v1.0.1+46 fix: shotgun mapping [S1..S5] with brightness first"
git push origin main
echo Deployment checks completed.
pause
