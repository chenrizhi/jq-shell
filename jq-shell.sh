#!/bin/bash

jsonq() {
    json=$(cat)
    awk -v json="$json" -v json_orgi="$json" -v key="$1" '
    function strlastchar(s) {
        return substr(s, length(s), 1)
    }
    function startwith(s, c) {
        start = substr(s, 1, 1)
        return start == c
    }
    function endwith(s, c) {
        return strlastchar(s) == c
    }
    function innerstr(s) { # 取出括号/引号内的内容
        return substr(s, 2, length(s)-2)
    }
    function strindex(s, n) { # 字符串通过下标取值，索引是从1开始的
        return substr(s, n, 1)
    }
    function trim(s) {
        sub("^[ \n]*", "", s);
        sub("[ \n]*$", "", s);
        return s
    }
    function findValueByKey(s, k) {
        if ("\""k"\"" != substr(s, 1, length(k)+2)) {exit 0}
        s = trim(s)
        start = 0; stop = 0; layer = 0
        for (i = 2 + length(k) + 1; i <= length(s); ++i) {
            lastChar = substr(s, i - 1, 1)
            currChar = substr(s, i, 1)
            if (start <= 0) {
                if (lastChar == ":") {
                    start = currChar == " " ? i + 1: i
                    if (currChar == "{" || currChar == "[") {
                        layer = 1
                    }
                }
            } else {
                if (currChar == "{" || currChar == "[") {
                    ++layer
                }
                if (currChar == "}" || currChar == "]") {
                    --layer
                }
                if ((currChar == "," || currChar == "}" || currChar == "]") && layer <= 0) {
                    stop = currChar == "," ? i : i + 1 + layer
                    break
                }
            }
        }
        if (start <= 0 || stop <= 0 || start > length(s) || stop > length(s) || start >= stop) {
            exit 0
        } else {
            return trim(substr(s, start, stop - start))
        }
    }
    function unquote(s) {
        if (startwith(s, "\"")) {
            s = substr(s, 2, length(s)-1)
        }
        if (endwith(s, "\"")) {
            s = substr(s, 1, length(s)-1)
        }
        return s
    }
    BEGIN{
        if (match(key, /^\./) == 0) {exit 0;}
        sub(/\][ ]*\[/,"].[", key)
        split(key, ks, ".")
        if (length(ks) == 1) {print json; exit 0}
        for (j = 2; j <= length(ks); j++) {
            k = ks[j]
            if (startwith(k, "[") && endwith(k, "]") == 1) { # [n]
                idx = innerstr(k)
                currentIdx = -1
                # 找匹配对
                pairs = ""
                json = trim(json)
                if (startwith(json, "[") == 0) {
                    exit 0
                }
                start = 2
                cursor = 2
                for (; cursor <= length(json); cursor++) {
                    current = strindex(json, cursor)
                    if (current == " " || current == "\n") {continue} # 忽略空白
                    if (current == "[" || current == "{") {
                        if (length(pairs) == 0) {start = cursor}
                        pairs = pairs""current
                    }
                    if (current == "]" || current == "}") {
                        if ((strlastchar(pairs) == "[" && current == "]") || (strlastchar(pairs) == "{" && current == "}")) {
                            pairs = substr(pairs, 1, length(pairs)-1) # 删掉最后一个字符
                            if (pairs == "") { # 匹配到了所有的左括号
                                currentIdx++
                                if (currentIdx == idx) {
                                    json = substr(json, start, cursor-start+1)
                                    break
                                }
                            }
                        } else {
                            pairs = pairs""current
                        }
                    }
                }
            } else {
                # 到这里，就只能是{"key": "value"}或{"key":{}}或{"key":[{}]}
                pairs = ""
                json = trim(json)
                if (startwith(json, "[")) {exit 0}
                #if (!startwith(json, "\"") || !startwith(json, "{")) {json="\""json}
                # 找匹配的键
                start = 2
                cursor = 2
                noMatch = 0
                for (; cursor <= length(json); cursor++) {
                    current = strindex(json, cursor)
                    if (current == " " || current == "\n" || current == ",") {continue} # 忽略空白和逗号
                    if (substr(json, cursor, length(k)+2) == "\""k"\"") {
                        json = findValueByKey(substr(json, cursor, length(json)-cursor+1), k)
                        break
                    } else {
                        noMatch = 1
                    }
                    if (noMatch) {
                        pos = match(substr(json, cursor+1, length(json)-cursor), /[^(\\")]"/)
                        ck = substr(substr(json, cursor+1, length(json)-cursor), 1, pos)
                        t = findValueByKey(substr(json, cursor, length(json)-cursor+1), ck)
                        tLen = length(t)
                        sub(/\\/, "\\\\", t)
                        pos = match(substr(json, cursor+1, length(json)-cursor), t)
                        if (pos != 0) {
                            cursor = cursor + pos + tLen
                        }
                        noMatch = 0
                        continue
                    }
                }
            }
        }
        if (json_orgi == json) { print;exit 0 }
        print unquote(json)
    }'
}
doublebackslash() {
    echo "$1" | sed 's/\\/\\\\/g'
}

json=$(cat)
echo "$json" | jsonq $1
