@echo off
echo Deploying v1.0.1+39...
git add .
git commit -m "v1.0.1+39 fix: sanitize payload 0x0A->0x0B"
git push origin main
echo Deployment checks completed.
pause
