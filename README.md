# Ltsv parser plugin for Embulk


## Overview

* **Plugin type**: parser
* **Guess supported**: yes

## Configuration

- **option1**: description (integer, required)
- **option2**: description (string, default: `"myvalue"`)
- **null_value_pattern**: null value pattern. (string, default: `null`)

## Example

```yaml

in:
  type: file
  path_prefix: /Users/toyama-h/access_log-20150616.ltsv.gz
  decoders:
  - {type: gzip}
  parser:
    type: ltsv
    charset: UTF-8
    newline: CRLF
    null_value_pattern: ^(-|null|NULL)$
    schema:
      - {name: host, type: string}
      - {name: ip_address, type: string}
      - {name: server, type: string}
      - {name: remote_user, type: string}
      - {name: log_time, type: timestamp, time_format: '%d/%b/%Y:%H:%M:%S %z'}
      - {name: method, type: string}
      - {name: path, type: string}
      - {name: protocol, type: string}
      - {name: status, type: long}
      - {name: size, type: string}
      - {name: referer, type: string}
      - {name: user_agent, type: string}
      - {name: response_time, type: long}
exec: {}
out: {type: stdout}


```

(If guess supported) you don't have to write `parser:` section in the configuration file. After writing `in:` section, you can let embulk guess `parser:` section using this command:

```
$ embulk gem install embulk-parser-ltsv
$ embulk guess -g ltsv config.yml -o guessed.yml
```

## Build

```
$ rake
```
