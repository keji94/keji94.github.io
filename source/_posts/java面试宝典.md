---
layout: post
title: java面试宝典
date: 2019-05-12 01：00：00
categories: 
  - 面试
---

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

### finalize

### synchronized

### 访问修饰符

## 集合

### ArrayList

### HashMap

## 多线程

## IO

## 反射和动态代理



# 第二部分 常用框架

## spinrgmvc

## spring

## mybatis

## springboot

## dubbo

## shiro

## solr和es

## zookeeper

## maven

# 第三部分 数据库

## mysql

## redis

## mongodb

# 第四部分 Java虚拟机

# 第五部分 JavaWeb

# 第六部分 设计模式

# 第七部分 项目相关

# 第八部分 算法相关

# 第九部分 Linux

# 第十部分 HR面试