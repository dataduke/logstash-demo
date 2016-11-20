# Logstash-Demo

| `dev` | `master` |
| :---: | :------: |
| [![Circle CI](https://circleci.com/gh/ePages-de/docker-logstash/tree/dev.svg?style=svg&circle-token=9b3456474fd889f35316f663edce2af2b16777e7)](https://circleci.com/gh/ePages-de/to-logstash/tree/dev) | [![Circle CI](https://circleci.com/gh/ePages-de/docker-logstash/tree/master.svg?style=svg&circle-token=9b3456474fd889f35316f663edce2af2b16777e7)](https://circleci.com/gh/ePages-de/to-logstash/tree/master) |

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
