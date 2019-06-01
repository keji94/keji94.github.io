---
layout: post
title: java面试宝典
date: 2019-05-12 01：00：00
categories: 
  - 面试
---
# 前言 做好面试前的准备工作



# 第一部分 Java基础

## 关键字
    
### static


#### static 关键字的作用?

static关键字可以让我们在不创建对象的情况下访问方法或变量。static除了可以修饰方法和变量外，还有static代码块，以及修饰内部类。被static修饰的数据，在内存中只会存在一份。合理利用static合理提升程序性能

<!-- more -->

**静态变量**

static变量也称作静态变量，静态变量和非静态变量的区别是：静态变量被所有的对象所共享，在内存中只有一个副本，它当且仅当在类初次加载时会被初始化。而非静态变量是对象所拥有的，在创建对象的时候被初始化，存在多个副本，各个对象拥有的副本互不影响。

static成员变量的初始化顺序按照定义的顺序进行初始化。

**静态方法**

static方法一般称作静态方法，由于静态方法不依赖于任何对象就可以进行访问，因此对于静态方法来说，是没有this的，因为它不依附于任何对象，既然都没有对象，就谈不上this了。并且由于这个特性，在静态方法中不能访问类的非静态成员变量和非静态成员方法，因为非静态成员方法/变量都是必须依赖具体的对象才能够被调用。

**静态代码块**

static代码块在类初次被加载的时候，会按照static块的顺序来执行每个static块，并且只会执行一次。

#### 为什么不能通过this访问static变量或者方法？

this代表的是当前对象，被static修饰的变量或者方法，在类被加载的时候就会初始化，这个时候还没有创建对象。

#### static笔试题

```java
public class StaticDemo extends ParentStaticDemo {

    static {
        System.out.println("static block run");
    }

    public StaticDemo() {
        System.out.println("child constructor run");
    }

    public static void main(String[] args) {
        new StaticDemo();
    }

}

class ParentStaticDemo {

    static {
        System.out.println("parent static block run ");
    }

    public ParentStaticDemo() {
        System.out.println("parent constructor run");
    }
}
```

执行StaticDemo类的main()方法，输出顺序是怎样的？

答案：

    parent static block run 
    static block run
    parent constructor run
    child constructor run

在main()方法中，使用new StaticDemo()创建一个StaticDemo对象，但是在创建对象前需要先加载StaticDemo类，由于StaticDemo继承ParentStaticDemo，所以需要先加载ParentStaticDemo类，所以先执行的是"parent static block run "。加载完ParentStaticDemo后，开始加载StaticDemo，所以下一个输出的是static block run。StaticDemo加载完之后，开始创建StaticDemo，由于继承ParentStaticDemo，先执行父类的构造方法，所以先输出parent constructor run，最后是child constructor run。

### final

final 通常表示无法被改变，在java中，final可以修饰变量、方法和类。

**final变量**

对于基本类型，final使数值恒定不变，而对于对象引用，final使引用恒定不变，一旦引用被初始化指向一个对象，就无法在将它指向另外一个变量。然而，对象其自身是可以修改的。

**final方法**

使用final方法的原因有两个，一是将方法锁定，确保在继承中是方法行为保持不变，不会被覆盖。二是效率。

在Java早期实现中，将一个方法指明为final，就是同意编译器将针对该方法的所有调用都改为内嵌调用。当编译器发现一个final方法调用命令时，它会跳过插入程序代码这种正常方式而执行方法调用机制(将参数调入栈，跳至方法方法代码处并执行，然后跳回并清理栈中的参数，处理返回值)，并且以方法体中的实际代码的副本来代替方法调用。这可以消除方法调用的开销。当然，如果一个方法很大，你的程序代码就会膨胀，所带来的性能提高会因为花费与方法内的时间量而被缩减。

需要注意的，JDK5以后，已经不推荐因为效率而使用final修饰方法，因为早期的虚拟机能够自动优化这种情况，只有你想明确禁止方法被覆盖时，才需要考虑使用final修饰方法。

**final类**

当将某个类定义为final类时，表名该类不能被集成。

### transient

在对象序列化的时候，有些变量不需要序列化，比如密码等，可以使用transient关键字来解决这个问题，transient修饰的变量不会被序列化。

### volatile
[volatile关键字的作用以及原理](http://kejishouxin.com/java%E5%9F%BA%E7%A1%80/volatile/volatile%E5%85%B3%E9%94%AE%E5%AD%97%E7%9A%84%E4%BD%9C%E7%94%A8%E4%BB%A5%E5%8F%8A%E5%8E%9F%E7%90%86/index.html)

### synchronized

## 其他

### String,StringBuffer和StringBuilder的区别；

String不可变得，对String类型进行改变的时候其实都是生成了一个新的String对象，然后将引用指向新的string对象。

StringBuffer对象是线程安全的可变字符序列。常用的方法是append和insert，append是添加到末端，insert是在指定的点添加字符。StringBuffer的方法基本都是同步的。

StringBuilder是5.0新增的，和StringBufer差不多，但是是线程不安全的，大多数实现中，比StringBuffer要快。

### Object的方法有哪些
1、clone()
2、equals()
3、finalize()
4、getclass()
5、hashcode()
6、notify()
7、notifyAll()
8、toString()
9、wait()

## 集合

### ArrayList

#### 说一下ArrayList的源码
[](http://kejishouxin.com/java%E5%9F%BA%E7%A1%80/%E9%9B%86%E5%90%88/ArrayList%20%E6%BA%90%E7%A0%81%E8%A7%A3%E6%9E%90/index.html)

#### Fail-fast行为是什么？

ArrayList里面有一个modCount属性，并且在其内部有一个私有的Itr类，实现了Iterator接口。在对ArrayList遍历时，首先会将modCount变量保存一份，之后每次遍历都会checkmodCount是否被修改了，如果修改了，则立即抛出ConcurrentModificationException


#### List和Set的区别 

set接口规定其实现无序，不可重复。
     HashSet（底层是HashMap） LinkedHashSet
list接口规定其实现有序，可重复。
     实现类有：LinkedList，ArrayList，Vector
map接口是散列集合的顶层接口，存储的key-value键值对
     HashMap HashTable StoredMap
     
### HashMap

#### 说一下HashMapde 源码

#### 如何实现HashMap顺序存储：可以参考LinkedHashMap的底层实现；

#### concurrentHashMap的源码解析

## 多线程

### wait和sleep的区别，必须理解；

### 说说阻塞队列的实现：可以参考ArrayBlockingQueue的底层实现（锁和同步都行）；

### 进程通讯的方式：消息队列，共享内存，信号量，socket通讯等；

### 用过并发包的哪些类；

### 什么地方用了多线程；

### Excutors可以产生哪些线程池；

### 为什么要用线程池；

### volatile关键字的用法：使多线程中的变量可见；

### Java中的多线程了解么，线程池的增长策略和拒绝策略了解么，说一下。

### 讲一下线程增加的过程和拒绝策略的执行。

### 讲了一下fixthreadpool的增长策略，然后几种拒绝策略。

### 高并发情况下，如何使用线程池，用哪个，问了一下线程结束要多久，是否在下一个线程结束前完成（我想的是cachethreadpool，其实思路错了）。

### 表示并发量比较大，所以我说可以考虑并发量是否大于队列长度加上最大线程数量和，如果不超过的话可以是用fixthreadpool。

### 你在项目中怎么用到并发的

## IO

### bio，nio，aio的区别；

### 京东内部的jsf是使用的什么协议通讯：可参见dubbo的协议；


## 反射和动态代理



# 第二部分 常用框架

## spinrgmvc

### springmvc的核心是什么，请求的流程是怎么处理的，控制反转怎么实现的；

### spring里面的aop的原理是什么；

### Springmvc的基本架构，请求流程。

## spring

### Spring bean的生命周期

### 说一下Spring源码把，它的架构，流程。

### Spring的bean如果要在实例化过程中修改其某一个成员变量，应该怎么做呢。不通过构造方法，并且AOP也并不能实现。



## mybatis

### mybatis如何处理结果集：反射，建议看看源码；


## springboot

## dubbo

### nio框架：dubbo的实现原理；

## shiro

## solr和es

### 倒排索引



## zookeeper

### zookeeper是什么；

### zookeeper哪里用到；

### zookeeper的选主过程；

### zookeeper集群之间如何通讯；

### 你们的zookeeper的节点加密是用的什么方式；

### 分布式锁的实现过程；

## maven

## MQ

### mq的原理是什么：有点大。。都可以说；

### mq如何保证实时性；

### mq的持久化是怎么做的；


# 第三部分 数据库

## mysql

### msyql优化经验：

### mysql的语句优化，使用什么工具；

### mysql的索引分类：B+，hash；什么情况用什么索引；

### mysql的存储引擎有哪些，区别是什么；

### 说说事务的特性和隔离级别；

### 悲观锁和乐观锁的区别，怎么实现；

### 索引什么时候会失效变成全表扫描

### 数据库的事务有什么用

### 数据的索引有什么用，怎么实现

### 联合索引的匹配原则

### 数据库万级变成亿级，怎么处理。分库分表，分片规则hash和取余数。使用mycat中间件实现。

### https://mp.weixin.qq.com/s/ZtuUg79OFLh20-HWs2Qs4A

## redis

### redis有哪些数据结构？

### 介绍下zset，它底层原理是什么？

### 布隆过滤器和hyperloglog.ip地址过滤的布隆过滤器实现。

#### 亿级ip地址过滤

### redis哨兵

### redis是怎么保证高可用的？

### redis为什么是单线程？

### redis的淘汰策略有哪些；

## mongodb

## docker 

### 听说你项目用过docker，讲一下docker的实现原理，说了虚拟机一般要对内核进行虚拟化，docker则用cgroup和namespace分别进行硬件和命名空间的隔离。

# 第四部分 Java虚拟机

## JVM的内存结构，JVM的算法；

## 强引用，软引用和弱引用的区别；

## 数组在内存中如何分配；

## 请写一段栈溢出、堆溢出的代码；

## ThreadLocal可以用来共享数据吗；


# 第五部分 JavaWeb

## tomcat
### 你平时是如何进行Tomcat性能优化的?

### 你说了解Tomcat的基本原理，了解的是哪一部分，基本架构，connector和container

### Tomcat的类加载器了解么，回答不了解只了解Java的类加载器。



## web

### 说说http,https协议；

### tcp/ip协议簇；

### osi五层网络协议；

### tcp，udp区别；

### 用过哪些加密算法：对称加密，非对称加密算法；

### 说说tcp三次握手，四次挥手；

### cookie和session的区别，分布式环境怎么保存用户状态；

### 分布式session解决方案

### HTTP协议了解么，和tcp有什么区别。

### http1.0和2.0的区别。答了TCP连接复用，加入ssl，以及压缩请求头。

### web请求的过程，讲了浏览器到http服务器的过程，再讲了mvc的请求处理过程。

其中哪个更新比较有意义，为什么。我说的是压缩请求头，这样可以优化HTTP服务的性能。

# 第六部分 设计模式

# 第七部分 项目相关

# 第八部分 算法相关

## java中常说的堆和栈，分别是什么数据结构；另外，为什么要分为堆和栈来存储数据。

## TreeMap如何插入数据：二叉树的左旋，右旋，双旋；

## 一个排序之后的数组，插入数据，可以使用什么方法？答：二分法；问：时间复杂度是多少？

## 平衡二叉树的时间复杂度；

## Hash算法和二叉树算法分别什么时候用；

## 图的广度优先算法和深度优先算法：详见jvm中垃圾回收实现；

## 排序算法和适用场景


# 第九部分 Linux

## linux常用的命令有哪些；

## 如何获取java进程的pid；

## 如何获取某个进程的网络端口号；

## 如何实时打印日志；

## 如何统计某个字符串行数；

# 第十部分 设计与思想
## 重构过代码没有？说说经验；

## 一千万的用户实时排名如何实现；

## 五万人并发抢票怎么实现；

## 项目中遇到的最大挑战。

## 项目中学到最多的东西

## 你的职业规划

# 第十一部分 HR面试

## 兴趣爱好

## 三年到五年的职业规划

## 意向公司和城市

## 实习经历和收获

## 实习中最大的困难

## 为什么换公司，为什么拒绝菜鸟实习offer

## 你的缺点和优点

## 你觉得你比其他人优秀的地方说三个

## 为什么想来我们部门