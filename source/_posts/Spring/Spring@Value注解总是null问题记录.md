---
title: Spring@Value注解总是null问题记录
categories:
  - Spring
date: 2019-03-16 19:40:36
---


## 问题描述
在使用@value注解之后，字段总是为空。后来发现是因为字段使用了static修饰。
```
@Component
public class TestValue {
    @Value("${appEnv}")
    private static String appenv; //null

    public String test() {
        return appenv;
    }
}
```
## 原因
spring的依赖注入不支持为static变量注入。spring 依赖注入的底层原理还是利用反射来创建对象。而static变量，在jvm加载类的时候便已经创建，存在于方法区，被所有实例共享，属于类的属性而不是对象的属性。spring是基于对象层面的依赖注入。
<!-- more -->

## 解决
1.使用set方法注入，非静态setter 方法注入静态变量。如：
```
import org.springframework.beans.factory.annotation.Value;  
import org.springframework.stereotype.Component;  
  
@Component  
public class GlobalValue {  
  
    public static String DATABASE;  
  
    @Value("${mongodb.db}")  
    public void setDatabase(String db) {  
        DATABASE = db;  
    }  
  
} 
```

2.@PostConstruct方式实现
```
import org.mongodb.morphia.AdvancedDatastore;  
import org.springframework.beans.factory.annotation.Autowired;  
  
@Component  
public class MongoFileOperationUtil {  
    @Autowired  
    private static AdvancedDatastore dsForRW;  
  
    private static MongoFileOperationUtil mongoFileOperationUtil;  
  
    @PostConstruct  
    public void init() {  
        mongoFileOperationUtil = this;  
        mongoFileOperationUtil.dsForRW = this.dsForRW;  
    }  
  
}
```
@PostConstruct，会在构造方法之后执行。其给static变量赋值的原理和set方法差不多，都是调用非静态方法给静态变量赋值