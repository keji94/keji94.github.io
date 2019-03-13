#!/bin/bash
set -ev

# get clone master
git clone https://${GH_REF} .deploy_git
cd .deploy_git
git checkout master

cd ../
mv .deploy_git/.git/ ./public/

cd ./public

git config user.name "keji"
git config user.email "798631828@qq.com"

# add commit timestamp
git add .
git commit -m "Travis CI Auto Builder at `date +"%Y-%m-%d %H:%M"`"

# Github Pages
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:master

cd ../

./ossutil64 config -e oss-cn-beijing.aliyuncs.com -i LTAILxlNnWg41hEp -k tkudYbKYLHivTLU59nCOUKMgXZDzx6

./ossutil64 cp public oss://oss://keji-image// -r -f
