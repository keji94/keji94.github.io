---
layout: post
title: HashMap源码解析
date: 2019-06-01 15:01:18
categories: 
  - 集合
  - HashMap
tags:
  - HashMap
  - list
---

哈希表（hash table）也叫散列表，是一种非常重要的数据结构，应用场景及其丰富，许多缓存技术（比如memcached）的核心其实就是在内存中维护一张大的哈希表，而HashMap的实现原理也常常出现在各类的面试题中，重要性可见一斑。本文会对java集合框架中的对应实现HashMap的实现原理进行讲解，然后会对JDK8的HashMap源码进行分析。

# 什么是哈希表
在讨论哈希表之前，我们先大概了解下其他数据结构

　　**数组**：采用一段连续的存储单元来存储数据。对于指定下标的查找，时间复杂度为O(1)；通过给定值进行查找，需要遍历数组，逐一比对给定关键字和数组元素，时间复杂度为O(n)，当然，对于有序数组，则可采用二分查找，插值查找，斐波那契查找等方式，可将查找复杂度提高为O(logn)；对于一般的插入删除操作，涉及到数组元素的移动，其平均复杂度也为O(n)

　　**线性链表**：对于链表的新增，删除等操作（在找到指定操作位置后），仅需处理结点间的引用即可，时间复杂度为O(1)，而查找操作需要遍历链表逐一进行比对，复杂度为O(n)

　　**二叉树**：对一棵相对平衡的有序二叉树，对其进行插入，查找，删除等操作，平均复杂度均为O(logn)。

　　**哈希表**：相比上述几种数据结构，在哈希表中进行添加，删除，查找等操作，性能十分之高，不考虑哈希冲突的情况下，仅需一次定位即可完成，时间复杂度为O(1)，接下来我们就来看看哈希表是如何实现达到惊艳的常数阶O(1)的。

<!-- more -->

　　我们知道，数据结构的物理存储结构只有两种：**顺序存储结构**和**链式存储结构**（像栈，队列，树，图等是从逻辑结构去抽象的，映射到内存中，也这两种物理组织形式），而在上面我们提到过，在数组中根据下标查找某个元素，一次定位就可以达到，哈希表利用了这种特性，**哈希表的主干就是数组**。

　　比如我们要新增或查找某个元素，我们通过把当前元素的关键字 通过某个函数映射到数组中的某个位置，通过数组下标一次定位就可完成操作。

    存储位置 = f(关键字)

其中，这个函数f一般称为**哈希函数**，这个函数的设计好坏会直接影响到哈希表的优劣。举个例子，比如我们要在哈希表中执行插入操作：

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/hash.png)

**哈希冲突**

然而万事无完美，如果两个不同的元素，通过哈希函数得出的实际存储地址相同怎么办？也就是说，当我们对某个元素进行哈希运算，得到一个存储地址，然后要进行插入的时候，发现已经被其他元素占用了，其实这就是所谓的**哈希冲突**，也叫哈希碰撞。前面我们提到过，哈希函数的设计至关重要，好的哈希函数会尽可能地保证 **计算简单**和**散列地址分布均匀,**但是，我们需要清楚的是，数组是一块连续的固定长度的内存空间，再好的哈希函数也不能保证得到的存储地址绝对不发生冲突。那么哈希冲突如何解决呢？哈希冲突的解决方案有多种:开放定址法（发生冲突，继续寻找下一块未被占用的存储地址），再散列函数法，链地址法，而HashMap即是采用了链地址法，也就是**数组+链表**的方式。

# JDK8中HashMap的实现原理

在JDK1.8之前，HashMap采用数组+链表实现，即使用链表处理冲突，同一hash值的节点都存储在一个链表里。但是当位于一个桶中的元素较多，即hash值相等的元素较多时，通过key值依次查找的效率较低。而JDK1.8中，HashMap采用数组+链表+红黑树实现，当链表长度超过阈值（8）时，将链表转换为红黑树，这样大大减少了查找时间。

下图中代表jdk1.8之前的hashmap结构，左边部分即代表哈希表，也称为哈希数组，数组的每个元素都是一个单链表的头节点，链表是用来解决冲突的，如果不同的key映射到了数组的同一位置处，就将其放入单链表中。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/hashmapjdk7.png)

jdk1.8之前的hashmap都采用上图的结构，都是基于一个数组和多个单链表，hash值冲突的时候，就将对应节点以链表的形式存储。如果在一个链表中查找其中一个节点时，将会花费O（n）的查找时间，会有很大的性能损失。到了jdk1.8，当同一个hash值的节点数不小于8时，不再采用单链表形式存储，而是采用红黑树，如下图所示。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/hashmapjdk8.png)

# JDK8 HashMap源码解析

## 类注释翻译

点开HashMap，迎面扑来的便是一大段关于HashMap的类注释，一个屏幕都放不下。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/HashMap%E7%B1%BB%E6%B3%A8%E9%87%8A.png)

通过这些注释，我们可以对HashMap的特性有一个大致的了解，接下来先尝试翻译一下，翻译不对的地方欢迎留言指出。

HashMap是Map接口的实现类，它基于哈希表，提供了所有可选的map操作，并允许null的值和null键（HashMap类大致相当于Hashtable ，区别在于它是不同步的，并允许null）。这个类不保证map的顺序; 特别是，它不能保证顺序是一直保持不变的。

如果Hash函数能够很完美的分散各个元素到桶上，对于get和put这些基础操作，HashMap可以提供恒定的时间性能。遍历HashMap的时间与实例的容量（桶数）加上其大小（key-value数量）成比例。因此，如果迭代性能很重要，则不要将初始容量设置得太高（或负载因子太低）。

HashMap实例有两个影响其性能的参数： _初始容量_和_负载因子_ 。_容量_是哈希表中的桶数，初始容量是创建哈希表时的容量。 _负载因子_决定扩容前哈希表能达到多少容量。 当哈希表中的条目数超过加载因子和当前容量的乘积时，哈希表会被重新哈希(也就是说，内部数据结构被重建),容量扩充为之前的两倍。

默认加载因子（0.75）在时间和空间成本之间提供了良好的权衡。 大于0.75会减少空间开销，但会增加查询成本（HashMap类的大多数操作中，包括get和put）。 在设置其初始容量时，应考虑预期key-value数及其加载因子，以便最小化扩容次数。 如果初始容量大于最大条目数除以加载因子，则不会发生扩容操作。

如果一个HashMap实例要存放很多的key-value，在初始化的时候指定一个大的容量比扩容性能更好。如果很多key的HashCode()相同，肯定会导致HashMap性能降低。如果这些间是Comparable（可比较）的，这个类或许可以通过键之间的比较顺序来改善性能。

需要注意的是HashMap不是同步的，如果多个线程同时访问HashMap，并且至少有一个线程在对其结构进行修改，则必须在外部加上同步（结构修改是添加或删除一个或多个映射的任何操作;仅更改与实例已包含的键关联的值不是结构修改）。
这通常通过在一个封装map的对象上加上同步来解决。如果不存在这样的对象，则map应该使用[Collections.synchronizedMap](https://docs.oracle.com/javase/8/docs/api/java/util/Collections.html#synchronizedMap-java.util.Map-)方法进行转换。这一步最好在创建的时候就完成，防止出现意外之外的不同步访问。

```java
Map m = Collections.synchronizedMap(new HashMap(...));
```

所有这个类的“集合视图方法(collection view methods)”返回的迭代器都是快速失败（ _fail-fast_）的：在迭代器创建之后，除了迭代器自己的remove方法之外，任何时候对map进行结构修改，迭代器都将抛出ConcurrentModificationException。因此，面对并发修改，迭代器会快速而干净地失败，而不是在不确定的时间冒着不确定的风险。

请注意，迭代器的快速失败行为无法阿紫存在不同步的并发修改时做出任何硬性保证。快速失败迭代器会尽最大努力抛出ConcurrentModificationException。因此，不要编写这个异常的程序：迭代器的快速失败行为应仅用于检测错误。

这个类是[Java集合框架的一员](https://docs.oracle.com/javase/8/docs/technotes/guides/collections/index.html)



## 重要字段

```java
//实际存储的key-value键值对的个数
transient int size; 

//阈值，当table == {}时，该值为初始容量（初始容量默认为16）；当table被填充了，也就是为table分配内存空间后，threshold一般为 capacity*loadFactory。HashMap在进行扩容时需要参考threshold，后面会详细谈到
int threshold; 

//负载因子，代表了table的填充度有多少，默认是0.75
final float loadFactor; 

//用于快速失败，由于HashMap非线程安全，在对HashMap进行迭代时，如果期间其他线程的参与导致HashMap的结构发生变化了（比如put，remove等操作），需要抛出异常ConcurrentModificationException
transient int modCount;
```

## 构造方法

```java
HashMap()
创建一个初始容量为16，默认加载因子为0.75的空HashMap

HashMap(int initialCapacity)
创建一个默认加载因子为0.75，自定义容量的空HashMap

HashMap(int initialCapacity, float loadFactor)
创建一个自定义加载因子，自定义容量的空HashMap

HashMap(Map<? extends K , ? extends V> m)
使用与指定Map相同的映射构造一个新的HashMap
```

HashMap有4个构造器，最后一个很少使用，这里就不讲了。其他构造器如果用户没有传入initialCapacity 或者loadFactor这两个参数，会使用默认值，initialCapacity默认为16，loadFactory默认为0.75。

```java
    /**
     * Constructs an empty <tt>HashMap</tt> with the default initial capacity
     * (16) and the default load factor (0.75).
     */
    public HashMap() {
        this.loadFactor = DEFAULT_LOAD_FACTOR; // all other fields defaulted
    }

```

可以看到，无参构造非常简单，只是对加载因子赋了默认值，这个时候HashmMap内部的数组其实还没有被初始化为null。对于使用无参构造创建的HashMap，会在第一次put的时候初始化数组，put方法后面会细讲。

```java
public HashMap(int initialCapacity, float loadFactor) {
　　　　　//此处对传入的初始容量进行校验，最大不能超过MAXIMUM_CAPACITY = 1<<30(2^30)
        //如果初始容量<0，直接抛异常
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal initial capacity: " +
                                               initialCapacity);
        //初始容量最大不能超过MAXIMUM_CAPACITY = 1<<30(2^30)                                      
        if (initialCapacity > MAXIMUM_CAPACITY)
            initialCapacity = MAXIMUM_CAPACITY;
        //如果加载因子<0或者不是浮点数,抛异常
        if (loadFactor <= 0 || Float.isNaN(loadFactor))
            throw new IllegalArgumentException("Illegal load factor: " +
                                               loadFactor);
        //对初始容量赋值
        this.loadFactor = loadFactor;
        //对阔值赋值
        this.threshold = tableSizeFor(initialCapacity);
}

```

tableSizeFor()方法是JDK8出现了，它的作用是返回返回**大于输入参数且最近的2的整数次幂的数**。比如输入3，则返回4；输入5，则返回8。这里的算法很是巧妙，对于性能有很大提升，感兴趣可以看这篇博客[Java8 HashMap之tableSizeFor](https://www.cnblogs.com/loading4/p/6239441.html)

```java
    /**
     * Returns a power of two size for the given target capacity.
     */
    static final int tableSizeFor(int cap) {
        int n = cap - 1;
        n |= n >>> 1;
        n |= n >>> 2;
        n |= n >>> 4;
        n |= n >>> 8;
        n |= n >>> 16;
        return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
    }

```


## put()

```java
public V put(K key, V value) {
  //首先对key进行了Hash，然后直接调用putVal()方法
  return putVal(hash(key), key, value, false, true); 
}

/**
 * Implements Map.put and related methods 
 * 
 * @param hash 键的哈希值
 * @param key  键
 * @param value 值
 * @param onlyIfAbsent 如果为true，不改变已经存在的值
 * @param evict 如果为true，处于创建模式.
 * @return 值
 */
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,boolean evict) {
  //申明变量 tab:临时数组 p:数组中的节点 n:存放老的容量 i:tab数组的下表
  Node<K,V>[] tab; Node<K,V> p; int n, i;
  //如果table为null或者长度为0，进行初始化分配大小
  if ((tab = table) == null || (n = tab.length) == 0)
    n = (tab = resize()).length;
  //(n - 1) & hash 计算出下标，如果该位置为null 说明没有碰撞，将value封装为一个新的Node并赋值
  if ((p = tab[i = (n - 1) & hash]) == null)
    tab[i] = newNode(hash, key, value, null);
  else { //反之，碰撞了
    Node<K,V> e; K k;
    //首先判断key是否存在，如果是，覆盖原来的值
    if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
      e = p;
    //判断是否为红黑树
    else if (p instanceof TreeNode)
      e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
    else { //是链表
      for (int binCount = 0; ; ++binCount) {
        if ((e = p.next) == null) {
          //将next指向新的节点
          p.next = newNode(hash, key, value, null);
          //binCount >= TREEIFY_THRESHOLD - 1 binCount>=7,链表长度为8时,转变为红黑树,结束循环
          if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
            treeifyBin(tab, hash);
          break;  
        }
        //如果链表中已经存在该key，结束循环
        if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
          break;
        //将e赋值给p，此处没明白为什么，p变量后面没有在使用过
        p = e;
     }
  }  
    if (e != null) { // existing mapping for key
       V oldValue = e.value;
       if (!onlyIfAbsent || oldValue == null) ////根据规则选择是否覆盖value
          e.value = value;
       afterNodeAccess(e);
       return oldValue;
    }
  }
  //fail-fast相关，迭代时会保存一份modCount，每次遍历都会比较该值和保存的值是否相等，不相等则抛出异常  
  ++modCount;
  //如果size >阔值，扩容
  if (++size > threshold)
  resize();
  afterNodeInsertion(evict);
  return null; 
}
    
```

put()方法涉及的成员变量或成员方法

### 成员变量transient Node<K,V>[] table
table是HashMap用来实际存放元素的数组，它在首次使用时会被初始化。它的长度始终是2的幂次方。在某些操作中长度可能为0。

```java
    /**
     * HashMap用来实际存放元素的数组
     */
    transient Node<K,V>[] table;

```


### 成员变量阔值threshold

```
    /**
     * 触发扩容的值 (容量 * 加载因子).
     *
     * @serial
     */
    int threshold;

```

### 静态方法hash()

```
    static final int hash(Object key) {
        int h;
        //先取key的hashCode,然后和其低16位进行异或操作
        return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
    }

```
我们知道HashMap的容量是2的幂次方，那么`newCap - 1`的高位应该全部为`0`。如果`e.hash`值只用自身的`hashcode`的话，那么`index`只会和`e.hash`低位做`&`操作。这样一来，`index`的值就只有低位参与运算，高位毫无存在感，从而会带来哈希冲突的风险。所以在计算`key`的哈希值的时候，用其自身`hashcode`值与其低`16`位做异或操作。这也就让高位参与到`index`的计算中来了，即降低了哈希冲突的风险又不会带来太大的性能问题。--[出自掘金，作者：特立独行的猪手](https://juejin.im/post/58f2f47061ff4b0058f4b7cc#heading-9)


### 方法resize()

```
    /**
     * Initializes or doubles table size.  If null, allocates in
     * accord with initial capacity target held in field threshold.
     * Otherwise, because we are using power-of-two expansion, the
     * elements from each bin must either stay at same index, or move
     * with a power of two offset in the new table.
     *
     * @return the table
     */
    final Node<K,V>[] resize() {
        //保存一份老的数组
        Node<K,V>[] oldTab = table;
        //老数组的容量，如果老数组为null，则是0，否则取length
        int oldCap = (oldTab == null) ? 0 : oldTab.length;
        //保存一份老的阔值
        int oldThr = threshold;
        //初始化新的容量和阔值
        int newCap, newThr = 0;
        //如果老的容量>0
        if (oldCap > 0) {
            //如果老的容量达到了最大值，不扩容，并且将阔值设置为了Integer的最大值2的31次方-1
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = Integer.MAX_VALUE;
                return oldTab;
            }else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                //首先将老的容量*2赋值给新的容量，然后判断新的容量<MAXIMUM_CAPACITY 并且老的容量大于16，将阔值*2     
                newThr = oldThr << 1; // double threshold
        }else if (oldThr > 0) // 如果老的数组容量<=0，但是阔值>0，直接将阔值赋值给新的容量
            newCap = oldThr;
        else {               // 初始化
            //新的容量为DEFAULT_INITIAL_CAPACITY 16
            newCap = DEFAULT_INITIAL_CAPACITY;
            //新的阔值为0.75 * 16 = 12
            newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
        }
        if (newThr == 0) {
            //防止阔值为0，比较好奇这种情况什么时候会出现，知道的同学还请不吝赐教
            float ft = (float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                      (int)ft : Integer.MAX_VALUE);
        }
        //将新的阔值赋值给成员变量
        threshold = newThr;

        //下面是将创建一个新的Node数组，并将老的数组里面的元素赋值到新的数组，这里不详细解读了。
        @SuppressWarnings({"rawtypes","unchecked"})
            Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
        table = newTab;
        if (oldTab != null) {
            for (int j = 0; j < oldCap; ++j) {
                Node<K,V> e;
                if ((e = oldTab[j]) != null) {
                    oldTab[j] = null;
                    if (e.next == null)
                        newTab[e.hash & (newCap - 1)] = e;
                    else if (e instanceof TreeNode)
                        ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                    else { // preserve order
                        Node<K,V> loHead = null, loTail = null;
                        Node<K,V> hiHead = null, hiTail = null;
                        Node<K,V> next;
                        do {
                            next = e.next;
                            if ((e.hash & oldCap) == 0) {
                                if (loTail == null)
                                    loHead = e;
                                else
                                    loTail.next = e;
                                loTail = e;
                            }
                            else {
                                if (hiTail == null)
                                    hiHead = e;
                                else
                                    hiTail.next = e;
                                hiTail = e;
                            }
                        } while ((e = next) != null);
                        if (loTail != null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
                        if (hiTail != null) {
                            hiTail.next = null;
                            newTab[j + oldCap] = hiHead;
                        }
                    }
                }
            }
        }
        return newTab;
    }
```

## get()

```java
    public V get(Object key) {
        Node<K,V> e;
        return (e = getNode(hash(key), key)) == null ? null : e.value;
    }

```
使用getNode()方法取值，没有返回null

```java
final Node<K,V> getNode(int hash, Object key) {
    Node<K,V>[] tab; Node<K,V> first, e; int n; K k;

    //判断是否有元素，没有返回null
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (first = tab[(n - 1) & hash]) != null) {
        //每次都会check第一个元素是否命中，命中直接返回
        if (first.hash == hash && // always check first node
            ((k = first.key) == key || (key != null && key.equals(k))))
            return first;
        //如果有下一个元素    
        if ((e = first.next) != null) {
            //如果是红黑树，从红黑树中取值
            if (first instanceof TreeNode)
                return ((TreeNode<K,V>)first).getTreeNode(hash, key);
            //遍历链表，直到取到值    
            do {
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    return e;
            } while ((e = e.next) != null);
        }
    }
    return null;
}
```


# 参考:
![https://www.cnblogs.com/chengxiao/p/6059914.html](https://www.cnblogs.com/chengxiao/p/6059914.html)
[https://juejin.im/post/5aa47ef2f265da23a0492cc8#heading-4](https://juejin.im/post/5aa47ef2f265da23a0492cc8#heading-4)
[https://juejin.im/post/58f2f47061ff4b0058f4b7cc#heading-7](https://juejin.im/post/58f2f47061ff4b0058f4b7cc#heading-7)
[https://docs.oracle.com/javase/8/docs/api/](https://docs.oracle.com/javase/8/docs/api/)

