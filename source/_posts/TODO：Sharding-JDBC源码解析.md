---
layout: post
title: Sharding-JDBC源码解析
categories: 
  - Sharding-JDBC
---

最近在工作中使用Sharding-JDBC做了分库分表，目前项目已经上线稳定运行，闲暇之余看下源码。

版本:4.0.0-RC1

由于现在基本都是springboot，而Sharding-Sphere也提供了SpringBoot的包，所以先看看sharding-jdbc-spring-boot-starter的源码，maven坐标:
<dependency>
   <groupId>org.apache.shardingsphere</groupId>
   <artifactId>sharding-jdbc-spring-boot-starter</artifactId>
   <version>${sharding-sphere.version}</version> 
 </dependency>
 <sharding-sphere.version>4.0.0-RC1</sharding-sphere.version>


