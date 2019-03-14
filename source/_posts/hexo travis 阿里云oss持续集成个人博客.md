title: hexo+travis+阿里云oss持续集成个人博客
author: keji
date: 2019-03-11 19:41:29
---
这两天抽空用hexo搭建了一个静态博客，并且使用travis+github pages做持续集成。后来对github pages的响应速度不是很满意，便将博客换成了hexo+travis+oss。

实现的效果是只需要提交代码，便自动将博客更新到github pages 和oss上面。

使用hexo+travis+github pages 完成持续部署的过程不在赘述，网上有很多教程，不过质量参差不齐，这里推荐一篇：
[使用Travis CI自动部署Hexo博客](https://www.itfanr.cc/2017/08/09/using-travis-ci-automatic-deploy-hexo-blogs/)
<!-- more -->

按照这篇文章操作，应该就可以实现hexo+travis+github pages持续集成。我在这个基础上，增加了对oss的持续集成。

有关oss如何部署静态页面，参考[如何将 hexo 生成的博客部署至阿里云 OSS 并全站启用 CDN 加速访问](https://juejin.im/post/5afba05b6fb9a07aa2138699)

值得一提的是，如果需要将oss绑定到域名，需要备案。

接下来需要做的是在push代码的时候，将构建出来的静态文件上传到oss中。这里我使用的是阿里云oss提供的工具类：
[命令行工具ossutil](https://help.aliyun.com/document_detail/50452.html?spm=a2c4g.11186623.6.1355.73af58d518E5T7)

首先将ossutil下载，放到hexo源码根目录:
![](/images/ossutil.png)



在上传只github pages的基础上，增加以下代码:
```

# 进入根目录
cd ../
# 开启权限
chmod 755 ossutil64
# 配置endpoint，id 秘钥
./ossutil64 config -e <your oss endpoint> -i <your AccessKey ID> -k <your Access Key Secret>
# 先删除所有文件，防止出现文件改名后不能覆盖的问题
./ossutil64 rm oss://keji-blog-hexo -r -f
# 上传public文件至oss
./ossutil64 cp public oss://keji-blog-hexo/ -r -f --loglevel=debug

```

这样，便可以了。






