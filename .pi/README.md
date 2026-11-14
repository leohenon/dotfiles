# [π](https://github.com/earendil-works/pi)

Config: `.pi/agent/settings.json`.

- [Settings and packages](agent/settings.json)
- [Model overrides](agent/models.json)
- [Local extensions](agent/extensions/README.md)
- [Package settings](agent/config/)

```text
agent/
├── settings.json
├── models.json
├── config/
├── extensions/
└── themes/
```

## Deploy

```sh
bash scripts/install-pi-config.sh
```

The [installer](../scripts/install-pi-config.sh) maps package settings to their
required paths under `~/.pi/agent/`. Don't rsync this directory directly.

New package configs need an explicit mapping in the installer.
