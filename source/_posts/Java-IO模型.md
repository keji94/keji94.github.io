title: Java IO模型
author: 克己
tags: []
categories: []
date: 2019-03-20 20:46:00
---
# Linux系统的五种IO模式

Java 的 IO 模型本质上还是利用操作系统提供的接口来实现,所以最好先了解Linux底层模型。推荐阅读[Linux IO模式及 select、poll、epoll详解](https://segmentfault.com/a/1190000003063859?utm_source=Weibo&utm_medium=shareLink&utm_campaign=socialShare&from=timeline&isappinstalled=0)

# Java IO模型的演变

## BIO

在JDK1.4之前，基于Java的所有Socket通信都采用同步阻塞模式(BIO)，这种一请求一应答的通信模型简化了上层的应用开发，但是在性能和可靠性方面却存在着巨大的瓶颈。当并发量增大，响应时间延迟增大之后，采用Java BIO开发的服务端只有通过硬件的不断扩容来满足高并发和低延迟，它极大的增加了企业的成本，随着集群规模的不断膨胀，系统的可维护性也面临巨大的挑战。

<!-- more -->

代码类似这样:

```java
public class BlokingIoServer implements Runnable{

    @Override
    public void run() {
        try {
            //将服务绑定到指定端口
            ServerSocket ss = new ServerSocket(8888);
            while (!Thread.interrupted()){
                //对 accept()方法的调 用将被阻塞，直到一个连接建立
                final Socket clientSocket = ss.accept();

                //为每个请求创建一个线程来处理
                new Thread(new Handler(clientSocket)).start();
            }
            // or, single-threaded, or a thread pool
        } catch (IOException ex) { /* ... */ }
    }
    static class Handler implements Runnable {
        final Socket socket;
        Handler(Socket s){
            socket = s;
        }
        @Override
        public void run() {
            try {
                byte[] input = new byte[1024];
                socket.getInputStream().read(input);
                byte[] output = process(input);
                socket.getOutputStream().write(output);
            } catch (IOException ex) { /* ... */ }
        }
        private byte[] process(byte[] cmd){
            //do something
            return null;
        }
    }
}

```


Web服务，大多数有着类似的流程:
Read request (从底层IO读取网络字节请求)
Decode request (把读取的网络字节请求进行解码,封装成为业务请求对象)
Process service (对解码封装后的业务请求对象进行业务处理)
Encode reply (将业务逻辑处理完后的响应进行编码为底层IO可传输的字节响应)
Send reply (利用底层IO发送已编码的字节响应)

不同之处在于，每一个步骤底层使用的技术和手段不同，比如:
XML解析,文件传输,Web页面生成,计算服务.....

![classic_service_design](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/classic_service_design.png)

经典(传统)的网络服务设计如上图所示，对每个请求都会产生一个新的线程来进行处理，这种设计的缺点是，线程的创建本身是系统资源的一个开销，如果并发请求达到一定数量，响应将会变慢，甚至有可能因为系统资源不足而造成系统崩溃。

### 伪异步I/O编程

为了解决同步阻塞I/O面临的一个链路需要一个线程处理的问题，后来有人对它的线程模型进行了优化，后端通过一个线程池来处理多个客户端的请求接入，形成客户端个数M:线程池最大线程数N的比例关系，其中M可以远远大于N,通过线程池可以灵活的调配线程资源， 设置线程的最大值， 防止由于海量并发接入导致线程耗尽。

![746143-20171024093026988-682603426](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/746143-20171024093026988-682603426.png)

当有新的客户端接入的吋候，将客户端的Socket封装成一个Task （该任务实现java.lang.Runnable接口）投递到后端的线程池中进行处理，JDK的线程池维护一个消息队列和N个活跃线程对消息队列中的任务进行处理。由于线程池可以设置消息队列的大小和最大线程数，因此，它的资源占用是可控的，无论多少个客户端并发访问，都不会导致资源的耗尽和宕机。


```java
public class TimeServer {

    public static void main(String[] args) throws IOException {
        int port = 8080;
        if (args != null && args.length > 0) {
            try {
                port = Integer.valueOf(args[0]);
            } catch (NumberFormatException e) {
                //采用默汄值
            }
        }
        ServerSocket server = null;
        try {
            server = new ServerSocket(port);
            System.out.println("The time server is start in port :" + port);
            Socket socket = null;

            TimeServerHandlerExecutePool singleExecutor = new TimeServerHandlerExecutePool(50, 10000);
            while (true) {
                socket = server.accept();
                singleExecutor.execute(new TimeServerHandler(socket));
            }
        } finally {
            if (server != null) {
                System.out.println("The time server close11");
                server.close();
                server = null;
            }

        }
    }
}


public class TimeServerHandlerExecutePool {
    private ExecutorService executor;

    public TimeServerHandlerExecutePool(int maxPoolSize, int queueSize) {
        executor = new ThreadPoolExecutor(Runtime.getRuntime().availableProcessors(), maxPoolSize, 120L,
                TimeUnit.SECONDS, new ArrayBlockingQueue<Runnable>(queueSize));
    }

    public void execute(java.lang.Runnable task) {
        executor.execute(task);
    }
}


public class TimeServerHandler implements Runnable {
    private Socket socket;

    public TimeServerHandler(Socket socket) {
        this.socket = socket;
    }

    @Override
    public void run() {
        BufferedReader in = null;
        PrintWriter out = null;
        try {
            in = new BufferedReader(new InputStreamReader(this.socket.getInputStream()));
            out = new PrintWriter(this.socket.getOutputStream(), true);
            String currentTime = null;
            String body = null;
            while (true) {
                body = in.readLine();
                if (body == null) {
                    break;
                }

                System.out.println("The time server receive order : " + body);
                currentTime = "QUERY TIME ORDER".equalsIgnoreCase(body) ? new Date(System.currentTimeMillis())
                        .toString() : "BAD ORDER";
                System.out.println(currentTime);
            }
        } catch (Exception e) {
            if (in != null) {
                try {
                    in.close();
                } catch (IOException el) {
                    el.printStackTrace();
                }
                if (out != null) {
                    out.close();
                    out = null;
                }
                if (this.socket != null) {
                    try {
                        this.socket.close();
                    } catch (IOException el) {
                        el.printStackTrace();
                    }
                    this.socket = null;
                }

            }
        }
    }
}

```

伪异步IO解决了线程的频繁创建销毁问题，但是如果通信对方返回应答时间过长，会引起级联故障，比如下面的场景:
1. 服务端处理缓慢，返回应答消息耗费60s，平时只需要10ms。
2. 采用伪异步IO的线程正在读取故障服务节点的响应，由于读取输入流是阻塞的，因此，它将会被同步阻塞60s。
3. 假如所有的可用线程都被故障服务器阻塞，那后续所有的IO消息都将在队列中排队。
4. 由于线程池采用阻塞队列实现，将队列积满之后，后续入队列的操作将被阻塞。
5. 由于前段只有一个Accptor线程接口客户端接入，它被阻塞在线程池的同步阻塞队列之后，新的客户端请求消息将被拒绝，客户端会发生大量的连接超时。
6. 由于几乎所有的连接都超时，调用者会认为系统崩溃，无法接受新的请求消息。



## NIO

NIO，有人解释为new I/O,有人解释为Non-block I/O(我更倾向后者)。

正是由于Java传统BIO的拙劣表现，才使得Java支持非阻塞I/O的呼声日渐高涨，最终，JDK1.4版本提供了新的NIO类库，Java终于也可以支持非阻塞I/O 了。NIO主要的类和接口如下:

* 进行异步I/O操作的缓冲区ByteBuffer等;
* 进行异步I/O操作的管道Pipe；
* 进行各种I/O操作（异步或者同步）的Channel,包括ServerSocketChannel和
* SocketChannel：
* 多种字符集的编码能力和解码能力；
* 实现非阻塞I/O操作的多路复用器selector：
* 基千流行的Perl实现的正则表达式类库；
* 文件通道FileChannelo。

新的NIO类库的提供，极大地促进了基于Java的异步非阻塞编程的发展和应用，但是，它依然有不完善的地方，特别是对文件系统的处理能力仍显不足，主要问题如下。

* 没有统一的文件属性（例如读写权限）；
* API能力比较弱，例如目录的级联创建和递归遍历，往往需要自己实现：
* 底层存储系统的一些高级API无法使用：
* 所有的文件操作都是同步阻塞调用，不支持异步文件读写操作。

2011年7月28日，JDKI.7正式发布。她将原来的NIO类库进行了升级，被称为NIO2.0。它主要提供了如下三个方
面的改进。

* 能够提供能够批量获取文件属性的API，这些API具有平台无关性，不与特定的文件系统相耦合，另外它还提供了标准文件系统的SPI,供各个服务提供商扩展实现；
* 提供AIO功能，支持基于文件的异步I/O操作和针对网络套接字的异步操作；
* 完成JSR-5I定义的通道功能，包括对配置和多播数据报的支持等；

### NIO类库概念和功能介绍

#### 缓冲区Buffer

Buffer是一个对象，它包含一些要写入或者要读出的数据。在NIO库中，所有数据都是用缓冲区处理的。在读取数据时，它是直接读到缓冲区中的；在写入数据时，写入到缓冲区中。任何吋候访问NIO中的数据，都是通过缓冲区进行操作。

缓冲区实质上是一个数组。通常它是一个字节数组(ByteBuffer),也可以使用其他种类的数组。但是一个缓冲区**不仅仅**是一个数组，缓冲区提供了对数据的结构化访问以及维护读写位置(limit)等信息。

最常用的缓冲区是ByteBuffer, 一个ByteBuffer提供了一组功能用于操作byte数组。除了 ByteBuffer,还有其他的一些缓冲区，事实上，每一种Java基本类型(除了 Boolean类型)都对应有一种缓冲区，具体如下。

* ByteBuffer：字节缓冲区
* CharBuffer：字符缓冲区
* ShortBuffer：短整型缓冲K
* IntBuffer：整形缓冲区
* LongBuffer：长整形缓冲区
* FloatBuffer：浮点型缓冲区
* DoubleBuffer： 双精度浮点型缓冲区

![BufferUml](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/BufferUml.png)

每—个Buffer类都是Buffer接口的一个T实例。除了 ByteBuffer,每一个Buffe类都有完全一样的操作，只是它们所处理的数据类型不一样。因为大多数标准I/O操作都使用ByteBuffer,所以它除了具有一般缓冲区的操作之外还提供一些特有的操作，方便网络读写。

#### 管道channel

Channel是一个通道，可以通过它读取和写入数据，它就像自来水管一样，网络数据通过Channel读取和写入。通道与流的不同之处在于通道是双向的，流只是在一个方向上移动（一个流必须是InputStream或者OutputStream的子类），而且通道可以用于读、写或者同时用于读写。

Channel的类继承图如下。
![ChannelUml](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/ChannelUml.png)


因为Channel是全双工的，所以它可以比流更好地映射底层操作系统的API。特别是在UNIX网络编程模型中，底层操作系统的通道都是全双工的，同时支持读写操作。

#### 多路复用器Selector

多路复用器提供选择已经就绪的任务的能力。 简单来讲， Selector会不断地轮询注册在其上的Channel,如果某个Channel上面有新的TCP 连接接入、 读和写事件， 这个Channel就处于就绪状态， 会被Selector轮询出来， 然后通过SelectionKey可以获取就绪Channel的集合， 进行后续的I/O操作。

#### 使用NIO实现服务端
![nioserver](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/nioserver.png)

```java
public class TimeServerNio {

    public static void main(String[] args) {
        //设置监听端口
        int port = 8080;
        if (args != null && args.length > 0) {
            try {
                port = Integer.valueOf(args[0]);
            } catch (NumberFormatException e) {
                //采用默认值
            }
        }
        
        //创建了一个被称为MultiplexerTimeServer的多路复用类， 它是个一个独立
        //的线程， 负责轮洵多路复用器Selctor,可以处理多个客户端的并发接入
        MultiplexerTimeServer timeServer = new MultiplexerTimeServer(port);

        new Thread(timeServer, "NIO-MultiplexerTirneServer-001H").start();
    }

}

```

```java
public class MultiplexerTimeServer implements Runnable {

    private Selector selector;

    private ServerSocketChannel servChannel;

    private volatile boolean stop;

    /**
     * 在构造方法中进行资源初始化， 创建多路复用器Selector、
     * ServerSocketChannel,对 Channel 和 TCP 参数进行配置
     *
     * @param port
     */
    public MultiplexerTimeServer(int port) {
        try {
            selector = Selector.open();
            servChannel = ServerSocketChannel.open();
            //设置为异步非阻塞模式
            servChannel.configureBlocking(false);
            servChannel.socket().bind(new InetSocketAddress(port), 1024);
            //注册selector
            servChannel.register(selector, SelectionKey.OP_ACCEPT);
            System.out.println("The time server is start in port : " + port);
        } catch (IOException e) {
            //资源初始化失败，退出系统
            e.printStackTrace();
            System.exit(1);
        }
    }

    public void stop() {
        this.stop = true;
    }


    @Override
    public void run() {
        while (!stop) {
            try {
                //循环遍历selector,它的休眠时间为1s
                selector.select(1000);
                //返回就绪状态的Channel的SelectionKey集合
                Set<SelectionKey> selectedKeys = selector.selectedKeys();
                Iterator<SelectionKey> it = selectedKeys.iterator();
                SelectionKey key = null;

                //通过对就绪状态的Channel集合进行迭代， 可以进行网络的异步读写操作
                while (it.hasNext()) {
                    key = it.next();
                    it.remove();
                    try {
                        handleInput(key);
                    } catch (Exception e) {
                        if (key != null) {
                            key.cancel();
                            if (key.channel() != null) {
                                key.channel().close();
                            }
                        }
                    }
                }
            } catch (Throwable t) {
                t.printStackTrace();
            }
        }

        // 多路复用器关闭后，所有注册在上面的Channel和Pipe等资源都会被自动去注册并关闭，所以不需要重复释放资源
        if (selector != null) {
            try {
                selector.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private void handleInput(SelectionKey key) throws IOException {

        if (key.isValid()) {
            // 处理新接入的请求消息
            if (key.isAcceptable()) {
                // Accept the new connection
                ServerSocketChannel ssc = (ServerSocketChannel) key.channel();
                SocketChannel sc = ssc.accept();
                sc.configureBlocking(false);
                // Add the new connection to the selector
                sc.register(selector, SelectionKey.OP_READ);
            }
            if (key.isReadable()) {
                // Read the data
                SocketChannel sc = (SocketChannel) key.channel();
                ByteBuffer readBuffer = ByteBuffer.allocate(1024);
                int readBytes = sc.read(readBuffer);
                if (readBytes > 0) {
                    readBuffer.flip();
                    byte[] bytes = new byte[readBuffer.remaining()];
                    readBuffer.get(bytes);
                    String body = new String(bytes, "UTF-8");
                    System.out.println("The time server receive order : "
                                       + body);
                    String currentTime = "QUERY TIME ORDER"
                                                 .equalsIgnoreCase(body) ? new java.util.Date(
                            System.currentTimeMillis()).toString()
                                                                         : "BAD ORDER";
                    doWrite(sc, currentTime);
                } else if (readBytes < 0) {
                    // 对端链路关闭
                    key.cancel();
                    sc.close();
                } else {
                    ; // 读到0字节，忽略
                }
            }
        }
    }

    /**
     * 将应答消息异步发送给客户端
     *
     * @param channel channel
     * @param response response
     * @throws IOException exception
     */
    private void doWrite(SocketChannel channel, String response)
            throws IOException {
        if (response != null && response.trim().length() > 0) {
            //将字符串编码成字节数组， 根据字节数组的容量创建ByteBuff
            byte[] bytes = response.getBytes();
            ByteBuffer writeBuffer = ByteBuffer.allocate(bytes.length);
            //将字节数据复制到缓冲区
            writeBuffer.put(bytes);
            writeBuffer.flip();
            //将缓冲区中的字节数组发送出去
            channel.write(writeBuffer);
        }
    }
}

```

#### 使用NIO实现客户端
![TimeClient](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/TimeClient.png)

```java
public class TimeClientNio {

    public static void main(String[] args) {

        int port = 8080;
        if (args != null && args.length > 0) {
            try {
                port = Integer.valueOf(args[0]);
            } catch (NumberFormatException e) {
                // 采用默认值
            }
        }
        new Thread(new TimeClientHandle("127.0.0.1", port), "TimeClient-001")
                .start();
    }
}

```

```java
public class TimeClientHandle implements Runnable{
    private String host;
    private int port;

    private Selector selector;
    private SocketChannel socketChannel;

    private volatile boolean stop;

    /**
     * implements Runnable
     *
     * @param host host
     * @param port port
     */
    public TimeClientHandle(String host, int port) {
        this.host = host == null ? "127.0.0.1" : host;
        this.port = port;
        try {
            selector = Selector.open();
            socketChannel = SocketChannel.open();
            //设置为异步非阻塞模式
            socketChannel.configureBlocking(false);
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    @Override
    public void run() {
        try {
            //发送连接请求
            doConnect();
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }
        while (!stop) {
            try {
                selector.select(1000);
                Set<SelectionKey> selectedKeys = selector.selectedKeys();
                Iterator<SelectionKey> it = selectedKeys.iterator();
                SelectionKey key = null;
                while (it.hasNext()) {
                    key = it.next();
                    it.remove();
                    try {
                        handleInput(key);
                    } catch (Exception e) {
                        if (key != null) {
                            key.cancel();
                            if (key.channel() != null)
                                key.channel().close();
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                System.exit(1);
            }
        }

        // 多路复用器关闭后，所有注册在上面的Channel和Pipe等资源都会被自动去注册并关闭，所以不需要重复释放资源
        if (selector != null){
            try {
                selector.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

    }

    private void handleInput(SelectionKey key) throws IOException {

        if (key.isValid()) {
            // 判断是否连接成功
            SocketChannel sc = (SocketChannel) key.channel();
            //如果返回值为true,说明客户端连接成功
            if (key.isConnectable()) {
                if (sc.finishConnect()) {
                    sc.register(selector, SelectionKey.OP_READ);
                    doWrite(sc);
                } else {
                    System.exit(1);// 连接失败，进程退出
                }
            }
            if (key.isReadable()) {
                //预分配1M的接收缓冲K用于读取应答消息， 调川Socketchannel的read()方法进行异步读取操作
                ByteBuffer readBuffer = ByteBuffer.allocate(1024);
                int readBytes = sc.read(readBuffer);

                if (readBytes > 0) {
                    readBuffer.flip();
                    byte[] bytes = new byte[readBuffer.remaining()];
                    readBuffer.get(bytes);
                    String body = new String(bytes, "UTF-8");
                    System.out.println("Now is : " + body);
                    this.stop = true;
                } else if (readBytes < 0) {
                    // 对端链路关闭
                    key.cancel();
                    sc.close();
                } else
                    ; // 读到0字节，忽略
            }
        }

    }

    private void doConnect() throws IOException {
        // 如果直接连接成功，则注册到多路复用器上，发送请求消息，读应答
        if (socketChannel.connect(new InetSocketAddress(host, port))) {
            socketChannel.register(selector, SelectionKey.OP_READ);
            doWrite(socketChannel);
        } else {
            //如果没有直接连接成功， 则说明服务端没有返回TCP握手应答消息， 但这并不代表连接失败， 我们需要将SocketChannel
            //注册到多路复用器Selector上， 注册SelectionKey.OP CONNECT»当服务端返回TCP
            //syn-ack消息后， Selector就能够轮询到这个SocketChannel处于连接就绪状态
            socketChannel.register(selector, SelectionKey.OP_CONNECT);
        }
    }

    private void doWrite(SocketChannel sc) throws IOException {
        byte[] req = "QUERY TIME ORDER".getBytes();
        ByteBuffer writeBuffer = ByteBuffer.allocate(req.length);
        writeBuffer.put(req);
        writeBuffer.flip();
        sc.write(writeBuffer);
        //hasRemaining()方法对发送结果进行判断， 是否全部发送完成
        if (!writeBuffer.hasRemaining()) {
            System.out.println("Send order 2 server succeed.");
        }
    }
}

```

NIO编程难度确实比同步阻塞BIO大很多， 上面的NIO 例子**并没有考虑“ 半包读” 和“ 半包写” **， 如果加上这些， 代码将会更加复杂。

### NIO优点总结
1. 客户端发起的连接操作是异步的， 可以通过在多路复用器注册OP_CONNECT等待后续结果， 不需要像之前的客户端那样被同步阻塞。
2. Socketchannel的读写操作都是异步的， 如果没有可读写的数据它不会同步等待，直接返回， 这样I/O通信线程就可以处理其他的链路， 不需要同步等待这个链路可用。 
3. 线程模型的优化： 由于JDK的Selector在Linux等主流操作系统上通过epoll实现， 它没有连接句柄数的限制(只受限于操作系统的最大句柄数或者对单个进程的句柄限制)， 这意味着一个Selector线程可以同时处理成千上万个客户端连接， 而且性能不会随着客户端的增加而线性下降， 因此， 它非常适合做高性能、 高负载的网络服务器。

## AIO
NIO2.0引入了新的异步通道概念，并提供了异步文件通道和异步套接字通道的实现。异步通道提供两种方式获取操作结果.
* 通过java.util.concurrent.Future类來表示异步操作的结果；
* 在执行异步操作的时候传入一个java.nio.channels。

CompletionHandler接口的实现类作为操作完成的回调。

NIO2.0的异步套接字通道是真正的异步非阻塞I/O,它对应UNIX网络编程中的事件驱动I/O (AIO),它不需要通过多路复用器(Selector)对注册的通道进行轮询操作即可实现异步读写， 从而简化了 NIO的编程模型。

### aio服务端代码
```java
public class TimeServerAio {

    public static void main(String[] args) throws IOException {
        int port = 8080;
        if (args != null && args.length > 0) {
            try {
                port = Integer.valueOf(args[0]);
            } catch (NumberFormatException e) {
                // 采用默认值
            }
        }
        //创建异步的时间服务器处理类
        AsyncTimeServerHandler timeServer = new AsyncTimeServerHandler(port);
        new Thread(timeServer, "AIO-AsyncTimeServerHandler-001").start();
    }
}

public class AsyncTimeServerHandler implements Runnable{
    private int port;

    CountDownLatch latch;
    AsynchronousServerSocketChannel asynchronousServerSocketChannel;

    /**
     * 创建一个异步的服务端通道AsynchronousServerSocketChannel， 然后调H］它的
     * bind h'法绑定监听端口， 如果端口合法且没被占用， 绑定成功， 打印启动成功提示到控
     * 制台
     *
     * @param port port
     */
    public AsyncTimeServerHandler(int port) {
        this.port = port;
        try {
            asynchronousServerSocketChannel = AsynchronousServerSocketChannel
                    .open();
            asynchronousServerSocketChannel.bind(new InetSocketAddress(port));
            System.out.println("The time server is start in port : " + port);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void run() {

        //初始化CountDownLatch对象， 它的作用是在完成一组正在执行的操作之前， 允许当前的线程一直阻塞.在本例程中， 我们让线程在此阻塞,
        //防止服务端执行完成退出。 在实际项目应用中， 不需要启动独立的线程來处理
        //AsynchronousServerSocketChannel
        latch = new CountDownLatch(1);
        doAccept();
        try {
            latch.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public void doAccept() {
        //接收客户端的选接
        asynchronousServerSocketChannel.accept(this,
                new AcceptCompletionHandler());
    }
}

public class AcceptCompletionHandler implements CompletionHandler<AsynchronousSocketChannel, AsyncTimeServerHandler> {
    @Override
    public void completed(AsynchronousSocketChannel result, AsyncTimeServerHandler attachment) {
        attachment.asynchronousServerSocketChannel.accept(attachment, this);
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        result.read(buffer, buffer, new ReadCompletionHandler(result));
    }

    @Override
    public void failed(Throwable exc, AsyncTimeServerHandler attachment) {
        exc.printStackTrace();
        attachment.latch.countDown();
    }
}

public class ReadCompletionHandler implements CompletionHandler<Integer, ByteBuffer> {
    private AsynchronousSocketChannel channel;

    public ReadCompletionHandler(AsynchronousSocketChannel channel) {
        if (this.channel == null) {
            this.channel = channel;
        }
    }

    @Override
    public void completed(Integer result, ByteBuffer attachment) {
        attachment.flip();
        byte[] body = new byte[attachment.remaining()];
        attachment.get(body);
        try {
            String req = new String(body, "UTF-8");
            System.out.println("The time server receive order : " + req);
            String currentTime = "QUERY TIME ORDER".equalsIgnoreCase(req) ? new java.util.Date(
                    System.currentTimeMillis()).toString() : "BAD ORDER";
            doWrite(currentTime);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }

    private void doWrite(String currentTime) {
        if (currentTime != null && currentTime.trim().length() > 0) {
            byte[] bytes = (currentTime).getBytes();
            ByteBuffer writeBuffer = ByteBuffer.allocate(bytes.length);
            writeBuffer.put(bytes);
            writeBuffer.flip();
            channel.write(writeBuffer, writeBuffer, new CompletionHandler<Integer, ByteBuffer>() {
                @Override
                public void completed(Integer result, ByteBuffer buffer) {
                    // 如果没有发送完成，继续发送
                    if (buffer.hasRemaining()) {
                        channel.write(buffer, buffer, this);
                    }
                }

                @Override
                public void failed(Throwable exc, ByteBuffer attachment) {
                    try {
                        channel.close();
                    } catch (IOException e) {
                        // ingnore on close
                    }
                }
            });
        }
    }

    @Override
    public void failed(Throwable exc, ByteBuffer attachment) {
        try {
            this.channel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

```

### aio客户端代码

```java
public class TimeClientAio {

    public static void main(String[] args) {
        int port = 8080;
        if (args != null && args.length > 0) {
            try {
                port = Integer.valueOf(args[0]);
            } catch (NumberFormatException e) {
                // 采用默认值
            }

        }
        new Thread(new AsyncTimeClientHandler("127.0.0.1", port),
                "AIO-AsyncTimeClientHandler-001").start();

    }

}


public class AsyncTimeClientHandler implements CompletionHandler<Void, AsyncTimeClientHandler>, Runnable{

    private AsynchronousSocketChannel client;
    private String host;
    private int port;
    private CountDownLatch latch;

    public AsyncTimeClientHandler(String host, int port) {
        this.host = host;
        this.port = port;
        try {
            client = AsynchronousSocketChannel.open();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void run() {

        latch = new CountDownLatch(1);
        client.connect(new InetSocketAddress(host, port), this, this);
        try {
            latch.await();
        } catch (InterruptedException e1) {
            e1.printStackTrace();
        }
        try {
            client.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void completed(Void result, AsyncTimeClientHandler attachment) {
        byte[] req = "QUERY TIME ORDER".getBytes();
        ByteBuffer writeBuffer = ByteBuffer.allocate(req.length);
        writeBuffer.put(req);
        writeBuffer.flip();
        client.write(writeBuffer, writeBuffer,
                new CompletionHandler<Integer, ByteBuffer>() {
                    @Override
                    public void completed(Integer result, ByteBuffer buffer) {
                        if (buffer.hasRemaining()) {
                            client.write(buffer, buffer, this);
                        } else {
                            ByteBuffer readBuffer = ByteBuffer.allocate(1024);
                            client.read(
                                    readBuffer,
                                    readBuffer,
                                    new CompletionHandler<Integer, ByteBuffer>() {
                                        @Override
                                        public void completed(Integer result,
                                                              ByteBuffer buffer) {
                                            buffer.flip();
                                            byte[] bytes = new byte[buffer
                                                    .remaining()];
                                            buffer.get(bytes);
                                            String body;
                                            try {
                                                body = new String(bytes,
                                                        "UTF-8");
                                                System.out.println("Now is : "
                                                                   + body);
                                                latch.countDown();
                                            } catch (UnsupportedEncodingException e) {
                                                e.printStackTrace();
                                            }
                                        }

                                        @Override
                                        public void failed(Throwable exc,
                                                           ByteBuffer attachment) {
                                            try {
                                                client.close();
                                                latch.countDown();
                                            } catch (IOException e) {
                                                // ingnore on close
                                            }
                                        }
                                    });
                        }
                    }

                    @Override
                    public void failed(Throwable exc, ByteBuffer attachment) {
                        try {
                            client.close();
                            latch.countDown();
                        } catch (IOException e) {
                            // ingnore on close
                        }
                    }
                });
    }

    @Override
    public void failed(Throwable exc, AsyncTimeClientHandler attachment) {
        exc.printStackTrace();
        try {
            client.close();
            latch.countDown();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

```
异步Socket Channel是被动执行对象， 我们不需要像 NIO编程那样创建一个独立的 I/O线程来处理读写操作。 对于AsynchronousServerSocketChannel和AsynchronousSocketChannel,它们都由JDK底层的线程池负责回调并驱动读写
操作

#4中IO模型功能和特性对比
![io_comare](https://keji-image.oss-cn-hangzhou.aliyuncs.com/keji-blog-hexo/io_compare.png)
