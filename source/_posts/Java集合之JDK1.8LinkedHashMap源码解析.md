---
layout: post
title: Java集合之JDK1.8LinkedHashMap源码解析
categories:
  - consectetur
  - malesuada
tags:
  - semper
  - fermentum
---

# 概览

LinkedHashMap实现了Map接口继承至HashMap，它在HashMap的基础上，通过一条双向链表是插入顺序和访问顺序保持一致。LinkedHashMap除了对双向链表的维护外，基本都是对HashMap的操作，所以在看LinkedHashMap源码之前，强烈建议先看看HashMap的源码,可以参考我的这一篇：[](https://zhuanlan.zhihu.com/p/72296421)

本篇文章不会再详细解析HashMap的东西，将重点放在LinkedHashMap对双向链表的维护上。

# 构造函数

照例从创建LinkedHashMap对象说起，依次为起点，一步步解开LinkedHashMap的神秘面纱。

```java
　LinkedHashMap()
　使用默认初始容量16和默认加载因子0.75创建一个LinkedHashMap
　LinkedHashMap(int initialCapacity)
　使用自定义初始容量和默认加载因子0.75创建一个LinkedHashMap
　LinkedHashMap(int initialCapacity, float loadFactor)
　使用自定义初始容量和自动以加载因子创建一个LinkedHashMap
　LinkedHashMap(int initialCapacity, float loadFactor, boolean accessOrder)
　使用自定义初始容量和自动以加载因子创建一个LinkedHashMap,并且可以设置accessOrder,accessOrder为true，调用get方法会改变内部结构，这一点后面会细讲
　LinkedHashMap(Map<? extends K,? extends V> m)
　使用Map子类实例创建一个LinkedHashMap
```
<!-- more -->

## LinkedHashMap() 无参构造

```java
public LinkedHashMap() {
   //调用父类HashMap构造方法
　　super();
　　//accessOrder默认为false
　　accessOrder = false;
}
```

## LinkedHashMap(int initialCapacity, float loadFactor)自定义初始容量和加载因子

```java
public LinkedHashMap(int initialCapacity, float loadFactor) {
   //调用父类HashMap构造方法
　　super(initialCapacity, loadFactor);
   //accessOrder默认为false
　　accessOrder = false;
}
```

LinkedHashMap和HashMap的构造方法差不多，区别在于多了一个accessOrder，接下来看看这个字段起什么作用。

# accessOrder

点开accessOrder的调用处，发现除了构造方法外，只有3处使用了accessOrder字段,分别是get()方法,getOrDefault()方法和afterNodeAccess（）方法。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/accessOrder.png)

get()方法我们比较熟悉，先看下get()方法的代码

```java
public V get(Object key) {
　　Node<K,V> e;
　　if ((e = getNode(hash(key), key)) == null)
　　　　return null;
   //如果accessOrder为true，调用afterNodeAccess()方法,传入get()方法取出的节点e
　　if (accessOrder)
　　　　afterNodeAccess(e);
　　return e.value;
}
```

看下afterNodeAccess()方法的代码

```java
void afterNodeAccess(Node<K,V> e) { // move node to last
   //声明最后一个节点last
　　LinkedHashMap.Entry<K,V> last;
   //如果accessOrder为true并且最后一个节点tail不等于get()方法取出的节点e
　　if (accessOrder && (last = tail) != e) {
       //将e复制给p,取出p的前节点和后节点分别复制给b和a
　　　　LinkedHashMap.Entry<K,V> p =
　　　　　　(LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
      //将p的后节点置为null
　　　　p.after = null;
　　　　if (b == null)
　　　　　　head = a;
　　　　else
　　　　　　b.after = a;
　　　　if (a != null)
　　　　　　a.before = b;
　　　　else
　　　　　　last = b;
　　　　if (last == null)
　　　　　　head = p;
　　　　else {
　　　　　　p.before = last;
　　　　　　last.after = p;
　　　　}
　　　　tail = p;
　　　　++modCount;
　　}
}
```

tail是LinkedHashMap的成员变量,保存的是一份最新的节点数据。
```java
/**
　* The tail (youngest) of the doubly linked list.
　*/
transient LinkedHashMap.Entry<K,V> tail;
```

有最新的便有最老的，LinkedHashMap中使用head变量保存。
```
/**
　* The head (eldest) of the doubly linked list.
　*/
transient LinkedHashMap.Entry<K,V> head;
```

这个方法的代码并不复杂，不一一解释了，我么只需要知道最终的效果是将get()方法取出的节点，放到了链表的最后，使之成为尾部节点，从而改变了数据在LinkedHashMap中的存储顺序，它的迭代顺序就是最后访问其条目的顺序。这种特性很适合构建LRU Cache

## LRU Cache

### 什么是LRU？

LRU是Least Recently Used的缩写，即最近最少使用，是一种常用的页面置换算法，选择最近最久未使用的页面予以淘汰。

实现 LRU 算法除了需要 key/value 字典外，还需要附加一个链表，链表中的元素按照一定的顺序进行排列。当空间满的时候，会踢掉链表尾部的元素。当字典的某个元素被访问时，它在链表中的位置会被移动到表头。所以链表的元素排列顺序就是元素最近被访问的时间顺序。

位于链表尾部的元素就是不被重用的元素，所以会被踢掉。位于表头的元素就是最近刚刚被人用过的元素，所以暂时不会被踢。

看了这里的描述，有人可能会疑惑，链表尾部的元素会被踢掉。这和LinkedHashMap似乎正好矛盾，因为LinkedHashMap是将最近访问的元素放到末尾。

注意，链表的双向的，头部和尾部的确定取决于我们代码的上下文。

拓展:Redis在内存过高的时候可以对key进行淘汰，Redis 提供了几种可选策略 (maxmemory-policy) 来让用户自己决定该如何腾出新的空间以继续提供读写服务。

这几种策略的其中之一便有LRU：

volatile-lru 尝试淘汰设置了过期时间的 key，最少使用的 key 优先被淘汰。没有设置过期时间的 key 不会被淘汰，这样可以保证需要持久化的数据不会突然丢失。

# put()方法

LinkedHashMap的put()方法继承至HashMap,没有进行重写。此处不再赘述HashMap的put()方法。LinkedHashMap对创建节点的方法进行了重写

## new Node()重写

```java
Node<K,V> newNode(int hash, K key, V value, Node<K,V> e) {
　　//创建一个LinkedHashMap.Entry对象
　　LinkedHashMap.Entry<K,V> p =
　　　　new LinkedHashMap.Entry<K,V>(hash, key, value, e);
   //将p放到链表的最后
　　linkNodeLast(p);
　　return p;
}
```

LinkedHashMap.Entry是LinkedHashMap的静态内部类，它就是所谓的双向链表,继承至HashMap.Node类，并在此基础上扩展了两个属性:前节点和后节点

```java
/**
　* HashMap.Node subclass for normal LinkedHashMap entries.
　*/
static class Entry<K,V> extends HashMap.Node<K,V> {
　　//定义了两个变量，分别是当前节点的前一个节点和后一个节点
　　Entry<K,V> before, after;
　　Entry(int hash, K key, V value, Node<K,V> next) {
　　　　super(hash, key, value, next);
　　}
}
```

接下来看下linkNodeLast的代码

```java
//将tail保存一份
LinkedHashMap.Entry<K,V> last = tail;
//将最新的节点p赋值给tail
tail = p;
if (last == null)
　　//如果链表是空的，将p放在链表头部
　　head = p;
else {
　　//如果链表不为空，将p放到链表的尾部
　　p.before = last;
　　last.after = p;
}
```

# get()方法

LinkedHashMap对HashMap的get()方法进行了重写，区别在前面已经说过，主要就是accessOrder字段。如果我们设置了accessOrder字段为true，那么get()方法在获得数据之后，会将该数据节点放置链表的最后。

```java
public V get(Object key) {
　　Node<K,V> e;
　　//调用HashMap的getNode()方法获取数据
　　if ((e = getNode(hash(key), key)) == null)
　　　　return null;
　　if (accessOrder)
　　　　afterNodeAccess(e);
　　return e.value;
}
```


# remove()方法

对于remove方法，在LinkedHashMap中也没有重写，它调用的还是父类的HashMap的remove()方法，在LinkedHashMap中重写的是：afterNodeRemoval(Node<K,V> e)这个方法，在Hash表的元素被删除之后，删除双向链表的元素。

```java
void afterNodeRemoval(Node<K,V> e) { // unlink
　　LinkedHashMap.Entry<K,V> p =
　　　　(LinkedHashMap.Entry<K,V>)e, b = p.before, a = p.after;
　　p.before = p.after = null;
　　if (b == null)
　　　　head = a;
　　else
　　　　b.after = a;
　　if (a == null)
　　　　tail = b;
　　else
　　　　a.before = b;
}
```

# Iterator遍历

LinkedHashMap重写了entrySet()方法
```
public Set<Map.Entry<K,V>> entrySet() {
　　Set<Map.Entry<K,V>> es;
　　return (es = entrySet) == null ? (entrySet = new LinkedEntrySet()) : es;
}
```

LinkedHashMap实际上是对双向链表LinkedHashMap.Entry遍历。
```
abstract class LinkedHashIterator {
　　LinkedHashMap.Entry<K,V> next;
　　LinkedHashMap.Entry<K,V> current;
　　int expectedModCount;

　　LinkedHashIterator() {
　　　　next = head;
　　　　expectedModCount = modCount;
　　　　current = null;
　　}

　　public final boolean hasNext() {
　　　　return next != null;
　　}

　　final LinkedHashMap.Entry<K,V> nextNode() {
       //遍历双向链表
　　　　LinkedHashMap.Entry<K,V> e = next;
　　　　if (modCount != expectedModCount)
　　　　　　throw new ConcurrentModificationException();
　　　　if (e == null)
　　　　　　throw new NoSuchElementException();
　　　　current = e;
　　　　next = e.after;
　　　　return e;
　　}

　　public final void remove() {
　　　　Node<K,V> p = current;
　　　　if (p == null)
　　　　　　throw new IllegalStateException();
　　　　if (modCount != expectedModCount)
　　　　　　throw new ConcurrentModificationException();
　　　　current = null;
　　　　K key = p.key;
　　　　removeNode(hash(key), key, null, false, false);
　　　　expectedModCount = modCount;
　　}
}
```

# 总结
1. LinkedHashMap通过在HashMap的基础上增加一条双向链表，实现了插入顺序和访问顺序一致。实现的核心是静态内部类LinkedHashMap.Entry，LinkedHashMap.Entry继承至HashMap的静态内部类HashMap.Node。Entry拥有Node的所有属性，并且在此基础上增加了前节点和后节点两个属性。所有对底层HashMap数据结构修改的地方都会修改该链表进行修改,遍历的时候便是遍历这一条有序的链表。需要注意的是get()方法在accessOrder为true的时候也会对底层结构进行修改。
2. 基于get()在accessOrder为true时，会将访问到的元素放到链表的最后的特性，我们可以使用LinkedHashMap实现LRU缓存。
3. LinkedHashMap同HashMap一样，线程不安全





