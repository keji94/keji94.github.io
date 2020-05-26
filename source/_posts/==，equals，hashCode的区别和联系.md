---
layout: post
title: ==，equals，hashCode的区别和联系
date: 2019-03-16 19:40:36
categories:
  - 基础
---

## == 和equals

== 比较的是对象在内存的地址。equals()定义在Object中。
```java
public boolean equals(Object obj) {
　　return (this == obj);
}
```
这意味着所有对象都有equals()方法,并且默认情况下equals()方法和==一样比较的是对象在内存的地址值。
一般引用数据类型之间的比较，需要重写equals，让其比较对象的字段值。

<!-- more -->

## hashCode()方法的作用
```
public native int hashCode();
```
hashCode()方法注释翻译:

返回该对象的哈希码值。支持此方法是为了提高哈希表（例如 java.util.Hashtable 提供的哈希表）的性能。

hashCode的的常规协定是:

- 在 Java 应用程序执行期间，在对同一对象多次调用 hashCode 方法时，必须一致地返回相同的整数，前提是将对象进行 equals 比较时所用的信息没有被修改。从某一应用程序的一次执行到同一应用程序的另一次执行，该整数无需保持一致。
- 如果根据equals(Object)方法两个对象相等，那么对两个对象调用hashCode方法必须产生相同的整数结果。
- 如果两个对象根据equals(java.lang.Object)方法是不相等的，那么调用这两个对象上的hashCode方法必须产生不同的整数结果。但是，程序员应该意识到，为不相等的对象生成不同的整数结果可能会提高哈希表的性能。

实际上，由 Object 类定义的 hashCode 方法确实会针对不同的对象返回不同的整数。（这一般是通过将该对象的内部地址转换成一个整数来实现的，但是 JavaTM 编程语言不需要这种实现技巧。）


注意这一句话：
    “支持此方法是为了提高哈希表（例如 java.util.Hashtable 提供的哈希表）的性能。”

也就是说，虽然每个Java类都包含hashCode() 函数。但是，仅仅当创建并某个“类的散列表”时(比如HashMap<User>)，该类的hashCode() 才有用(作用是：确定该类的每一个对象在散列表中的位置)；其它情况下(例如，创建类的单个对象，或者创建类的对象数组等等)，类的hashCode() 没有作用。

上面的散列表，指的是：Java集合中底层是散列表的类，如HashMap，Hashtable，HashSet。

关于散列表更过详细的介绍，可以参考[哈希表、Java中HashMap](https://blog.csdn.net/u010297957/article/details/51974340)

## equals()和hashCode()的区别和联系

面试的时候，经常会被问到，为什么重写equals方法的时候需要重写hashCode()？我们来看一个只重写equals的demo
```java
import java.util.HashSet;
import java.util.Objects;

import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

/**
 *
 * @author keji
 * @version $Id: HashCodeAndEquals.java, v 0.1 2018/12/12 6:40 PM keji Exp $
 */
public class HashCodeAndEquals {

    public static void main(String[] args) {

        User p1 = new User(100,"eee");
        User p2 = new User(100,"eee");
        User p3 = new User(200,"aaa");

        HashSet<User> hashSet = new HashSet<>();
        hashSet.add(p1);
        hashSet.add(p2);
        hashSet.add(p3);

        System.out.printf("p1.equals(p2) : %s; p1(%d) p2(%d)\n", p1.equals(p2), p1.hashCode(), p2.hashCode());
        System.out.printf("set:%s\n", hashSet);
    }

    private static class User{

        private int age;

        private String name;

        public User(int age, String name) {
            this.age = age;
            this.name = name;
        }

        public int getAge() {
            return age;
        }

        public void setAge(int age) {
            this.age = age;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) {
                return true;
            }
            if (o == null || getClass() != o.getClass()) {
                return false;
            }
            User user = (User)o;
            return age == user.age && Objects.equals(name, user.name);
        }

        @Override
        public String toString() {
            return ToStringBuilder.reflectionToString(this, ToStringStyle.SHORT_PREFIX_STYLE);
        }
    }
}

输出结果:
p1.equals(p2) : true; p1(189568618) p2(793589513)
set:[HashCodeAndEquals.User[age=100,name=eee], HashCodeAndEquals.User[age=100,name=eee], HashCodeAndEquals.User[age=200,name=aaa]]
```
可以看到，在只重写equals，没有重写hashcode的情况下。equals相等，但是hashcode不相等，导致HashSet中仍然有重复元素：p1和p2。

当在原来的基础上，重写HashCode，再次执行main()
```
@Override
public int hashCode() {
　　return Objects.hash(age, name);
}

输出结果如下：
p1.equals(p2) : true; p1(104354) p2(104354)
set:[HashCodeAndEquals.User[age=100,name=eee], HashCodeAndEquals.User[age=200,name=aaa]]
```

所有，当我们在HashMap,HashTable,HashSet等这些底层使用散列表的数据结构时，如果我们只重写equals()而不重写hashCode()，并不能很好的利用他们的特性。

但是，当我们明确对象不会再HashMap,HashTable,HashSet等这些数据结构中使用时，我们不重写hashCode()写是可以的。
```java
User p1 = new User(100,"eee");
User p2 = new User(100,"eee");
User p3 = new User(200,"aaa");

ArrayList<User> list1 = new ArrayList<>();
list1.add(p1);
list1.add(p2);
list1.add(p3);
ArrayList<User> list2 = new ArrayList<>();
list2.add(p1);
list2.add(p2);
list2.add(p3);
System.out.printf("p1.equals(p2) : %s; p1(%d) p2(%d)\n", p1.equals(p2), p1.hashCode(), p2.hashCode());
System.out.printf("p1.equals(p3) : %s; p1(%d) p3(%d)\n", p1.equals(p3), p1.hashCode(), p3.hashCode());
System.out.printf("list1.equals(list2) :%s\n",list1.equals(list2));

输出结果：
p1.equals(p2) : true; p1(104354) p2(104354)
p1.equals(p3) : false; p1(104354) p3(103482)
list1.equals(list2) :true
```

关于HashCode和equals的区别和联系，网络上有这样一个结论:
当equals相等时,HashCode一定相等。
当HashCode相等时，equals不一定相等。

这个结论不能说它是错的，但是它有一个**前提是对equals和hashCode()进行了重写**。

重写equals的同时重写hashCode(反之亦然)，这是一种规范。虽然前面说过如果对象不存储在HashMap、HashSet、HashTab等这些对象中时，hashCode是无用的，但是谁敢在设计这个对象的时候保证该对象以后不会再这些数据结构中使用？

综上所述，重写equals的时候，要重写hashCode方法。




