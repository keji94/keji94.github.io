---
layout: post
title: Java数据结构：二叉树与二叉搜索树
date: 2019-06-01 15:01:18
categories: 
  - 数据结构
tags:
  - 数据结构
---

# Java数据结构：二叉树与二叉搜索树

上一篇介绍了树这种数据结构，并用Java代码使用链表实现了树。[](https://zhuanlan.zhihu.com/p/74141967),接下来介绍树的其中一种特例，二叉树。


在计算机科学中，二叉树（英语：Binary tree）是每个节点最多只有两个分支（即不存在分支度大于2的节点）的树结构。通常分支被称作“左子树”或“右子树”。二叉树的分支具有左右次序，不能随意颠倒。

二叉树的第 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/i.svg)层至多拥有 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/2i-1.svg)个节点；深度为 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/k.svg)的二叉树至多总共有![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/2k-1.svg)个节点（定义根节点所在深度 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/k0%3D0.svg)），而总计拥有节点数匹配的，称为“满二叉树”；深度为 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/k.svg)有![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/n.svg)个节点的二叉树，当且仅当其中的每一节点，都可以和同样深度![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/k.svg)的满二叉树，序号为1到![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/n.svg)的节点一对一对应时，称为完全二叉树。对任何一棵非空的二叉树![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/t.svg)，如果其叶片（终端节点）数为 ![title](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/n0.svg)，分支度为2的节点数为 ![title](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/n2.svg)，则 ![title](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/n0%3Dn2.svg)。

与普通树不同，普通树的节点个数至少为1，而二叉树的节点个数可以为0；普通树节点的最大分支度没有限制，而二叉树节点的最大分支度为2；普通树的节点无左、右次序之分，而二叉树的节点有左、右次序之分。

二叉树通常作为数据结构应用，典型用法是对节点定义一个标记函数，将一些值与每个节点相关系。这样标记的二叉树就可以实现二叉搜索树和二叉堆，并应用于高效率的搜索和排序。

<!-- more -->

# 二叉树的实现

## Node类
首先，需要有一个节点对象的类。这些对象包含数据，数据代表要存储的内容（例如，在员工
数据库中的员工记录），而且还有指向节点的两个子节点的引用。
```java
@Data
public class Node<T> {

    /**
     * 角标
     */
    private Integer index;
    /**
     * 数据
     */
    private T data;
    /**
     * 左节点
     */
    private Node leftChild;
    /**
     * 右节点
     */
    private Node rightChild;

　　public void displayNode() {

  　}

    /**
     * 构造函数
     * 
     * @param index 角标
     * @param data 数据
     */
    public Node(Integer index, T data) {
        this.index = index;
        this.data = data;
        this.leftChild = null;
        this.rightChild = null;
    }
}
```

有些实现也把节点的父节点的引用包括在Node类中。这样做会使一些操作简化，但使一些别的操作复杂，所以这里不使用它。

这个类中还有一个叫displayNode()的方法，用它来显示节点数据，不过在这里没有写出它的代码。

## Tree类

还需要有一个表示树本身的类，由这个类实例化的对象含有所有的节点，这个类是Tree类。它只有一个数据字段：一个表示根的Node变量。它不需要包含其他节点的数据字段，因为其他节点都可以从根开始访问到。

Tree类有很多方法。它们用来查询、插入和删除节点；进行各种不同的遍历；显示树。下面是这个类的骨架:
```java
public class Tree<T> {

    private Node<T> root;

    public Node<T> find(int key) {
        return null;
    }

    public void insert(int id, T data) {

    }

    public Node delete(int id) {
        return null;
    }

}
```

## 遍历二叉树
作为树的一种特例，二叉树自然继承了一般树结构的前序、后序以及层次等遍历方法。这三个遍历算法的实现与普通树大同小异，这里不再赘述。

需要特别指出的是，对二叉树还可以定义一个新的遍历方法⎯⎯中序遍历（Inorder traversal）。顾名思义，在访问每个节点之前，首先遍历其左子树；待该节点被访问过后，才遍历其右子树。类似地，由中序遍历确定的节点序列，称作中序遍历序列。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/Tree_Inorder_iter.png)


## 二叉搜索树（Binary Search Tree）

二叉搜索树（英语：Binary Search Tree），也称为二叉查找树、有序二叉树（ordered binary tree）或排序二叉树（sorted binary tree），是指一棵空树或者具有下列性质的二叉树：

1. 若任意节点的左子树不空，则左子树上所有节点的值均小于它的根节点的值；
2. 若任意节点的右子树不空，则右子树上所有节点的值均大于它的根节点的值；
3. 任意节点的左、右子树也分别为二叉查找树；
4. 没有键值相等的节点。

二叉查找树相比于其他数据结构的优势在于查找、插入的时间复杂度较低。为 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/lognsvg.svg)。二叉查找树是基础性数据结构，用于构建更为抽象的数据结构，如集合、多重集、关联数组等。

二叉查找树的查找过程和次优二叉树类似，通常采取二叉链表作为二叉查找树的存储结构。中序遍历二叉查找树可得到一个关键字的有序序列，一个无序序列可以通过构造一棵二叉查找树变成一个有序序列，构造树的过程即为对无序序列进行查找的过程。

每次插入的新的结点都是二叉查找树上新的叶子结点，在进行插入操作时，不必移动其它结点，只需改动某个结点的指针，由空变为非空即可。搜索、插入、删除的复杂度等于树高，期望 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/lognsvg.svg)，最坏 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/on.svg)（数列有序，树退化成线性表）。


虽然二叉查找树的最坏效率是 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/on.svg)，但它支持动态查询，且有很多改进版的二叉查找树可以使树高为 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/lognsvg.svg)，从而将最坏效率降至 ![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/lognsvg.svg)，如AVL树、红黑树等。

### 在二叉搜索树插入节点的算法

向一个二叉搜索树b中插入一个节点s的算法，过程为：

1. 若b是空树，则将s所指节点作为根节点插入，否则：
2. 若s->data等于b的根节点的数据域之值，则返回，否则：
3. 若s->data小于b的根节点的数据域之值，则把s所指节点插入到左子树中，否则：
4. 把s所指节点插入到右子树中。（新插入节点总是叶子节点）

```java
public class Tree<T> {

    private Node<T> root;

    public Node<T> find(int key) {
        return null;
    }

    public void insert(int id, T data) {
        Node<T> newNode = new Node<>();
        newNode.setIndex(id);
        newNode.setData(data);
        if (null == root) {
            root = newNode;
        }else {
            //从根节点开始查找
            Node<T> current = root;
            //声明父节点的引用
            Node<T> parent;
            while (true) {
                //父节点的引用指向当前节点
                parent = current;
                //如果角标小于当前节点,插入到左节点
                if (id < current.getIndex()) {
                    current = current.getLeftChild();
                    //节点为空才进行赋值，否则继续查找
                    if (null == current) {
                        parent.setLeftChild(newNode);
                        return;
                    }
                }else {
                    //否则插入到右节点
                    current = current.getRightChild();
                    if (null == current) {
                        parent.setRightChild(newNode);
                        return;
                    }
                }
            }

        }
    }

    public Node delete(int id) {
        return null;
    }
}
```

### 二叉搜索树的查找算法

在二叉搜索树b中查找x的过程为：

1. 若b是空树，则搜索失败，否则：
2. 若x等于b的根节点的数据域之值，则查找成功；否则：
3. 若x小于b的根节点的数据域之值，则搜索左子树；否则：
4. 查找右子树。

```java
public Node<T> find(int key) {
　　if (null == root) {
　　　　return null;
　　}
　　Node<T> current = root;

　　//如果不是当前节点
　　while (current.getIndex() != key) {
　　　　if (key < current.getIndex()) {
　　　　　　current = current.getLeftChild();
　　　　}else {
　　　　　　current = current.getRightChild();
　　　　}
　　　　
　　　　//如果左右节点均为null，查找失败
　　　　if (null == current) {
　　　　　　return null;
　　　　}
　　}

　　return current;
}
```


### 在二叉查找树删除结点的算法

删除节点是二叉搜索树常用的一般操作中最复杂的。但是，删除节点在很多树的应用中又非常重要，所以要详细研究并总结特点。

删除节点要从查找要删的节点开始入手，方法与前面介绍的find()和insert()相同。找到节点后,这个要删除的节点要分三种情况讨论：

1. 该节点是叶节点(没有子节点)。
2. 该节点有一个子节点。
3. 该节点有两个子节点。

#### 情况一：删除没有子节点的节点
要删除叶节点，只需要改变该节点的父节点的对应子字段的值，由指向该节点、改为null就可以了。要删除的节点仍然存在，但它已经不是树的一部分了。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/tree_del.png)

因为Java语言有垃圾自动收集的机制，所以不需要非得把节点本身给删掉。


####  情况二 删除只有一个子节点的节点

第二种情况也不是很难。这个节点只有两个连接：连向父节点的和连向它惟一的子节点的。

需要从这个序列中“剪断”这个节点，把它的子节点直接连到它的父节点上。这个过程要求改变父节点适当的引用(左子节点还是右子节点)，指向要删除节点的子节点。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/tree_del_one_child.png)

#### 情况三 删除有两个子节点的节点

下面有趣的情况出现了。如果要删除的节点有两个子节点，就不能只是用它的一个子节点代替它。为什么不能这样呢？看图：

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/tree_del_two_child.png)

假设要删除节点25,并且用它的根是35的右子树取代它。那么35的左子节点应该是谁呢？是要删除节点25的左子节点15,还是35原来的左子节点30？然而在这两种情况中30都会被放得不对，但又不能删掉它。

对每一个节点来说，比该节点的关键字值次高的节点是它的中序后继，可以简称为该节点的后继。在上图中，节点30就是节点25的后继。

这里有一个窍门：删除有两个子节点的节点，用它的中序后继来代替该节点。如下图：
![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/tree_del_replace.png)

这里还有更麻烦的情况是它的后继自己也有子节点，后面会讨论这种可能性。

**找后继节点**

怎么找节点的后继呢？算法如下:

首先，找到初始节点的右子节点A，它的关键字值一定比初始节点大。然后转到A的左子节点那里（如果有的话），然后到这个左子节点的左子节点，以此类推，顺着左子节点的路径一直向下找。这个路径上的最后一个左子节点就是初始节点的后继。

如果初始节点的右子节点没有左子节点，那么这个右子节点本身就是后继。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/findSuccessor.png)

以下是找后继节点的代码:
```java
private Node<T> getSuccessor(Node<T> delNode) {
　　Node<T> successorParent = delNode;
　　Node<T> successor = delNode;

　　//go to rightChild
　　Node<T> current = delNode.getRightChild();

　　while (current != null) {
　　　　//一直往下找左节点
　　　　successorParent = successor;
　　　　successor = current;
　　　　current = current.getLeftChild();
　　}

　　//跳出循环，此时successor为最后的一个左节点，也就是被删除节点的后继节点
　　
　　//这里的判断先忽视，在后面会讲
　　if (successor != delNode.getRightChild()) {
　　　　successorParent.setLeftChild(successor.getRightChild());
　　　　successor.setRightChild(delNode.getRightChild());
　　}

　　return successor;
}
```

这个方法首先找到delNode的右子节点，然后，在while循环中，顺着这个右子节点所有左子节点的路径向下查找。当while循环中止时，successor就存有delNode的后继。

找到后继后，还需要访问它的父节点，所以在while循环中还需要保留当前节点的父节点。

正如看到的那样，后继节点可能与current有两种位置关系，current就是要删除的节点。后继可能是current的右子节点，或者也可能是current右子节点的左子孙节点。下面来依次看看这两种情况。

**后继节点是delNode的右子节点**

如果后继是cunent的右子节点，情况就简单了一点，因为只需要把后继为根的子树移到删除的节点的位置。这个操作只需要两个步骤：

1. 把current从它父节点的rightChild字段删掉(当然也可能是leftChild字段)，把这个字段指向后继。
2. 把current的左子节点移出来，把它插到后继的leftChild字段。

下图演示了这种情况，要删除节点75，后继节点是其右节点

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/del_accessor_right.png)

接上之前的代码
```java
public Node<T> delete(int key) {
　　//...接前面的else if
　　else {
　　　　//查找后继节点
　　　　Node<T> successor = getSuccessor(current);

　　　　//情况3.1 如果如果删除节点有两个子节点且后继节点是删除节点的右子节点
　　　　if (current == root) {
　　　　　　root = successor;
　　　　} else if (isLeftChild) {
　　　　　　parent.setLeftChild(successor);
　　　　} else {
　　　　　　parent.setRightChild(successor);
　　　　}

　　　　successor.setLeftChild(current.getLeftChild());

　　}

　　return current;
}
```


第一步：如果要删除的节点current是根，它没有父节点，所以就只需要把根置为后继。
否则，要删除的节点或者是左子节点或者是右子节点了(图8.19中它是右子节点)，因此
需要把它父节点的对应的字段指向successor。当delete()方法返回，current失去了作用范
围后，就没有引用指向current保存的节点，它就会被Java的垃圾收集机制销毁。

第二步：把successor的左子节点指向的位置设为current的左子节点。


如果后继有子节点怎么办呢？首先，后继节点是肯定不会有左子节点的。无论后继是要删除节
点的右子节点还是这个右子节点的左子节点之一，这条在查找后继节点的算法中可以验证。

另一方面，后继很有可能有右子节点。当后继是被删除节点的右子节点时，这种情况不会带来
多大问题。移动后继的时候，它的右子树只要跟着移动就可以了。这和要删除节点的右子节点没有
冲突，因为后继就是右子节点。

下面这种情况就需要很小心了。

**后继节点是delNode右子节点的左后代**

如果successor是要删除节点右子节点的左后代，执行删除操作需要以下四个步骤:
1. 把后继父节点的leftChild字段置为successor的右子节点。
2. 把successor的rightChild字段置为要删除节点的右子节点。
3. 把current从它父节点的rightChild字段移除，把这个字段置为successor
4. 把current的左子节点从current移除，successor的leftChild字段置为current的左子节点。

![](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/tree_del_successor_isLeft.png)

第1步和第2步由getSuccessor()方法完成(已经在前面写上了)，第3步和第4步由delete()方法完成。

## 通过标记删除

看到这里，删除操作已经全部完成了，真的是相当棘手的操作，难就难在节点的改变上。那么我们可不可以不改变节点，达到删除的目的？。

答案是可以的，在node类中加了一个Boolean的字段，名称如deleted。要删除一个节点时，就把此节点的这个字段置为true。其他操作，像find(),在查找之前先判断这个节点是不是标志为已删除了。

这样，删除的节点不会改变树的结构。当然，这样做存储中还保留着这种“己经删除”的节点。

如果树中没有那么多删除操作时，这也不失为一个好方法。（例如，已经离职的员工的档案要永久保存在员工记录中。）

下面是删除操作的完整代码:
```java
public Node<T> delete(int key) {

　　if (null == root) {
　　　　return null;
　　}

　　Node<T> current = root;
　　Node<T> parent = root;
　　boolean isLeftChild = true;

　　//删除操作第一步，查找要删除的节点
　　while (current.getIndex() != key) {
　　　　parent = current;
　　　　if (key < current.getIndex()) {
　　　　　　isLeftChild = true;
　　　　　　current = current.getLeftChild();
　　　　} else {
　　　　　　isLeftChild = false;
　　　　　　current = current.getRightChild();
　　　　}

　　　　//如果左右节点均为null，没有找到要删除的元素
　　　　if (null == current) {
　　　　　　return null;
　　　　}

　　}

　　//跳出循环，找到要删除的元素:current

　　if (null == current.getLeftChild() && null == current.getRightChild()) {
　　　　//情况1：如果当前节点没有子节点
　　　　if (current == root) {
　　　　　　//如果当前节点是根节点,将树清空
　　　　　　root = null;
　　　　　　return current;
　　　　} else if (isLeftChild) {
　　　　　　//如果当前节点是其父节点的做节点，将父节点的左节点清空
　　　　　　parent.setLeftChild(null);
　　　　} else {
　　　　　　parent.setRightChild(null);
　　　　}
　　} else if (null == current.getRightChild()) {
　　　　//情况2.1：如果删除节点只有一个子节点且没有右节点
　　　　if (current == root) {
　　　　　　root = current.getLeftChild();
　　　　} else if (isLeftChild) {
　　　　　　parent.setLeftChild(current.getLeftChild());
　　　　} else {
　　　　　　parent.setRightChild(current.getLeftChild());
　　　　}

　　} else if (null == current.getLeftChild()) {
　　　　//情况2.2 如果删除节点只有一个子节点且没有左节点
　　　　if (current == root) {
　　　　　　root = current.getRightChild();
　　　　} else if (isLeftChild) {
　　　　　　parent.setLeftChild(current.getRightChild());
　　　　} else {
　　　　　　parent.setRightChild(current.getRightChild());
　　　　}

　　} else {
　　　　//查找后继节点
　　　　Node<T> successor = getSuccessor(current);

　　　　//情况3.1 如果如果删除节点有两个子节点且后继节点是删除节点的右子节点
　　　　if (current == root) {
　　　　　　root = successor;
　　　　} else if (isLeftChild) {
　　　　　　parent.setLeftChild(successor);
　　　　} else {
　　　　　　parent.setRightChild(successor);
　　　　}

　　　　successor.setLeftChild(current.getLeftChild());

　　}

　　return current;
}

private Node<T> getSuccessor(Node<T> delNode) {
　　Node<T> successorParent = delNode;
　　Node<T> successor = delNode;

　　//go to rightChild
　　Node<T> current = delNode.getRightChild();

　　while (current != null) {
　　　　//一直往下找左节点
　　　　successorParent = successor;
　　　　successor = current;
　　　　current = current.getLeftChild();
　　}

　　//跳出循环，此时successor为最后的一个左节点，也就是被删除节点的后继节点

　　//如果successor是要删除节点右子节点的左后代
　　if (successor != delNode.getRightChild()) {
　　　　//把后继节点的父节点的leftChild字段置为successor的右子节点
　　　　successorParent.setLeftChild(successor.getRightChild());
　　　　//把successor的rightChild字段置为要删除节点的右子节点。
　　　　successor.setRightChild(delNode.getRightChild());
　　}

　　return successor;
}
```

### 二叉查找树的遍历

前面说过二叉树的遍历主要有四种：前序遍历、后序遍历、层次遍历以及中序遍历。二叉搜索树最常用的遍历方法是中序遍历。

#### 中序遍历

中序遍历二叉搜索树会使所有的节点按关键字值升序被访问到。如果希望在二叉树中创建有序
的数据序列，这是一种方法。
```java
private void inOrder(Node<T> localRoot) {
　　if (null != localRoot) {
　　　　inOrder(localRoot.getLeftChild());
　　　　System.out.println(localRoot.getIndex());
　　　　inOrder(localRoot.getRightChild());
　　}
}
```

