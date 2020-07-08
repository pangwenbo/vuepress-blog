@echo off

echo building...
call build.bat
echo building-complete.

git init
git add -A
git commit -m 'auto-deploy'
git remote add origin git@github.com:pangwenbo/vuepress-blog.git
git pull
git push --force origin HEAD:gh-pages

echo Auto-Deploy-Complete!
pause