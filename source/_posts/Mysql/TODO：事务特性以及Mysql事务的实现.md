---
layout: post
title: 事务特性以及Mysql事务的实现
date: 2019-06-18 15:01:18
categories:
  - mysql
tags:
  - mysql
---


# 事务特性

事务是数据库区别于文件系统的重要特征之一。事务用来保证数据库的完整性--要么都做修改，要么都不做。同时，事务有严格的定义，它必须同时满足四个特性。

**原子性**

原子性是指整个数据库事务是不可分割的工作单位。只有使事务中所有的数据库操作执行都成功，才算整个事务成功。如果事务中任何一个SQL语句执行失败，那么已经执行 成功的SQL语句也必须撒销，数据库状态应该退回到执行事务前的状态。

**一致性(consistency)**

一致性指事务将数据库从一种状态转变为下一种一致的状态。在事务开始之前和事务 结束以后，数据库的完整性约束没有被破坏。

**隔离性(isolation)**

一个事务的影响在该事务提交前对其他事务都不可见——这通过锁来实现

**持久性(durability)**

事务一旦提交，其结果就是永久性的。即使发生宕机等故障，数据库也能将数据恢复。

<!-- more -->


# 事务隔离级别

了解事务隔离级别前，先介绍下数据库在并发读取数据产生的问题。

**脏读**

一个事务可以读到了另外一个还没有提交（commit）事务的数据。

举个例子：
       公司发工资了，把50000元打到我的账号上，但是该事务并未提交，而我正好去查看账户，发现工资已经到账，是50000元整，非常高兴。可是不幸的是，领导发现发给的工资金额不对，是2000元，于是迅速回滚了事务，修改金额后，将事务提交，最后我实际的工资只有2000元，空欢喜一场。

脏读是两个并发的事务，“事务A：领导发工资”、“事务B：我查询工资账户”，事务B读取了事务A尚未提交的数据。

**不可重复读**

一个事务A需要多次读取一个数据，在这个事务还没有提交前，存在另外的事务B对改数据进行了修改，导致事务A前后读取的数据不一致。

**幻读**

事务A需要修改表中的所有数据行，与此同时，事务B需要往表中插入新的数据。事务A在修改完毕后发现还有数据没有被修改，就好象发生了幻觉一样。


ISO和ANIS SQL标准制定了四种事务隔离级别。

**READ UNCOMMITTED**
在这一隔离级别，一个事务可以读到另外一个还没有提交（commit）的事务。脏读，不可重复度，幻读都有可能发生。


**READ COMMITTED**

该级别比READ UNCOMMITTED高一级，只能读取到事务已经提交的数据，它解决了脏读的问题，但是不能解决不可重复度，幻读。它是Oracle数据库的默认隔离级别。

**REPEATABLE READ**



**SERIALIZABLE**

READ UNCOMMITTED称为浏览访问(browse access),仅仅只对事务而言的。
READ COMMITTED称为游标稳定(cursor stability)。
REPEATABLE READ是2.9999°的 隔离，没有幻读的保护。
SERIALIZABLE称为隔离，或3'。SQL和SQL 2标准的默认事务 隔离级别是SERIALIZABLE。

InnoDB存储引擎默认的支持隔离级别是REPEATABLE READ,但是与标准SQL不同 的是，InnoDB存储引擎在REPEATABLE READ事务隔离级别下，使用Next-Key Lock锁的 算法，因此避免幻读的产生。这与其他数据库系统(如Microsoft SQL Server数据库)是不 同的。所以说，InnoDB存储引擎在默认REPEATABLE READ的事务隔离级别下已经能完全保证事务的隔离性要求，即达到SQL标准的SERIALIZABLE隔离级别。

隔离级别越低，事务请求的锁越少，或者保持锁的时间就越短。这也是为什么大多数 数据库系统默认的事务隔离级别是READ COMMITTED。

# Mysql事务的实现

在Mysql中原子性、一致性、持久性通过数据库的redo和undo 来完成。隔离性用锁实现。

## 隔离性的实现




隔离性由第6章讲述的锁得以实现。
7.2.1    redo
在InnoDB存储引擎中，事务日志通过重做(redo)日志文件和InnoDB存储引擎的日志 缓冲(InnoDB Log Buffer)来实现。当开始一个事务时，会记录该事务的一个LSN  (Log
Sequence Number,日志序列号)，当事务执行时，会往InnoDB存储引擎的日志缓冲里插
入事务日志I当事务提交时，必须将InnoDB存储引擎的日志缓冲写入磁盘(默认的实现， 即innodb_flush_log_at_trx_commit= 1)。也就是在写数据前，需要先写日志。这种方式称 为预写日志方式(Write-Ahead Logging, WAL)。
InnoDB存储引擎通过预写日志的方式来保证事务的完整性。这意味着磁盘上存储的数
据页和内存缓冲池中的页是不同步的，对于内存缓冲池中页的修改，先是写入重做日志文
件，然后再写入磁盘，因此是一种异步的方式。可以通过命令SHOW ENGINE INNODB STATUS来观察当前磁盘和日志的“差距”：
create table z (a int,primary key(a))engine-innodb;

create procedure load_test (count int)
begin
declare i int unsigned default 0;
start transaction;
while i < count do
insert into z select i;
set i=i+l;
end while;
conunit;
end;
首先建立一张表z，然后建立一个往表z中导入数据的存储过程load_test0通过命令 SHOW ENGINE INNODB STATUS观察当前的重做日志情况：
mysql> show engine innodb status\G;
......
LOG

1 row in set (0.00 sec)
Log sequence number表示当前的LSN, Log flushed up to表示刷新到重做日志文件的 LSN, Last checkpoint at表示刷新到磁盘的LSN。因为当前没有任何操作，所以这三者的 值是一样的。接着开始导入10 000条记录：
mysql>call load_test(10000);
mysql> show engine innodb status\G;

这次SHOW ENGINE INNODB STATUS的结果就不同了，Log sequence number的LSN
为113047672789, Log flushed up to的LSN为113047672789, Last checkpoint at的LSN为 113047174608,可以把Log flushed up to和Last checkpoint at的差值498 181 (-486.5K)理 解为重做日志产生的增量(以字节为单位)。
虽然在上面的例子中，Log sequence number和Log flushed up to的值是相等的，但是在
实际的生产环境中，该值有可能是f同的。因为在一个事务中从日志缓冲刷新到重做日志
文件，并不只是在事务提交时发生，每秒都会有从日志缓冲刷新到重做日志文件的动作
(这部分内容我们在3.6.2小节已经讲解过了)。下面是一个生产环境下重做日志的信息：. mysql> show engine innodb status\G;

1 row in set (0.00 sec)
可以看到，在生产环境下Log sequence number%        Log flushed up to%         Last checkpoint at 三个值可能是不同的。
7.2.2   undo
重做日志记录了事务的行为，可以很好地通过其进行“重做”。但是事务有时还需要
撤销，这时就需要undo。undo与redo正好相反，对于数据库进行修改时，数据库不但会产
生redo,而且还会产生一定量的undo,即使你执行的事务或语句由于某种原因失败了，或
者如果你用一条ROLLBACK语句请求回滚，就可以利用这些undo信息将数据回滚到修改
之前的样子。与redo不同的是，redo存放在重做日志文件中，undo存放在数据库内部的一 个特殊段(segment)中，这称为undo段(undo segment), undo段位于共享表空间内。可

以通过pyjnnodb_pagejnfo.py工具，来査看当前共享表空间中undo的数量：
froot^xen-server -]# python py_innodb_page_info.py /usr/local/mysql/data/ibdatal Total number of page: 46208:
Insert Buffer Free List: 13093
Insert Buffer Bitmap: 3
System Page: 5
Transaction system Page: 1
Freshly Allocated Page: 4579
undo Log Page: 2222
File Segment inode: 6
B-tree Node: 26296

扩展描述页：2
可以看到，当前的共享表空间ibdata 1内有2222个undo页。
我们通常对于undo有这样的误解：undo用于将数据库物理地恢复到执行语句或事务之
前样子——但事实并非如此。数据库只是逻辑地恢复到原来的样子，所有修改都被逻辑地
取消，但是数据结构本身在回滚之后可能大不相同，因为在多用户并发系统中，可能会有
数十、数百甚至数千个并发事务。数据库的主要任务就是协调对于数据记录的并发访问。
如一个事务在修改当前一个页中某几条记录，但同时还有别的事务在对同一个页中另几条
记录进行修改。因此，不能将个页回滚到事务开始的样子，因为这样会影响其他事务正 在进行的工作。
例如：我们的事务执行了一个INSERT  10万条记录的SQL语句，这条语句可能会导致
分配一个新的段，即表空间会增大。如果我们执行ROLLBACK时，会将插入的事务进行
回滚，但是表空间的大小并不会因此而收缩。因此，当InnoDB存储引擎回滚时，它实际上
做的是与先前相反的工作。对于每个INSERT, InnoDB存储引擎会完成一个DELETE；对
于每个DELETE,  InnoDB存储引擎会执行一个INSERT；对于每个UPDATE,  InnoDB存储 引擎则会执行一个相反的UPDATE,将修改前的行放回去。
Oracle和Microsoft SQL Server数据库都有内部的数据字典来观察当前undo的信息*
InnoDB存储引擎在这方面做得还是不够的，所以DBA只能通过原理和经验来进行判断。 我写过一个补丁（patch）来扩展SHOW ENGINE INNODB STATUS命令的显示结果，可 以用来査看当前内存缓冲池中undo页的数量，如下代码所示。

可以看到，当前内存缓冲中有1个undo页。接着我们开启一个事务，执行插入10万条 记录的操作，需要注意的是，这并不进行提交操作：
mysql> create table t like order_line;
Query OK, 0 rows affected (0.23 sec)
mysql> insert into t select *  from order一line limit 100000;
Query OK, 100000 rows affected (45.01 sec)
Records: 100000  Duplicates:   0  Warnings:   0
之后在另一个会话中执行命令SHOW ENGINE INNODB STATUS,可以看到之前的会 话产生的undo量：

1 row in set (12.38 sec)
可以看到，此时undo页的数量变成了129,也就是说，刚才的一个事务大致产生了129
个undo页。另外，即使对INSERT的事务进行了提交，我们在一段时间内还是可以看到内
存中有129个undo页。这是因为，对于undo页的回收是在master thread中进行的，master
thread也不是每次回收所有的undo页。关于master thread的工作原理，我们在第2.3.1小节曾 介绍过。
