
---
layout: post
title: Java集合之JDK1.8HashSet源码解析
date: 2019-06-01 15:01:18
categories:
  - 容器
tags:
  - 容器,HashSet
---

前面分析了ArrayList和HashMap的源码，今天分析下HashSet的源码。HashSet作为Java集合框架的一员，也是非常重要的，虽然平时用的没有前面两个多，但是在一些特定的场景可以帮助我们快速解决问题，所以掌握其特性也是非常重要的。

# 类注释

首先还是先看下官方的类注释，快速了解HashSet的特性。

此类实现Set接口，由哈希表（实际上是HashMap实例）支持。它不能保证集合的迭代顺序;特别是，它不保证顺序一直保持不变。该类允许null元素。如果Hash函数能够很完美的分散各个元素到桶上，该类的基本操作（add, remove, contains and size）提供恒定的时间性能。

迭代此集合需要的时间与HashSet实例的大小（元素数量）以及HashMap实例的“容量”（桶数）之和成比例。因此，如果迭代性能很重要，则不要将初始容量设置得太高（或负载因子太低）。请注意，此实现不同步。如果多个线程同时访问哈希集合，并且至少有一个线程修改了该即可，则必须在外部进行同步。这通常通过在自然封装集合的某个对象上进行同步来实现。如果不存在此类对象，则应使用Collections.synchronizedSet方法“包装”该集合。这最好在创建时完成，以防止对集合的意外不同步访问：Set s = Collections.synchronizedSet（new HashSet（...））;

这个类的迭代器方法返回的迭代器是快速失败的：如果在创建迭代器之后的任何时候修改了set，​​除了通过迭代器自己的remove方法之外，Iterator都将抛出ConcurrentModificationException。因此，在并发修改的情况下，迭代器快速而干净地失败，而不是在未来的未确定时间冒着任意的，非确定性行为的风险。

请注意，迭代器的快速失败行为无法阿紫存在不同步的并发修改时做出任何硬性保证。快速失败迭代器会尽最大努力抛出ConcurrentModificationException。因此，不要编写这个异常的程序：迭代器的快速失败行为应仅用于检测错误。

由于HashSet的底层是HashMap,它的类注释和HashMap差不多，其特性也和HashMap差不多。

<!-- more -->
# 构造方法

同HashMap一样，HashSet也有4个构造方法

**HashSet()**
构建一个空的set集合，其底层的HashMap实例使用默认的初始容量(16)和加载因子(0.75)。

**HashSet(Collection<? extends E> c)**
使用其他集合创建一个新得HashSet

**HashSet(int initialCapacity)**
构建一个空的set集合，其底层的HashMap实例使用传入的初始容量和默认加载因子(0.75)。

**HashSet(int initialCapacity, float loadFactor)**
构建一个空的set集合，其底层的HashMap实例使用传入的初始容量和加载因子。

我们看一下第一个和第四个构造方法

```java
    /**
     * 构建一个空的set集合，其底层的HashMap实例使用默认的初始容量(16)和加载因子(0.75)。
     */
    public HashSet() {
        map = new HashMap<>();
    }

```

```java
    /**
     * 构建一个空的set集合，其底层的HashMap实例使用传入的初始容量和加载因子。
     *
     * @param      initialCapacity   初始容量
     * @param      loadFactor        加载因子
     * @throws     IllegalArgumentException if the initial capacity is less
     *             than zero, or if the load factor is nonpositive
     */
    public HashSet(int initialCapacity, float loadFactor) {
        map = new HashMap<>(initialCapacity, loadFactor);
    }

```

# 成员变量

```java
/**
 * 存放元素的map
 */
private transient HashMap<E,Object> map;

/**
 * HashMap的value值
 */
private static final Object PRESENT = new Object();
```

# 成员方法
## add

```
    /**
     * 将元素放到map中，key是要添加的元素e，value是final修饰的object对象。
     */
    public boolean add(E e) {
        return map.put(e, PRESENT)==null;
    }

```

## remove

```java
    /**
     * 从HashMap中移除元素o，如果元素存在返回true，否则返回false
     */
    public boolean remove(Object o) {
        return map.remove(o)==PRESENT;
    }

```

## size

```java
    /**
     * 返回HashMap中元素的个数
     *
     * @return the number of elements in this set (its cardinality)
     */
    public int size() {
        return map.size();
    }

```

## contains

```java
    /**
     * 判断HashMap中是否包含某个元素
     *
     * @param o element whose presence in this set is to be tested
     * @return <tt>true</tt> if this set contains the specified element
     */
    public boolean contains(Object o) {
        return map.containsKey(o);
    }

```

## isEmpty

```
    /**
     * 判断HashSet是否是空的
     *
     * @return <tt>true</tt> if this set contains no elements
     */
    public boolean isEmpty() {
        return map.isEmpty();
    }

```

底层调用的是HashMap的isEmpty方法，实现如下

```java
    public boolean isEmpty() {
        return size == 0;
    }
```

# ArrayList和HashSet的区别
比较ArrayList和HashSet的区别，其实也是比较ArrayList和HashMap的区别

1. ArraysList是有序的，元素可以重复。HashSet无序，元素不可重复。
2. ArrayList底层是一个数组，HashSet底层是一个HashMap，HashMap的底层又是数组+链表+红黑树
3. ArrList在数组被填充满之后才会扩容，扩容到原来的1.5倍+1.HashSet和HashMap一样，扩容的实际和加载因子有关，扩容到原来的2倍


# 总结
1. HashSet的底层其实是一个HashMap，key是我们存放的元素，其value是一个final修饰的object对象
2. HashSet是无序的，和HashMap一样。
3. HashSet也是线程不安全的，我们可以使用Set s = Collections.synchronizedSet（new HashSet（...））包装一个线程安全的Set
4. HashSet中的元素不可重复，因为HashMap中的key不可重复，重复的key会覆盖其value。


# 参考
[https://docs.oracle.com/javase/8/docs/api/](https://docs.oracle.com/javase/8/docs/api/)

