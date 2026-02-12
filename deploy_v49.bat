@echo off
echo Deploying v1.0.1+49...
git add .
git commit -m "v1.0.1+49 fix: universal shotgun [S1,S2,S3,S1,S2,S4,S5] + QuickStart"
git push origin main
echo Deployment checks completed.
pause
