# ru-tunnel

Настройка раздельной маршрутизации (split tunneling) для корректной работы российских сайтов при активном VPN подключении.

## Проблема

Когда VPN настроен с `AllowedIPs = 0.0.0.0/0`, весь трафик идёт через удалённый сервер. Российские сайты при этом могут работать некорректно — медленно грузиться, показывать ошибки или требовать отключить VPN.

Скрипт настраивает раздельную маршрутизацию: российские сайты идут через прямое соединение, остальной трафик продолжает идти через VPN как обычно.

---

## Windows

**Требования**
- Windows 10 / 11
- Права администратора
- Любой VPN клиент (WireGuard, OpenVPN и др.)

**Установка**

1. Скачай `ru-tunnel.bat`
2. Правая кнопка мыши — "Запуск от имени администратора"
3. Нажми Y для подтверждения
4. Подожди пока добавятся маршруты (~11 000 адресов)

Маршруты сохраняются после перезагрузки. Запусти повторно для обновления.

**Удаление**

```powershell
route -f
```

> Внимание: удаляет **все** статические маршруты, не только российские

---

## macOS

**Требования**
- macOS 12+
- curl (встроен в систему)

**Установка**

```bash
curl -O https://raw.githubusercontent.com/SaraKontur/ru-tunnel/main/ru-tunnel.sh
chmod +x ru-tunnel.sh
sudo bash ru-tunnel.sh
```

Скрипт предложит настроить автозапуск при загрузке системы.

> На macOS маршруты сбрасываются после перезагрузки — используй автозапуск

**Удаление автозапуска**

```bash
sudo launchctl unload /Library/LaunchDaemons/com.russia.routes.plist
sudo rm /Library/LaunchDaemons/com.russia.routes.plist
sudo rm /usr/local/bin/russia-routes-startup.sh
```

---

## Linux

**Требования**
- Любой дистрибутив
- curl
- iproute2 (`sudo apt install iproute2`)

**Установка**

```bash
curl -O https://raw.githubusercontent.com/SaraKontur/ru-tunnel/main/ru-tunnel.sh
chmod +x ru-tunnel.sh
sudo bash ru-tunnel.sh
```

**Автозапуск через systemd**

```ini
[Unit]
Description=Russia Split Tunnel Routes
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'curl -s https://www.ipdeny.com/ipblocks/data/countries/ru.zone | while read range; do ip route delete $range 2>/dev/null; ip route add $range via YOUR_GATEWAY 2>/dev/null; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Сохрани в `/etc/systemd/system/russia-routes.service`, замени `YOUR_GATEWAY` на IP своего шлюза, затем:

```bash
sudo systemctl enable russia-routes
sudo systemctl start russia-routes
```

---

## FAQ

**Откуда берётся список IP?**
С сайта [ipdeny.com](https://www.ipdeny.com) — регулярно обновляемая база ~11 000 российских подсетей.

**Нужно ли обновлять маршруты?**
Раз в несколько месяцев. Просто запусти скрипт повторно.

**Работает ли с OpenVPN?**
Да, скрипт добавляет системные маршруты и работает с любым VPN клиентом.

**Видят ли российские сайты мой реальный IP?**
Да — трафик идёт напрямую с твоего IP.

---

Если помогло — поставь ⭐

## Лицензия

MIT
