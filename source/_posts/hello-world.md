title: Java8新特性 使用Optional避免NPE
date: 2019-03-12 12:24:01
---
# 前言
相信每一个Java程序员都碰到过NPE异常，每个避免NPE，往往会在代码中写很多if判断，形成代码污染。为了解决这个问题，Google公司著名的Guava项目引入了Optional类，Guava通过使用检查空值的方式来防止代码污染，它鼓励程序员写更干净的代码。受到Google Guava的启发，Optional类已经成为Java 8类库的一部分。

# Optional类介绍
Optional类存在于java.util包中，它是一个用来存放null值或者非null值的容器。如果容器内有值，isPresent()方法返回true,使用get()方法可以取到这个值.
除此之外，还提供了基于对值存在与否的判断的其他方法，比如：
orElse()(如果值不存在，则返回默认值)
ifPresent()(如果值存在，则执行代码块)
需要注意的是，这是一个“基于值(value-based)”的类，使用对身份敏感的操作，比如(比较符号'==',一致性哈希或同步)都可能出现意想不到的结果，这类操作应该避免。[什么是value-based class?](https://docs.oracle.com/javase/8/docs/api/java/lang/doc-files/ValueBased.html)

# Optional类的方法
![title](https://keji-image.oss-cn-hangzhou.aliyuncs.com/super-blog/2018-10-20_172111.png)
注:
第一排:m:表示方法,左下角有个白色标志的表示static方法 f:表示变量
第二排:上锁表示为private方法,解锁表示public
第三排:方法或变量名称
第四排:方法返回值

我们一个个看
## empty() 创建一个空的Optional对象
public static<T> Optional<T> empty()
返回一个Optional对象，其存储的值是null
```
Optional<Object> emptyOptional = Optional.empty();
System.out.println(emptyOptional);

result:Optional.empty
```
注意判断Optional值是否为Null,不要使用null == Optional.empty(),而应该使用isPresent()

## of() 创建一个不为空的Optional对象，如果值为null，抛出NPE
```
Optional<Object> optional = Optional.of(1);
System.out.println(optional);

result:Optional[1]
```

## ofNullable()创建一个可为空的Optional对象
```
Optional<Object> emptyOptional = Optional.ofNullable(null);
Optional<Long> longOptional = Optional.ofNullable(2L);
System.out.println(emptyOptional);
System.out.println(longOptional);

result:
	Optional.empty
	Optional[2]
```
## isPresent() 判断值是否存在
public boolean isPresent()
```
Optional<Object> optional = Optional.of(1);
Optional<Object> emptyOptional = Optional.ofNullable(null);
boolean isPresent = optional.isPresent();
boolean emptyOptionalPresent = emptyOptional.isPresent();
System.out.println(isPresent);
System.out.println(emptyOptionalPresent);

result:
	true
	false
```
## ifPresent() 注意不是isPresent()当值存在的时候，执行传入的代码
```
Optional<Object> optional = Optional.of(1);
optional.ifPresent(e-> System.out.println((Integer)e+1));

result:2
```

## orElse() 如果存在返回原来的值，不存在，则返回指定的值

public T orElse(T other)

```
Optional<Object> optional = Optional.of(1);
Optional<Object> emptyOptional = Optional.empty();
Object orElse = optional.orElse(2);
Object orElse2 = emptyOptional.orElse(2);
System.out.println(orElse);
System.out.println(orElse2);

result:
	1
	2
```

稍微复杂点的例子:
```
public class User {

    private String name;

    private Integer age;

    public User(String name, Integer age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public Integer getAge() {
        return age;
    }
}

List<User> userList = Arrays.asList(new User("李四", 20), new User("张三", 18), new User("王五", 25));

User user = userList.stream().filter(e -> e.getAge() > 25).findFirst().orElse(new User("王老五", 30));
System.out.println(user.getName());

result:王老五
```

## orElseGet() 如果存在，返回原来的值，如果不存在，返回返回函数式接口的结果

public T orElseGet(Supplier<? extends T> other)
和orElse不同的是，这个可以传入一个函数表达式
```
Optional<Object> emptyOptional = Optional.empty();
String name = "王老五";
Object orElseGet = emptyOptional.orElseGet(name::length);
System.out.println(orElseGet);

result:3
```

## orElseThrow 如果存在，返回原来的值，如果不存在，抛出一个指定的异常

public <X extends Throwable> T orElseThrow(Supplier<? extends X> exceptionSupplier) throws X

```
Optional<Object> emptyOptional = Optional.empty();
Object orElseThrow = emptyOptional.orElseThrow(()->new RuntimeException("程序异常"));

result:
Exception in thread "main" java.lang.RuntimeException: 程序异常
...
```

## filter() 按要求返回过滤后的元素，没有返回一个空的Optional对象

public Optional<T> filter(Predicate<? super T> predicate)
```
Optional<Object> optional = Optional.of(1);
Optional<Object> emptyOptional = Optional.empty();
Optional<Object> optionalO = optional.filter(e -> e.equals(1));
Optional<Object> optionalO1 = emptyOptional.filter(e -> e.equals(1));

System.out.println(optionalO);
System.out.println(optionalO1);

result:
	Optional[1]
	Optional.empty
```

## map() 对Optional中保存的值进行函数运算，并返回新的Optional,里面保存的值可以是任何类型
```
User user = new User("李四", 20);
Optional<Integer> optionalInteger = Optional.of(new User("李四", 20)).map(User::getAge);
System.out.println(optionalInteger);

result:Optional[20]
```
## flatMap() 和map(),区别在于，保存的只只能和调用方一样
```
User user = new User("李四", 20);
Optional<User> user1 = userOptional.flatMap(e -> {
		if (e.getAge() > 19) {
				return Optional.of(new User("张三", 21));
		} else {
				return Optional.of(new User("王五", 18));
		}
});

System.out.println(user1.get().getName());

result:张三
```



