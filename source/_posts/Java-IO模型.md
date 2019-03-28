title: Java IO模型
author: 克己
tags: []
categories: []
date: 2019-03-20 20:46:00
---
# Linux系统的五种IO模式

Java 的 IO 模型本质上还是利用操作系统提供的接口来实现,所以最好先了解Linux底层模型。推荐阅读[Linux IO模式及 select、poll、epoll详解](https://segmentfault.com/a/1190000003063859?utm_source=Weibo&utm_medium=shareLink&utm_campaign=socialShare&from=timeline&isappinstalled=0)

# Java IO模型的演变

# BIO

在JDK1.4之前，基于Java的所有Socket通信都采用同步阻塞模式(BIO)，这种一请求一应答的通信模型简化了上层的应用开发，但是在性能和可靠性方面却存在着巨大的瓶颈。当并发量增大，响应时间延迟增大之后，采用Java BIO开发的服务端只有通过硬件的不断扩容来满足高并发和低延迟，它极大的增加了企业的成本，笨企鹅随着集群规模的不断膨胀，系统的可维护性也面临巨大的挑战。

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

![classic_service_design](images/classic_service_design.png)

经典(传统)的网络服务设计如上图所示，对每个请求都会产生一个新的线程来进行处理，这种设计的缺点是，线程的创建本身是系统资源的一个开销，如果并发请求达到一定数量，响应将会变慢，甚至有可能因为系统资源不足而造成系统崩溃。

## 伪异步I/O编程

为了解决同步阻塞I/O面临的一个链路需要一个线程处理的问题，后来有人对它的线程模型进行了优化，后端通过一个线程池来处理多个客户端的请求接入，形成客户端个数线程池最大线程数W的比例关系，其中A/可以远远大于M通过线程池可以灵活的调配线程资源， 设置线程的最大值， 防止由于海量并发接入导致线程耗尽。

![746143-20171024093026988-682603426](images/746143-20171024093026988-682603426.png)

当有新的客户端接入的吋候，将客户端的Socket封装成一个Task （该任务实现java.lang.Runnable接口）投递到后端的线程池中进行处理，JDK的线程池维护一个消息队列和/V个活跃线程对消息队列中的任务进行处理。由于线程池可以设置消息队列的大小和最大线程数，因此，它的资源占用是可控的，无论多少个客户端并发访问，都不会导致资
源的耗尽和宕机。


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

伪异步IO解决的线程的频繁创建销毁问题，但是如果通信对方返回应答时间过长，会引起级联故障:
1. 服务端处理缓慢，返回应答消息耗费60s，平时只需要10ms。
2. 采用伪异步IO的线程正在读取故障服务节点的响应，由于读取输入流是阻塞的，因此，它将会被同步阻塞60s。
3. 假如所有的可用线程都被故障服务器阻塞，那后续所有的IO消息都将在队列中排队。
4. 由于线程池采用阻塞队列实现，将队列积满之后，后续入队列的操作将被阻塞。
5. 由于前段只有一个Accptor线程接口客户端接入，它被阻塞在线程池的同步阻塞队列之后，新的客户端请求消息将被拒绝，客户端会发生大量的连接超时。
6. 由于几乎所有的连接都超时，调用者会认为系统崩溃，无法接受新的请求消息。



# NIO

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

## NIO类库概念和功能介绍

### 缓冲区Buffer

Buffer是一个对象，它包含一些要写入或者要读出的数据。在NIO库中，所有数据都是用缓冲区处理的。在读取数据时，它是直接读到缓冲区中的；在写入数据时，写入到缓冲区中。任何吋候访问NIO中的数据，都是通过缓冲区进行操作。

缓冲区实质上是一个数组。通常它是一个字节数组(ByteBuffer),也可以使用其他种类的数组。似是一个缓冲区**不仅仅**是一个数组，缓冲区提供了对数据的结构化访问以及维护读写位置(limit)等信息。

最常用的缓冲区是ByteBuffer, 一个ByteBuffer提供了一组功能用于操作byte数组。除了 ByteBuffer,还有其他的一些缓冲区，事实上，每一种Java基本类型(除了 Boolean类型)都对应有一种缓冲区，具体如下。

* ByteBuffer：字节缓冲区
* CharBuffer：字符缓冲区
* ShortBuffer：短整型缓冲K
* IntBuffer：整形缓冲区
* LongBuffer：长整形缓冲区
* FloatBuffer：浮点型缓冲区
* DoubleBuffer： 双精度浮点型缓冲区

![BufferUml](images/BufferUml.png)

每—个Buffer类都是Buffer接口的一个T实例。除了 ByteBuffer,每一个Buffe类都有完全一样的操作，只是它们所处理的数据类型不一样。因为大多数标准I/O操作都使用ByteBuffer,所以它除了具有一般缓冲区的操作之外还提供一些特有的操作，方便网络读写。

### 管道channel

Channel是一个通道，可以通过它读取和写入数据，它就像自来水管一样，网络数据通过Channel读取和写入。通道与流的不同之处在于通道是双向的，流只是在一个方向上移动（一个流必须是InputStream或者OutputStream的子类），而且通道可以用于读、写或者同时用于读写。

Channel的类继承图如下。
![ChannelUml](images/ChannelUml.png)


因为Channel是全双工的，所以它可以比流更好地映射底层操作系统的API。特别是在UNIX网络编程模型中，底层操作系统的通道都是全双工的，同时支持读写操作。



# AIO

# 同步IO

# 异步IO