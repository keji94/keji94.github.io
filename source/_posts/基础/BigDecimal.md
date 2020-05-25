---
title: BigDecimal使用案例
author: keji
categories:
  - 基础
date: 2019-03-11 19:40:36
---
# 创建BigDecimal对象
创建BigDecimal对象常用的方式有2种：
```java
BigDecimal a = new Bigdecimal(1);
BigDecimal a1 = BigDecimal.valueOf(1);
```
**不推荐**使用new 关键字创建Bigdecimal对象。原因是当new 的值是一个小数的时候，其真实的值并不是我们想要的值
```java
BigDecimal b = new BigDecimal(1.1);
BigDecimal b1 = BigDecimal.valueOf(1.1);
System.out.println("new的值b: "+b);
System.out.println("valueOf()的值b1: "+b1);
```
输出:
```
1.100000000000000088817841970012523233890533447265625
valueOf()的值b1: 1.1
```
这在比较大小的时候，很可能出现意想不到的结果。

<!-- more -->

例如:

```java
BigDecimal a = new BigDecimal(1.1);
String b = "1.1";
System.out.println(a.toString().equals(b)); //fasle
```

如果不注意，很可能产生bug。

# 加法
加法的方法有两种，方法签名如下:
```java
public BigDecimal add(BigDecimal augend)
public BigDecimal add(BigDecimal augend, MathContext mc)
```

MathContext 用于指定精度和舍入模式，具体查看[官方javadoc](https://docs.oracle.com/javase/7/docs/api/java/math/MathContext.html)

demo:
```java
BigDecimal a = BigDecimal.valueOf(1);
BigDecimal b = BigDecimal.valueOf(1.5);
BigDecimal c = BigDecimal.valueOf(1.4);

BigDecimal addResult = a.add(b);
BigDecimal addResult1 = a.add(b,new MathContext(2));
BigDecimal addResult2 = a.add(b,new MathContext(1));
BigDecimal addResult3 = a.add(c,new MathContext(1));

System.out.println("addResult: "+addResult);
System.out.println("addResult1: "+addResult1);
System.out.println("addResult2: "+addResult2);
System.out.println("addResult3: "+addResult3);
```
result:
```java
addResult: 2.5
addResult1: 2.5
addResult2: 3
addResult3: 2
```

mc 设置保留几位小数，舍入按四舍五入

# 减法
方法签名如下：
```java
public BigDecimal subtract(BigDecimal subtrahend)
public BigDecimal subtract(BigDecimal subtrahend, MathContext mc)
```

demo：
```java
BigDecimal a = BigDecimal.valueOf(1);
BigDecimal b = BigDecimal.valueOf(1.5);
BigDecimal c = BigDecimal.valueOf(1.4);

BigDecimal subtract = a.subtract(b);
BigDecimal subtract1 = a.subtract(b,new MathContext(2));
BigDecimal subtract2 = a.subtract(b,new MathContext(1));
BigDecimal subtract3 = a.subtract(c,new MathContext(1));

System.out.println("subtract: "+subtract);
System.out.println("subtract1: "+subtract1);
System.out.println("subtract2: "+subtract2);
System.out.println("subtract3: "+subtract3);
```

result：
```java
subtract: -0.5
subtract1: -0.5
subtract2: -0.5
subtract3: -0.4
```

# 乘法：
方法签名:
```java
public BigDecimal multiply(BigDecimal multiplicand)
public BigDecimal multiply(BigDecimal multiplicand, MathContext mc)
```

demo:
```java
BigDecimal a = BigDecimal.valueOf(1);
BigDecimal b = BigDecimal.valueOf(1.5);
BigDecimal c = BigDecimal.valueOf(1.4);

BigDecimal multiply = a.multiply(b);
BigDecimal multiply1 = a.multiply(b,new MathContext(2));
BigDecimal multiply2 = a.multiply(b,new MathContext(1));
BigDecimal multiply3 = a.multiply(c,new MathContext(1));

System.out.println("multiply: "+multiply);
System.out.println("multiply1: "+multiply1);
System.out.println("multiply2: "+multiply2);
System.out.println("multiply3: "+multiply3);
```

result:
```java
multiply: 1.5
multiply1: 1.5
multiply2: 2
multiply3: 1
```

# 除法:
```java
public BigDecimal divide(BigDecimal divisor)
public BigDecimal divide(BigDecimal divisor, MathContext mc)
public BigDecimal divide(BigDecimal divisor, int roundingMode)
public BigDecimal divide(BigDecimal divisor, RoundingMode roundingMode)
public BigDecimal divide(BigDecimal divisor, int scale, RoundingMode roundingMode)
public BigDecimal divide(BigDecimal divisor, int scale, int roundingMode)
```
其中 public BigDecimal divide(BigDecimal divisor) 不推荐使用。idea警告如下:
```
Inspection info: Reports calls to divide() or setScale() without a rounding mode argument. Such calls can lead to an ArithmeticException when the exact value cannot be represented in the result (e.g. because it has a non-terminating decimal expansion). Specifying a rounding mode prevents the ArithmeticException.

翻译:
检查信息:报告调用divide()或setScale()，而不带舍入模式参数。当结果中不能表示精确值时，这种调用可能导致算术异常(例如，因为它具有无限的十进制展开)。指定舍入模式可以防止算术异常。

简单点说就是除不尽的时候会报错
```

所以用除法的时候，我们需要指定其舍入模式。推荐使用:
```java
public BigDecimal divide(BigDecimal divisor, int scale, RoundingMode roundingMode)
public BigDecimal divide(BigDecimal divisor, int scale, int roundingMode)
```
指定舍入模式，和保留几位小数

demo:
```java
BigDecimal divide = a.divide(b, 2, BigDecimal.ROUND_HALF_UP);
System.out.println("divide: "+divide);
```