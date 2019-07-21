# Java数据结构：数组

# 数组是什么

在计算机科学中，数组数据结构（英语：array data structure），简称数组（英语：Array），是由相同类型的元素（element）的集合所组成的数据结构，分配一块连续的内存来存储。利用元素的索引（index）可以计算出该元素对应的存储地址。

# Java中的数组

在Java中，数组是一种效率最高的存储和随机访问对象引用序列的方式。数组就是一个简单的线性序列，这使得元素访问非常快速。但是为这种速度所付出代价是数组对象大小被固定，并且在其声明周期中不可改变。

数组内的元素既可以是基本数据类型，也可以是引用数据类型。区别在于对象数据保存的是引用，基本类型数组直接保存基本类型的值。

# 数组的创建

```java
//声明一个长度为2的int数组
int[] ints = new int[2];
//初始化一个保存1,2元素的数组
int[] intArr = new int[] {1, 2};
//初始化一个保存1,2,3,4的数组
int[] arr = {1, 2, 3, 4};


//声明一个为初始化的数组，我们没办法做任何事情
User[] userArr;
//声明一个长度为2的User类数组
User[] user = new User[2];
//初始化一个User数组，里面有两个User对象的引用
userArr = new User[] {new User(), new User()};
//初始化一个User数组，里面有两个User对象的引用
User[] userArr2 = {new User(), new User()};
```

# 数组是对象吗？

Java里面的数组到底是什么？

答案是对象。

证据：
```java
int[] arr = {1, 2, 3, 4};
String name = arr.getClass().getSuperclass().getName();
System.out.println(name);
```

输出:java.lang.Object

数组的父类是Object。

Java数组这个对象太特俗了，以至于我们没办法把它当做对象处理，甚至我们都找不到类文件与之对应，但是找不到不代表没有。数组对象并不是从某个类实例化来的，而是由JVM直接创建的，因此查看类名的时候会发现是很奇怪的类似于"[I"这样的样子：

```
int[] arr = {1, 2, 3, 4};
String name = arr.getClass().getName();
System.out.println(name);//
输出：[I

User[] userArr2 = {new User(), new User()};
String userArrClassName = userArr2.getClass().getName();
System.out.println(userArrClassName);
输出:[Lcom.weimai.medical.admin.controller.User;
```

# length返回的是什么？

length只表示数组能够容纳多少元素，也就是说，length是数组的大小，而不是实际存放的元素个数。

# Array类是做什么的？

我们点开Array类看一下。

```
/**
 * The {@code Array} class provides static methods to dynamically create and
 * access Java arrays.
 *
 * <p>{@code Array} permits widening conversions to occur during a get or set
 * operation, but throws an {@code IllegalArgumentException} if a narrowing
 * conversion would occur.
 *
 * @author Nakul Saraiya
 */
```

首先看到这样一段注释，它的第一句就说明了Array类的作用：Array类提供静态方法来创建和访问Java数组。

再看下它的类声明：
```
public final
class Array {}
```

final类，不可修改。看到这里基本可以断定Array类和我们创建数组这个动作毫无关系，并且也不是真正的数组类。

正如类注释说明的那样，Array类可以帮助我们快速操作数组，它更像一个工具类，底层基本都是native方法。

比如：

```java
int[] arr = {1, 2, 3, 4};
//取数组索引为1的元素
System.out.println(Array.get(arr, 1)); //2
//取数组索引为3的元素
System.out.println(Array.get(arr, 3)); //4

```

下面正式回答你的问题:
问题一：
　答案是没有关系，因为Array类是final的，Array类提供了一些静态方法帮助我们创建和访问数组。

问题二：
　在Java中，没有类文件与数组对应，数组是在JVM中动态生成的。

问题三：
　数组的长度，在动态生成的数组对象的对象头里有一个 _length 字段，记录数组长度。获取数组长度是由一条特定的指令arraylength实现。
　
　Array.getLength()和arr.length是一样的效果，代码验证如下:
```
//声明一个容量为2的数组
int[] ints = new int[2];
//指定索引0的值为1
ints[0] = 1;
System.out.println(ints.length); //2
System.out.println(Array.getLength(ints); //2
```

问题四：
　不知道你是指底层JVM的判断还是我们程序员自己判断。感觉应该是指底层JVM，很抱歉，水平有限，我也不清楚，但是感觉和底层的压栈出栈什么的有关系，不知道有没有使用length判断。

希望以上回答能帮到你，关注我的专栏[Java技术栈](https://zhuanlan.zhihu.com/stackjava)，让我们一起成长


