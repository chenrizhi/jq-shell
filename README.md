# jq-shell

纯shell解析json. 



## 安装

```bash
curl https://raw.githubusercontent.com/chenrizhi/jq-shell/main/jq-shell.sh > /usr/local/bin/jq-shell
chmod +x /usr/local/bin/jq-shell
```



## 测试

- 测试数据1

  ```bash
  json='
  {
      "code": 200,
      "msg": "success",
      "data": {
          "orderNo": "test_order_no"
      }
  }
  '
  
  ~ # echo "$json" | jq-shell ".code"
  200
  
  ~ # echo "$json" | jq-shell ".data"
  {
          "orderNo": "test_order_no"
      }
  
  ```

- 测试数据2

  ```bash
  json='
  [
      [{
          "name": "haxi",
          "age": 18
      },
      {
          "name": "hh",
          "age": 28
      }
      ],
      [{
          "name": "crz"
      }]
  ]
  '
  
  ~ # echo "$json" | jq-shell ".[0][1].name"
  hh
  
  ~ # echo "$json" | jq-shell ".[1][0]"
  {
          "name": "crz"
      }
  ```

- 测试数据3

  ```bash
  json='{"name":"ha\"ha", "age":18}'
  
  ~ # echo "$json" | jq-shell ".name"
  ha"ha
  
  ~ # echo "$json" | jq-shell ".age"
  18
  ```

- 测试数据4

  ```bash
  json='
  {
      "message": "{\"code\": 200}"
  }
  '
  
  ~ # echo "$json" | jq-shell ".message"
  {"code": 200}
  ```

- 测试数据5

  ```json
  json='{"id":"15331352","message":"ok"}'
  
  ~ # echo "$json" | jq-shell ".message"
  ok
  
  ~ # echo "$json" | jq-shell ".id"
  15331352
  ```

- 测试数据6

  ```bash
  json='{"result":"/\n","status":"Done"}'
  
  ~ # echo "$json" | jq-shell ".result"
  /
  
  
  ~ # echo "$json" | jq-shell ".status"
  Done
  ```

  
