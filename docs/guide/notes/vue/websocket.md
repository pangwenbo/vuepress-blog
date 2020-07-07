# websocket使用说明
## 1、创建工具类websocket.js
``` js
    class socket {
            /* websocket实例 */
            ws = null
    
            /*'#'为私有属性，外部不可调用 */
    
            /* 状态 */
            //连接状态
            #alive = false
            //把类的参数传入这里，方便调用
            #params = null
    
            /* 计时器 */
            //重连计时器
            #reconnect_timer = null
            //心跳计时器
            #heart_timer = null
            // 信息onmessage缓存方法
            #message_func = null
    
    
            /* 参数 */
            //心跳时间 50秒一次
            heartBeat = 10000
            //心跳信息：默认为‘hello’随便改，看后台
            heartMsg = 'hello'
            //是否自动重连
            reconnect = true
            //重连间隔时间
            reconnectTime = 5000
            //重连次数
            reconnectTimes = 10
    
            constructor(params) {
                    this.#params = params
                    this.init()
            }
    
            /* 初始化 */
            init() {
                    //重中之重，不然重连的时候会越来越快
                    clearInterval(this.#reconnect_timer)
                    clearInterval(this.#heart_timer)
    
                    //取出所有参数
                    let params = this.#params
                    //设置连接路径
                    let { url, port } = params
                    let global_params = ['heartBeat', 'heartMsg', 'reconnect', 'reconnectTime', 'reconnectTimes']
    
                    //定义全局变量
                    Object.keys(params).forEach(key => {
                            if (global_params.indexOf(key) !== -1) {
                                    this[key] = params[key]
                            }
                    })
    
                    let ws_url = port ? url + ':' + port : url
    
                    // this.ws = null
                    delete this.ws
                    this.ws = new WebSocket(ws_url)
    
                    // window.console.log(this.#message_func)
                    if (this.#message_func) {
                            this.onmessage(this.#message_func)
                    }
    
    
                    //默认绑定事件
                    this.ws.onopen = () => {
                            //设置状态为开启
                            this.#alive = true
                            clearInterval(this.#reconnect_timer)
                            //连接后进入心跳状态
                            this.onheartbeat()
                    }
                    this.ws.onclose = () => {
                            //设置状态为断开
                            this.#alive = false
    
                            clearInterval(this.#heart_timer)
    
                            //自动重连开启  +  不在重连状态下
                            if (true == this.reconnect) {
                                    /* 断开后立刻重连 */
                                    this.onreconnect()
                            }
                    }
            }
    
    
            /*
             *
             * ‘心跳事件’和‘重连事件’
             *
             */
    
            /* 心跳事件 */
            onheartbeat(func) {
                    //在连接状态下
                    if (true == this.#alive) {
                            /* 心跳计时器 */
                            this.#heart_timer = setInterval(() => {
                                    //发送心跳信息
                                    this.send(this.heartMsg)
                                    func ? func(this) : false
    
                            }, this.heartBeat)
                    }
            }
    
            /* 重连事件 */
            onreconnect(func) {
                    /* 重连间隔计时器 */
                    this.#reconnect_timer = setInterval(() => {
                            //限制重连次数
                            if (this.reconnectTimes <= 0) {
                                    //关闭定时器
                                    // this.#isReconnect = false
                                    clearInterval(this.#reconnect_timer)
                                    //跳出函数之间的循环
                                    return;
                            } else {
                                    //重连一次-1
                                    this.reconnectTimes--
                            }
                            //进入初始状态
                            this.init()
                            func ? func(this) : false
                    }, this.reconnectTime)
            }
    
            /*
             *
             * 对原生方法和事件进行封装
             *
             */
    
            // 发送消息 
            send(text) {
                    if (true == this.#alive) {
                            text = typeof text == 'string' ? text : JSON.stringify(text)
                            this.ws.send(text)
                    }
            }
    
            // 断开连接
            close() {
                    if (true == this.#alive) {
                            this.ws.close()
                    }
            }
    
            //接受消息
            onmessage(func, all = false) {
                    this.ws.onmessage = data => {
                            this.#message_func = func
                            func(!all ? data.data : data)
                    }
            }
    
            //websocket连接成功事件
            onopen(func) {
                    this.ws.onopen = event => {
    
                            this.#alive = true
                            func ? func(event) : false
    
                    }
            }
            //websocket关闭事件
            onclose(func) {
                    this.ws.onclose = event => {
    
                            //设置状态为断开
                            this.#alive = false
    
                            clearInterval(this.#heart_timer)
    
                            //自动重连开启  +  不在重连状态下
                            if (true == this.reconnect) {
                                    /* 断开后立刻重连 */
                                    this.onreconnect()
                            }
                            func ? func(event) : false
                    }
            }
            //websocket错误事件
            onerror(func) {
                    this.ws.onerror = event => {
                            func ? func(event) : false
                    }
            }
    }
    
    export default socket
``` 

## 2、使用方式 vue store.js
``` js
    const state = {
            ws: () => {
            },
    }
    const getters = {
            ws: state => state.ws, //websocket
    }
    const mutations = {
            [types.SET_WS](state, ws) { 
                    state.ws = ws
            },
    }
    const actions = {
            //提交ws实例
            setWs({ commit }, param) {
                    return commit(types.SET_WS, param)
            },
    }
```	
## 3、vue中使用


一般把new socket({****})之后保存在vuex的state中，全局方便调用而且可以保留状态，保证整个系统只存在一个ws连接
``` js
    	import { mapActions, mapGetters } from "vuex";
    	import websocket from "@/utils/websocket.js";
    	export default {
    		name: "App",
    		computed: {
    			...mapGetters(["ws"])
    		},
    		mounted() {
    			let socket = new websocket({
    				url: "ws://127.0.0.1:8001"
    			});
    			this.setWs(socket);
    			this.ws.onmessage(data => {
    				console.log(data);
    			});
    			// this.ws.send("发送消息");
    		},
    		methods: {
    			...mapActions(["setWs"])
    		}
    	};
``` 
## 4、测试


npm先安装（可以在vue的根目录直接装，把下面的server.js也放到根目录）

``` js
    npm i nodejs-websocket
```
	
测试创建server.js

``` js
    let ws = require("nodejs-websocket")
    let port = 8001
    let heart_beat = 60 //每60秒内需要客户端心跳一次，否则关闭连接
    
    let server = ws.createServer(function (conn) {
    
            //计算心跳时间
            conn.heart_time = 0
    
            let timer = setInterval(() => {
                    //检查心跳时间
                    if (conn.heart_time > heart_beat) {
                            clearInterval(timer);
                            conn.close()
                    }
                    conn.heart_time++
            }, 1000)
            // function sendOne () {
            //     conn.sendText
            // }
            // function sendAll () {
            //     for ()
            //     conn.sendText
            // }
            //根据时间戳生成用户id uid
            let uid = String((new Date()).getTime()).slice(-6)
            conn.uid = uid
            console.log('用户' + uid + ' 已经连接')
            // console.log(uid+' is connected')
    
            conn.sendText('Hello man!' + uid)
    
            //接受到发过来的信息
            conn.on("text", function (text) {
                    //重置心跳
                    conn.heart_time = 0
                    if (text == 'hello') {
                            //设置的心跳信息，不做任何处理直接返回
                            conn.sendText('心跳连接:' + text)
                            return
                    }
                    //  console.log('get user:' + conn.uid + ' message:' + text)
    
                    conn.sendText('接收到的信息:' + text)
            })
    
            //断开连接的回调
            conn.on("close", function (code, reason) {
                    console.log('用户' + uid + ' 已经断开连接')
            })
    
            //处理错误事件信息
            conn.on('error', function (err) {
                    console.log('用户' + uid + ' 已经断开连接，错误原因： ' + err)
            })
    }).listen(port);//8001端口
    console.log('ws://127.0.0.1:' + port + ' is runing.')
``` 	
## 5、最后
node server.js