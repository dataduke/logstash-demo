# Logstash-Demo

| `dev` | `master` |
| :---: | :------: |
| [![CircleCI](https://circleci.com/gh/dataduke/logstash-demo/tree/dev.svg?style=svg)](https://circleci.com/gh/dataduke/logstash-demo/tree/dev) | [![CircleCI](https://circleci.com/gh/dataduke/logstash-demo/tree/master.svg?style=svg)](https://circleci.com/gh/dataduke/logstash-demo/tree/master) |

---

## Usage

```
bash build.sh
export LS_INPUT=<value>                   # values: log
export LS_OUTPUT=<comma,seperated,values> # values: console,log,elasticsearch
export LS_CONFIG=</local/logstash/config>
export LS_LOG=</local/application/log>
mkdir -p $LS_CONFIG $LS_LOG
cp log/ $LS_LOG/
bash start.sh                             # wait until log is processed
bash stop.sh                              # validate output see ouput types
```
