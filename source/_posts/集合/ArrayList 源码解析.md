---
layout: post
title: Java集合之ArrayList 源码解析
date: 2019-03-16 19:40:36
categories: 
  - java基础
  - 集合
---

ArrayList是Java最常用的几种数据结构之一， 同时也是面试热点。了解其内部实现原理是非常必要的。

# 创建ArrayList
```java
ArrayList<Object> list1 = new ArrayList<>();
ArrayList<Object> list2 = new ArrayList<>(16);
ArrayList<Object> list3 = new ArrayList<>(list2);
```
ArrayList为我们提供了三个构造方法。我们创建ArrayList对象除了使用空参构造，还可以传递一个int数值，指定初始容量或者传递一个集合。
<!-- more -->
## 空参构造ArrayList()
```java
/**
　* Constructs an empty list with an initial capacity of ten.
　*/
public ArrayList() {
　　this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
}
```
空参构造非常简单，它会为我们创建一个空的集合。elementData成员变量是用来存放数据的对象,是一个Object[]，DEFAULTCAPACITY_EMPTY_ELEMENTDATA则是一个空的数组。

```java
/**
　* Shared empty array instance used for default sized empty instances. We
　* distinguish this from EMPTY_ELEMENTDATA to know how much to inflate when
　* first element is added.
　*/
private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};
```

注意DEFAULTCAPACITY_EMPTY_ELEMENTDATA类型为static final，表明其在内存中只有一份且禁止修改。

```java
/**
　* The array buffer into which the elements of the ArrayList are stored.
　* The capacity of the ArrayList is the length of this array buffer. Any
　* empty ArrayList with elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA
　* will be expanded to DEFAULT_CAPACITY when the first element is added.
　*/
transient Object[] elementData; // non-private to simplify nested class access
```
注意elementData使用transient修饰。表明在采用Java默认的序列化机制的时候，被该关键字修饰的属性不会被序列化。而ArrayList类实现了java.io.Serializable接口，即采用了Java默认的序列化机制。但是elementData在网络传输的时候不序列化肯定是不行的，翻看源码会发现ArrayList自己实现了序列化和反序列化的方法。
```java
/**
　* Save the state of the <tt>ArrayList</tt> instance to a stream (that
　* is, serialize it).
　*
　* @serialData The length of the array backing the <tt>ArrayList</tt>
　*             instance is emitted (int), followed by all of its elements
　*             (each an <tt>Object</tt>) in the proper order.
　*/
private void writeObject(java.io.ObjectOutputStream s)
　　throws java.io.IOException{
　　// Write out element count, and any hidden stuff
　　int expectedModCount = modCount;
　　s.defaultWriteObject();

　　// Write out size as capacity for behavioural compatibility with clone()
　　s.writeInt(size);

　　// Write out all elements in the proper order.
　　for (int i=0; i<size; i++) {
　　　　s.writeObject(elementData[i]);
　　}

　　if (modCount != expectedModCount) {
　　　　throw new ConcurrentModificationException();
　　}
}

/**
　* Reconstitute the <tt>ArrayList</tt> instance from a stream (that is,
　* deserialize it).
　*/
private void readObject(java.io.ObjectInputStream s)
　　throws java.io.IOException, ClassNotFoundException {
　　elementData = EMPTY_ELEMENTDATA;

　　// Read in size, and any hidden stuff
　　s.defaultReadObject();

　　// Read in capacity
　　s.readInt(); // ignored

　　if (size > 0) {
　　　　// be like clone(), allocate array based upon size not capacity
　　　　ensureCapacityInternal(size);

　　　　Object[] a = elementData;
　　　　// Read in all elements in the proper order.
　　　　for (int i=0; i<size; i++) {
　　　　　　a[i] = s.readObject();
　　　　}
　　}
}
```

空参构造底层为我们创建的是一个空的数组，初始容量是0，这肯定没法存东西的，必然会使用的时候进行扩容。我们来看下add()方法
```java
/**
　* Appends the specified element to the end of this list.
　*
　* @param e element to be appended to this list
　* @return <tt>true</tt> (as specified by {@link Collection#add})
　*/
public boolean add(E e) {
　　ensureCapacityInternal(size + 1);  // Increments modCount!!
　　elementData[size++] = e;
　　return true;
}
```

首先，调用了ensureCapacityInternal()方法，入参传递了size+1，size+1表示elementData所需要的最小长度。这里的size变量，是用来记录ArrayList包含元素的多少的，初始值为0，我们调用ArrayList的size()方法，返回的就是该字段。
```java
/**
　* The size of the ArrayList (the number of elements it contains).
　*
　* @serial
　*/
private int size;
```
看下ensureCapacityInternal()的源码:
```java
private void ensureCapacityInternal(int minCapacity) {
    ensureExplicitCapacity(calculateCapacity(elementData, minCapacity));
}

```
简单点说，该方法做了一件事情，判断当前数组能不能方法即将被添加的元素，如果不能，扩容。

首先调用了calculateCapacity()计算容量，代码如下:
```java
private static int calculateCapacity(Object[] elementData, int minCapacity) {
    if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
        return Math.max(DEFAULT_CAPACITY, minCapacity);
    }
    return minCapacity;
}
```
如果集合还没有被初始化，则初始化容量为10。如果已经初始化过了，直接返回。
```java
/**
  * Default initial capacity.
  */
private static final int DEFAULT_CAPACITY = 10;
```

调用完calculateCapacity()后，调用ensureExplicitCapacity(),这个方法做了两件事情：
1.将modCount自增
2.如果容量不够，扩容。
```java
private void ensureExplicitCapacity(int minCapacity) {
　　modCount++;

　　// overflow-conscious code
　　if (minCapacity - elementData.length > 0)
　　　　//扩容
　　　　grow(minCapacity);
}
```
我们先将modCount属性放到一边，看下扩容的方法grow()。

```java
/**
　* Increases the capacity to ensure that it can hold at least the
　* number of elements specified by the minimum capacity argument.
　*
　* @param minCapacity the desired minimum capacity
　*/
　private void grow(int minCapacity) {
　　　// overflow-conscious code
　　　int oldCapacity = elementData.length;
　　　int newCapacity = oldCapacity + (oldCapacity >> 1);
　　　if (newCapacity - minCapacity < 0)
　　　　　newCapacity = minCapacity;
　　　if (newCapacity - MAX_ARRAY_SIZE > 0)
　　　　　newCapacity = hugeCapacity(minCapacity);
　　　// minCapacity is usually close to size, so this is a win:
　　　elementData = Arrays.copyOf(elementData, newCapacity);
　}
```
可以看到扩容后的容量为原容量的1.5倍+1。另外网上很多文章说ArrayList是无限扩容的，其实不是，它是有限度的。上面的代码有一个判断:
```java
if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
```
如果扩容后的容量比数组最大容量大，调用hugeCapacity()方法，并将扩容前所需要的最小容量传递的进去。
```java
private static int hugeCapacity(int minCapacity) {
　　if (minCapacity < 0) // overflow
　　　　throw new OutOfMemoryError();
　　return (minCapacity > MAX_ARRAY_SIZE) ?
　　　　Integer.MAX_VALUE :
　　　　MAX_ARRAY_SIZE;
}
```
hugeCapacity方法只在扩容时可能被调用，它的逻辑很简单，先做了个简单的判断，之后执行了一个三元表达式，如果扩容前所需最小容量大于数组最大长度，返回Integer的最大值，否则返回MAX_ARRAY_SIZE,MAX_ARRAY_SIZE的Integer的最大值-8。
```java
/**
　* The maximum size of array to allocate.
　* Some VMs reserve some header words in an array.
　* Attempts to allocate larger arrays may result in
　* OutOfMemoryError: Requested array size exceeds VM limit
　*/
private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
```
int的最大值为2的31次方-1，所以说ArrayList的最大容量为2的31次方-1。
```java
/**
　* A constant holding the maximum value an {@code int} can
　* have, 2<sup>31</sup>-1.
　*/
@Native public static final int   MAX_VALUE = 0x7fffffff;

```
回过头来在看我们调用空参构造创建一个ArrayList，并且第一次调用add()方法时发生了什么？扩容，是的，它会将默认的空数组扩容为一个长度为10的数组。

## 初始化指定集合大小ArrayList(int initialCapacity)

《阿里巴巴Java开发手册》里面建议初始化集合时尽量显示的指定集合大小。为什么？读了上面的源码之后，应该可以知道答案了。
1.节约内存，实际编码中，很多时候我们都可以知道ArrayList里面会放什么元素以及放多少元素。恰当的设置容器大小可以节约内存。
2.避免扩容产生的性能损耗。
比如我知道这个集合要放11个元素，那么我可以将集合的大小初始化为11，这样可以避免在添加第11个元素的时候，ArrayList扩容。

ArrayList的扩容底层调用了native方法System.arraycopy()简单点说就是将原来的数组中的元素拷贝到一个新的更大的数组中去。

看下指定初始容量构造的源码:
```java
/**
　* Constructs an empty list with the specified initial capacity.
　*
　* @param  initialCapacity  the initial capacity of the list
　* @throws IllegalArgumentException if the specified initial capacity
　*         is negative
　*/
public ArrayList(int initialCapacity) {
　　if (initialCapacity > 0) {
　　　　this.elementData = new Object[initialCapacity];
　　} else if (initialCapacity == 0) {
　　　　this.elementData = EMPTY_ELEMENTDATA;
　　} else {
　　　　throw new IllegalArgumentException("Illegal Capacity: "+
　　　　　　　　　　　　　　　　　　　　　　initialCapacity);
　　}
}
```
逻辑非常简单，如果初始容量>0，则创建一个该大小的数组。如果容量为0，则创建一个空数组。如果容量<0，抛出异常。

## 初始化传递集合ArrayList(Collection<? extends E> c)
```java
/**
　* Constructs a list containing the elements of the specified
　* collection, in the order they are returned by the collection's
　* iterator.
　*
　* @param c the collection whose elements are to be placed into this list
　* @throws NullPointerException if the specified collection is null
　*/
public ArrayList(Collection<? extends E> c) {
　　elementData = c.toArray();
　　if ((size = elementData.length) != 0) {
　　　　// c.toArray might (incorrectly) not return Object[] (see 6260652)
　　　　if (elementData.getClass() != Object[].class)
　　　　　　elementData = Arrays.copyOf(elementData, size, Object[].class);
　　} else {
　　　　// replace with empty array.
　　　　this.elementData = EMPTY_ELEMENTDATA;
　　}
}
```
逻辑并不复杂，直接将集合转换为Object数组，赋值给了elementData属性。后面还做了一些保障性操作。

# 添加元素
## 再探add(E e)方法
前面已经看过一点add()方法的源码，知道它首先会确认容量是否够用，如果不够，则进行扩容。注意ArrayList的扩容时机和HashMap有区别，ArrayList只有底层数组已满，不能放下即将存入的对象才会扩容，HashMap的扩容和加载因子有关系，默认情况下，不是容器满了才扩容。
```java
/**
　* Appends the specified element to the end of this list.
　*
　* @param e element to be appended to this list
　* @return <tt>true</tt> (as specified by {@link Collection#add})
　*/
public boolean add(E e) {
　　ensureCapacityInternal(size + 1);  // Increments modCount!!

　　elementData[size++] = e;
　　return true;
}
```

在确保容量够用之后，直接要添加的元素赋值给elementData数组的下一个空间。

## 添加到指定位置add(int index, E element)
```java
/**
　* Inserts the specified element at the specified position in this
　* list. Shifts the element currently at that position (if any) and
　* any subsequent elements to the right (adds one to their indices).
　*
　* @param index index at which the specified element is to be inserted
　* @param element element to be inserted
　* @throws IndexOutOfBoundsException {@inheritDoc}
　*/
public void add(int index, E element) {
　　//检查index是否在已有的数组中
　　if (index > size || index < 0)
　　　　throw new IndexOutOfBoundsException("Index:"+index+",Size:"+size);
　　ensureCapacity(size + 1);//确保对象数组elementData有足够的容量，可以将新加入的元素e加进去
　　System.arraycopy(elementData, index, elementData, index+1, size-index);//将index及其后边的所有的元素整块后移，空出index位置
　　elementData[index] = element;//插入元素
　　size++;//已有数组元素个数+1
}
```
使用这个方法，务必注意index的值需要在已经元素的下标之间。

## 添加所有addAll(Collection<? extends E> c)
```java
/**
　* Appends all of the elements in the specified collection to the end of
　* this list, in the order that they are returned by the
　* specified collection's Iterator.  The behavior of this operation is
　* undefined if the specified collection is modified while the operation
　* is in progress.  (This implies that the behavior of this call is
　* undefined if the specified collection is this list, and this
　* list is nonempty.)
　*
　* @param c collection containing elements to be added to this list
　* @return <tt>true</tt> if this list changed as a result of the call
　* @throws NullPointerException if the specified collection is null
　*/
public boolean addAll(Collection<? extends E> c) {
　　Object[] a = c.toArray();//将c集合转化为对象数组a
　　int numNew = a.length;//获取a对象数组的容量
　　ensureCapacity(size + numNew);//确保对象数组elementData有足够的容量，可以将新加入的a对象数组加进去
　　System.arraycopy(a, 0, elementData, size, numNew);//将对象数组a拷贝到elementData中去
　　size += numNew;//重新设置elementData中已加入的元素的个数
　　return numNew != 0;//若加入的是空集合则返回false
}
```

##添加所有到指定位置addAll(int index, Collection<? extends E> c)
```java
public boolean addAll(int index, Collection<? extends E> c) {
　　rangeCheckForAdd(index);

　　Object[] a = c.toArray();
　　int numNew = a.length;
　　ensureCapacityInternal(size + numNew);  // Increments modCount

　　int numMoved = size - index;
　　if (numMoved > 0)
　　　　System.arraycopy(elementData, index, elementData, index + numNew,
　　　　　　　　　　　　　numMoved);

　　System.arraycopy(a, 0, elementData, index, numNew);
　　size += numNew;
　　return numNew != 0;
}
```

# 删除元素
## 删除指定索引元素 E remove(int index)。
```java
/**
　* Removes the element at the specified position in this list.
　* Shifts any subsequent elements to the left (subtracts one from their
　* indices).
　*
　* @param index the index of the element to be removed
　* @return the element that was removed from the list
　* @throws IndexOutOfBoundsException {@inheritDoc}
　*/
public E remove(int index) {
　　//索引边界检查
　　rangeCheck(index);
   //计数器自增
　　modCount++;
　　//取得被删除元素
　　E oldValue = elementData(index);
　　//计算要移动的索引值
　　int numMoved = size - index - 1;
　　if (numMoved > 0)
　　　　//如果删除的不是最后一个元素，进行数组拷贝
　　　　System.arraycopy(elementData, index+1, elementData, index,
　　　　　　　　　　　　　numMoved);
　　//将最后一个元素置为null，下次gc回收
　　elementData[--size] = null; // clear to let GC do its work
　　//返回被删除的值
　　return oldValue;
}
```
## 删除指定值的元素 remove(Object o)
```java
/**
　* Removes the first occurrence of the specified element from this list,
　* if it is present.  If the list does not contain the element, it is
　* unchanged.  More formally, removes the element with the lowest index
　* <tt>i</tt> such that
　* <tt>(o==null&nbsp;?&nbsp;get(i)==null&nbsp;:&nbsp;o.equals(get(i)))</tt>
　* (if such an element exists).  Returns <tt>true</tt> if this list
　* contained the specified element (or equivalently, if this list
　* changed as a result of the call).
　*
　* @param o element to be removed from this list, if present
　* @return <tt>true</tt> if this list contained the specified element
　*/
public boolean remove(Object o) {
　　if (o == null) {//移除对象数组elementData中的第一个null
　　　　for (int index = 0; index < size; index++)
　　　　　　if (elementData[index] == null) {
　　　　　　　　fastRemove(index);
　　　　　　　　return true;
　　　　　　}
　　} else {//移除对象数组elementData中的第一个o
　　　　for (int index = 0; index < size; index++)
　　　　　　if (o.equals(elementData[index])) {
　　　　　　　　fastRemove(index);
　　　　　　　　return true;
　　　　　　}
　　}
　　return false;
}
```
```java
/*
　* 删除单个位置的元素，是ArrayList的私有方法
　*/
private void fastRemove(int index) {
　　modCount++;
　　int numMoved = size - index - 1;
　　if (numMoved > 0)//删除的不是最后一个元素
　　　　System.arraycopy(elementData, index + 1, elementData, index,numMoved);//删除的元素到最后的元素整块前移
　　elementData[--size] = null; //将最后一个元素设为null，在下次gc的时候就会回收掉了
}
```

remove(Object o)需要遍历数组，remove(int index)不需要，只需要判断索引符合范围即可，所以，通常：后者效率更高。



# 获取元素
## 获取单个元素get(int index)
```java
/**
　* Returns the element at the specified position in this list.
　*
　* @param  index index of the element to return
　* @return the element at the specified position in this list
　* @throws IndexOutOfBoundsException {@inheritDoc}
　*/
public E get(int index) {
　　rangeCheck(index);//检查索引范围
　　return (E) elementData[index];//返回元素，并将Object转型为E
}
```
```java
/**
　* Checks if the given index is in range.  If not, throws an appropriate
　* runtime exception.  This method does *not* check if the index is
　* negative: It is always used immediately prior to an array access,
　* which throws an ArrayIndexOutOfBoundsException if index is negative.
　*/
private void rangeCheck(int index) {
　　if (index >= size)
　　　　throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}
```
注意rangeCheck检查的是size的大小，也就是实际存储元素个数，而不是容器的实际容量。


#遍历元素 iterator()
```java
public Iterator<E> iterator() {
　　　　return new Itr();
　　}
```
Itr是ArryList的一个私有内部类，实现了Iterator接口。
```java
private class Itr implements Iterator<E> {
　　
　　int cursor = 0;//标记位：标记遍历到哪一个元素
　　int expectedModCount = modCount;//标记位：用于判断是否在遍历的过程中，是否发生了add、remove操作

　　//检测对象数组是否还有元素
　　public boolean hasNext() {
　　　　return cursor != size();//如果cursor==size，说明已经遍历完了，上一次遍历的是最后一个元素
　　}

　　//获取元素
　　public E next() {
　　　　checkForComodification();//检测在遍历的过程中，是否发生了add、remove操作
　　　　try {
　　　　　　E next = get(cursor++);
　　　　　　return next;
　　　　} catch (IndexOutOfBoundsException e) {//捕获get(cursor++)方法的IndexOutOfBoundsException
　　　　　　checkForComodification();
　　　　　　throw new NoSuchElementException();
　　　　}
　　}

　　//检测在遍历的过程中，是否发生了add、remove等操作
　　final void checkForComodification() {
　　　　if (modCount != expectedModCount)//发生了add、remove操作,这个我们可以查看add等的源代码，发现会出现modCount++
　　　　　　throw new ConcurrentModificationException();
　　}

　@Override
　@SuppressWarnings("unchecked")
　public void forEachRemaining(Consumer<? super E> consumer) {
　　　Objects.requireNonNull(consumer);
　　　final int size = ArrayList.this.size;
　　　int i = cursor;
　　　if (i >= size) {
　　　　　return;
　　　}
　　　final Object[] elementData = ArrayList.this.elementData;
　　　if (i >= elementData.length) {
　　　　　throw new ConcurrentModificationException();
　　　}
　　　while (i != size && modCount == expectedModCount) {
　　　　　consumer.accept((E) elementData[i++]);
　　　}
　　　// update once at end of iteration to reduce heap write traffic
　　　cursor = i;
　　　lastRet = i - 1;
　　　checkForComodification();
　}
}
```
需要注意的是这里有一个Java集合的fail-fast事件。你可能已经注意到，我们在调用add()、remove()这些修改集合的方法时，都会修改一个属性modCount。而我们在遍历集合时，首先会保存一份modCount，然后在遍历时，将保存的modCount和成员变量modCount对比，如果不一样，说明被集合已经被修改，抛出ConcurrentModificationException，产生fail-fast事件。

#其他
## 设置元素set(int index, E element)
```java
/**
  * 更换特定位置index上的元素为element，返回该位置上的旧值
  */
  public E set(int index, E element) {
      RangeCheck(index);//检查索引范围
      E oldValue = (E) elementData[index];//旧值
      elementData[index] = element;//该位置替换为新值
      return oldValue;//返回旧值
  }
```

## 判断元素是否存在
```java
/**
　* 判断动态数组是否包含元素o
　*/
public boolean contains(Object o) {
　　return indexOf(o) >= 0;
}

/**
　* 返回第一个出现的元素o的索引位置
　*/
public int indexOf(Object o) {
　　if (o == null) {//返回第一个null的索引
　　　　for (int i = 0; i < size; i++)
　　　　　　if (elementData[i] == null)
　　　　　　　　return i;
　　} else {//返回第一个o的索引
　　　　for (int i = 0; i < size; i++)
　　　　　　if (o.equals(elementData[i]))
　　　　　　　　return i;
　　}
　　return -1;//若不包含，返回-1
}

/**
　* 返回最后一个出现的元素o的索引位置
　*/
public int lastIndexOf(Object o) {
　　if (o == null) {
　　　　for (int i = size - 1; i >= 0; i--)
　　　　　　if (elementData[i] == null)
　　　　　　　　return i;
　　} else {
　　　　for (int i = size - 1; i >= 0; i--)
　　　　　　if (o.equals(elementData[i]))
　　　　　　　　return i;
　　}
　　return -1;
}
```

#总结
1.ArrayList的底层是数组，初始容量是10，当数组满了之后，继续添加元素时，会扩容到原来的1.5倍+1。
2.ArrayList保存了一个modCount属性，修改集合的操作都会让其自增。如果在遍历的时候modCount被修改，则会抛出异常，产生fail-fast事件。
3.ArrayList内部还维护了一个size属性，它是用来记录数组中的实际元素个数。
size,modCount，elementData这些成员变量，都注定了ArrayList线程不安全。
4.ArrayList实现了Iterator接口，这表明遍历ArrayList使用普通for循环比使用foreach更快，至于为什么可以参考[ArrayList集合实现RandomAccess接口有何作用？为何LinkedList集合却没实现这接口？](https://blog.csdn.net/weixin_39148512/article/details/79234817)





