java集合系列之JDK8CopyOnWriteArrayList源码解析

# 概述

CopyOnWriteArrayList是java.util.concurrent包中的一员，是ArrayList的线程安全版本。其实现原理正如它的类名描述的一样，在进行修改的时候，复制一份数据为新数组，并在新数组上面修改，最后将原来的数组引用指向新数组。

# 构造方法

CopyOnWriteArrayList拥有三个构造函数，分别是空参构造、传递一个集合的构造、传递一个数组的构造,下面对这三个构造函数一一讲解

## public CopyOnWriteArrayList()

```java
/**
　* 构造一个空的list
　*/
public CopyOnWriteArrayList() {
　　setArray(new Object[0]);
}

/**
　* Sets the array.
　*/
final void setArray(Object[] a) {
　　array = a;
}
```

空参构造就是创建了一个新的长度为0的Object数组，并且将该数组赋值给使用volatile修饰的成员变量**array**

```java
private transient volatile Object[] array;
```

## public CopyOnWriteArrayList(Collection<? extends E> c)

```java
/**
　* 使用特定的集合元素创建
　*
　* @param c 集合元素
　* @throws NullPointerException 如果元素为空，抛出NPE
　*/
public CopyOnWriteArrayList(Collection<? extends E> c) {
　　Object[] elements;
　　if (c.getClass() == CopyOnWriteArrayList.class)
　　//如果传递的集合是CopyOnWriteArrayList类，直接调用getArray()返回成员变量array的值
　　　　elements = ((CopyOnWriteArrayList<?>)c).getArray();
　　else {
　　//如果不是，调用toArray()方法转换为数组
　　　　elements = c.toArray();
　　　　if (elements.getClass() != Object[].class)
　　　// c.toArray 返回的可能不是Object[]数组,如果不是，将数组拷贝到Object数组
　　　　　　elements = Arrays.copyOf(elements, elements.length, Object[].class);
　　}
　　//设置成员变量的值
　　setArray(elements);
}
```

该构造方法首先将集合转换为数组，然后赋值给成员变量array。

## public CopyOnWriteArrayList(E[] toCopyIn)

```java
/**
　* 使用指定数组构造
　*
　* @param toCopyIn the array (a copy of this array is used as the
　*        internal array)
　* @throws NullPointerException if the specified array is null
　*/
public CopyOnWriteArrayList(E[] toCopyIn) {
　　setArray(Arrays.copyOf(toCopyIn, toCopyIn.length, Object[].class));
}
```

给构造方法是将传递进来的数组通过拷贝的方式复制到Object数组，然后赋值给成员变量array。

# 方法解析

## add()

```java
/**
　* Appends the specified element to the end of this list.
　*
　* @param e element to be appended to this list
　* @return {@code true} (as specified by {@link Collection#add})
　*/
public boolean add(E e) {
    //获取可重入锁锁
　　final ReentrantLock lock = this.lock;
　　//加锁
　　lock.lock();
　　try {
　　　　//获取旧数组的元素以及长度
　　　　Object[] elements = getArray();
　　　　int len = elements.length;
　　　　//创建一个新的数组,长度为原来的长度+1，将旧数组的元素拷贝到新的数组
　　　　Object[] newElements = Arrays.copyOf(elements, len + 1);
　　　　//将要添加的元素放在新数组最后
　　　　newElements[len] = e;
　　　　//将引用指向新的数组，旧数组被GC回收
　　　　setArray(newElements);
　　　　return true;
　　} finally {
　　　　//释放锁
　　　　lock.unlock();
　　}
}
```

## remove()

```java
/**
　* 删除指定数组指定位置上的元素，并且返回被删除的元素
　*
　* @throws IndexOutOfBoundsException {@inheritDoc}
　*/
public E remove(int index) {
　　//获取锁
　　final ReentrantLock lock = this.lock;
   //加锁
　　lock.lock();
　　try {
　　　　//获取旧数组的元素和长度
　　　　Object[] elements = getArray();
　　　　int len = elements.length;
　　　　//调用get()方法获取指定索引的元素
　　　　E oldValue = get(elements, index);
　　　　int numMoved = len - index - 1;
　　　　if (numMoved == 0)
　　　　　　//如果删除的是最后一个元素，直接copy第一个元素到倒数第一个元素为一个新的数组
　　　　　　setArray(Arrays.copyOf(elements, len - 1));
　　　　else {
　　　　　　//如果不是最后一个元素，分为两步拷贝
　　　　　　Object[] newElements = new Object[len - 1];
　　　　　　//拷贝被删除元素所在位置的前半段元素
　　　　　　System.arraycopy(elements, 0, newElements, 0, index);
　　　　　　//拷贝被删除元素所在位置的后半段元素
　　　　　　System.arraycopy(elements, index + 1, newElements, index,
　　　　　　　　　　　　　　　numMoved);
　　　　　　//设置值
　　　　　　setArray(newElements);
　　　　}
　　　　return oldValue;
　　} finally {
　　　　//释放锁
　　　　lock.unlock();
　　}
}
```

## get()

```java
public E get(int index) {
　　return get(getArray(), index);
}

final Object[] getArray() {
　　return array;
}

private E get(Object[] a, int index) {
　　return (E) a[index];
}
```

get()的实现很简单，就是返回”volatile数组“中的第index个元素。

## iterator()

```java
public Iterator<E> iterator() {
　　return new COWIterator<E>(getArray(), 0);
}

static final class COWIterator<E> implements ListIterator<E> {
        /** 数组快照 */
        private final Object[] snapshot;
        /** 游标  */
        private int cursor;

        private COWIterator(Object[] elements, int initialCursor) {
            cursor = initialCursor;
　　　　　　　//保存数组的快照
            snapshot = elements;
        }

        public boolean hasNext() {
            return cursor < snapshot.length;
        }

        public boolean hasPrevious() {
            return cursor > 0;
        }

　　　　　//获取下一个元素
        @SuppressWarnings("unchecked")
        public E next() {
            if (! hasNext())
                throw new NoSuchElementException();
            return (E) snapshot[cursor++];
        }

　　　　　//获取上一个元素
        @SuppressWarnings("unchecked")
        public E previous() {
            if (! hasPrevious())
                throw new NoSuchElementException();
            return (E) snapshot[--cursor];
        }

        public int nextIndex() {
            return cursor;
        }

        public int previousIndex() {
            return cursor-1;
        }

        /**
         * 不支持remove
         */
        public void remove() {
            throw new UnsupportedOperationException();
        }

        /**
         * 不支持set
         */
        public void set(E e) {
            throw new UnsupportedOperationException();
        }

        /**
         * 不支持add
         */
        public void add(E e) {
            throw new UnsupportedOperationException();
        }

        @Override
        public void forEachRemaining(Consumer<? super E> action) {
            Objects.requireNonNull(action);
            Object[] elements = snapshot;
            final int size = elements.length;
            for (int i = cursor; i < size; i++) {
                @SuppressWarnings("unchecked") E e = (E) elements[i];
                action.accept(e);
            }
            cursor = size;
        }
    }
```

- 创建迭代器的时候, 会保存数组元素的快照（有一个引用指向原数组）。
- COWIterator不支持修改元素的操作。例如，对于remove(), set(), add()操作都会抛出UnsupportedOperationException！

# 总结
1.CopyOnWriteArrayList是线程安全的，通过volatile和互斥锁以及写时复制保存线程安全。
2.修改操作(add、remove、set等)由于需要拷贝数组，性能损耗相对比较大。
3.使用迭代器进行遍历的速度很快，并且不会与其他线程发生冲突。迭代过程如果有修改操作会抛出UnsupportedOperationException，而不是ConcurrentModificationException，所以CopyOnWriteArrayList没有fail-fast机制。