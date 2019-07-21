最近在工作中使用Sharding-JDBC做了分库分表，目前项目已经上线并稳定运行，闲暇时于记录下使用过程以及踩过的坑，希望对准备使用Sharding-JDBC做分库分表的同学有些帮助。

# 业务背景

随着业务的发展，数据量也是爆炸式的增长，有的表结构数据量已经过亿，并且以每月几百万的量持续增长。已经到了必须分库分表的地步。正好我们的系统也要进行服务拆分，一个服务拆分为四个服务，于是一起将分库分表也做掉了。


# 技术选型

在决定分库分表之后，首先要做的便是技术选型，目前市面上用来分库分表的中间件有很多，比如Mycat、Sharding-JDBC、淘宝的TDDL（未开源）、平明软件的OneProxy（收费）、360的Atlas、Youtube的Vitess，还有最近比较流行的TiDB等等。

在选择中间件之前，首先得了解分库分表中间件的切入时机

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/382306343-5c07cde261b29_articlex.png)
1.编码层

 在同一个项目中创建多个数据源，采用if else的方式，直接根据条件在代码中路由。

  缺点：

 1.编写大量代码

 2.代码无法公用

2.框架层

 适合公司ORM框架统一的情况，通过修改或增强现有ORM框架的功能来实现

3.驱动层

 重新编写了一个JDBC的驱动，在内存中维护一个路由列表，然后将请求转发到真正的数据库连接中。例如：Sharding-JDBC、TDDL等

4.代理层

 伪装成一个数据库，接受业务端的链接。然后负载业务端的请求，解析或者转发到真正的数据库中。例如MyCat、MySQL Router、Sharding-Proxy

5.实现层
更换底层的数据存储，比如Mysql替换为TiDB。

传统的分库分表，通常是在驱动层和代理层做切入，这两个各有优劣，不过在将驱动层和代理层的区别前，先说一下TiDB。

## TiDB

TiDB是公司一位大佬推荐的，了解一番后发现这个数据库很方便快捷的帮我们解决海量数据存储这件事情，如果能用TiDB代替传统的分库分表方案也是很好的，可以节省很多时间。不过由于这个数据库只在公司大数据部门的OLAP系统有应用，而实时性要求较高的OLTP系统目前还没有应用，所以决定对TiDB系统进行一次压测，看看其能否满足线上的要求。

压测的过程不多赘述，最终的结果页不是很理想，因为有这么一个怪现象：在持续高并发的情况下，会出现莫名其妙的连接超时失败。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/%E5%9B%BE%E7%89%871.png)

对于这一结果，我们百思不得其解，对结果的准确性也保持的怀疑的态度。但是由于时间有限，不允许我们继续测试，只得将目光投向了其他中间件，同时也和官方联系，询问原因。

后面官方给出的说法是这样的：由于我们的内存配置的太小(8g)，导致持续 高并发的时候会进行内存回收，这个时候会强制断开连接。并且给我们介绍说目前实现上OLTP系统中应用TiDB内存都是258g，集群3台机器以上。好吧，都是土豪，惹不起。

## Sharding-JDBC和Mycat

排序TiDB后，便只能使用传统的分库分表方案，国内比较火的便是Sharding-JDBC和Mycat，这两个正是驱动层和代理层的代表。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/Driver%E5%92%8CProxy.png)

相对于Mycat，仅仅是一个Jar包的Sharding-JDBC赢了我的青睐。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/Sharding-JDBC.png)

# Sharding-JDBC在SpringBoot2中的应用。

Sharidng-JDBC最早起源于当当，后来进入了Apache孵化器，变为了Sharding-Sphere，目前最新的版本是[4.0.0-RC1](https://github.com/apache/incubator-shardingsphere/releases/tag/4.0.0-RC1)。

## 依赖引入

官方的文档并没有写明白Springboot项目应该如何引入依赖，好在机智的我在官方案例中找到了。

```
            <dependency>
                <groupId>org.apache.shardingsphere</groupId>
                <artifactId>sharding-jdbc-spring-boot-starter</artifactId>
                <version>4.0.0-RC1</version>
            </dependency>

```

## 配置数据源以及分库分表规则

```yaml
spring:
  shardingsphere:
    datasource:
      master0: # 主库连接信息
        driver-class-name: com.mysql.jdbc.Driver
        jdbc-url: jdbc:mysql://${your database ip}:3306/${your database name}?Unicode=true&characterEncoding=utf-8&zeroDateTimeBehavior=convertToNull&autoReconnect=true
        password: your password
        type: com.zaxxer.hikari.HikariDataSource
        username: your username
      master0slave0: # 从库连接信息
        driver-class-name: com.mysql.jdbc.Driver
        jdbc-url: jdbc:mysql://${your database ip}:3306/${your database name}?Unicode=true&characterEncoding=utf-8&zeroDateTimeBehavior=convertToNull&autoReconnect=true
        password: your password
        type: com.zaxxer.hikari.HikariDataSource
        username: your username
      names: master0,master0slave0 # 连接名称，和上面对应。如果有多个主库则配置master1,master1slave1，名字可以随便起，对应起来就好
    sharding:
      broadcast-tables: # 配置广播表，适合数据量不大，但是每个数据源都存在的表
        - xtgy_chaxunympz
      default-data-source-name: master0 #默认数据源，没有配置分库分表规则的表，会使用默认数据源
      master-slave-rules: #配置主从规则 
        master0:
          master-data-source-name: master0
          slave-data-source-names: master0slave0
      tables: #配置各表的路由规则
        table_name: #表名
          actual-data-nodes: master0.table_name_$->{0..127} #实际表名 table_name_0 至 table_name_127
          key-generator: #主键生成策略
            column: id
            type: UUID
          table-strategy: #分表规则
            inline:
              algorithm-expression: table_name_$->{customer_id % 128} #customer_id %128
              sharding-column: customer_id #用于分表的键
```


## 允许Bean覆盖

SpringBoot2默认不允许Bean覆盖，我们需要改成允许，不然**可能**会报错

```yaml
spring:
  main:
    allow-bean-definition-overriding: true

```


到这里，配置便完成了，是不是很简单？如果你的数据库和表结构都已经创建，就可以开始体验了。后面会介绍Sharding-JDBC的一些特性，已经源码解析。

# 参考
[https://shardingsphere.apache.org/document/current/cn/overview/](https://shardingsphere.apache.org/document/current/cn/overview/)

[https://segmentfault.com/a/1190000017272697](https://segmentfault.com/a/1190000017272697)





