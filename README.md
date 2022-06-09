# sh
sh

## 直接调用执行
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kevin197011/sh/main/krun)" ${shell_name}
```

## 下载到本地作为工具执行
```bash
curl -o /usr/bin/krun https://raw.githubusercontent.com/kevin197011/sh/main/krun && chmod +x /usr/bin/krun
krun ${shell_name}
```