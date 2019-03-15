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

# 进入根目录
cd ../
# 开启权限
chmod 755 ossutil64
# 配置endpoint，id 秘钥
./ossutil64 config -e oss-cn-beijing.aliyuncs.com -i LTAILxlNnWg41hEp -k tkudYbKYLHivTLU59nCOUKMgXZDzx6
# 先删除所有文件，防止出现文件改名后不能覆盖的问题
# ./ossutil64 rm oss://keji-blog-hexo -r -f
# 上传public文件至oss
./ossutil64 cp public oss://keji-blog-hexo/ -r -f --loglevel=debug
