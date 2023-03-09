## Установка ПО
### Vagrant
Переходим на https://developer.hashicorp.com/vagrant/downloads выбираем соответствующую версию. В данном случае Linux\Ubuntu 64-bit и версия 2.3.4. Копируем ссылку и в консоли выполняем:
```
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```
После успешного окончания будет установлен Vagrant.
### Packer
Переходим на https://developer.hashicorp.com/packer/downloads выбираем соответствующую версию. В данном случае Linux\Ubuntu 64-bit и версия 1.8.6. Копируем ссылку и в консоли выполняем:
```
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
```
После успешного окончания будет установлен Packer.

------------

# Kernel update
### Клонирование и запуск
Для выполнения этого действия требуется установить приложением git:
`git clone https://github.com/altyn-kenzhebaev/hw-1.git`
В текущей директории появится папка с именем репозитория. В данном случае hw-1. Ознакомимся с содержимым:
```
cd hw-1
ls -l
README.md
packer
Vagrantfile
```
Здесь:
- README.md - файл с данным руководством
- packer -  директория со скриптами для `packer`'а
- Vagrantfile - файл описывающий виртуальную инфраструктуру для `Vagrant`

Запустим виртуальную машину и залогинимся:
```bash
$ vagrant up
Bringing machine 'kernel-update' up with 'virtualbox' provider...
==> kernel-update: Importing base box 'centos/stream8'...
...
==> kernel-update: Booting VM...
...
==> kernel-update: Setting hostname...
$ vagrant ssh
[vagrant@kernel-update ~]$ uname -r
4.18.0-277.el8.x86_64
```
Теперь приступим к обновлению ядра.
### kernel update
Подключаем репозиторий, откуда возьмем необходимую версию ядра:
```
sudo yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm 
```
В репозитории есть две версии ядер:
kernel-ml — свежие и стабильные ядра
kernel-lt — стабильные ядра с длительной версией поддержки, более старые, чем версия ml.

Установим последнее ядро из репозитория elrepo-kernel:
```
sudo yum --enablerepo elrepo-kernel install kernel-ml -y
```
Параметр --enablerepo elrepo-kernel указывает что пакет ядра будет запрошен из репозитория elrepo-kernel.
Уже на этом этапе можно перезагрузить нашу виртуальную машину и выбрать новое ядро при загрузке ОС.
### grub update
После успешной установки нам необходимо сказать системе, что при загрузке нужно использовать новое ядро. В случае обновления ядра на рабочих серверах необходимо перезагрузиться с новым ядром, выбрав его при загрузке. И только при успешно прошедших загрузке нового ядра и тестах сервера переходить к загрузке с новым ядром по-умолчанию. В тестовой среде можно обойти данный этап и сразу назначить новое ядро по-умолчанию.
Обновляем конфигурацию загрузчика:
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
Выбираем загрузку с новым ядром по-умолчанию:
```
sudo grub2-set-default 0
```
Перезагружаем виртуальную машину:
```
sudo reboot
```
После перезагрузки виртуальной машины (3-4 минуты, зависит от мощности хостовой машины) заходим в нее и выполняем:
```
uname -r
```

------------

# Packer
Теперь  создаем свой образ системы, с уже установленым ядром 6й версии. Для это воспользуемся ранее установленной утилитой packer. В директории packer есть все необходимые настройки и скрипты для создания необходимого образа системы.
### packer provision config
Файл centos.json содержит описание того, как произвольный образ. Полное описание можно найти в документации к packer. Обратим внимание на основные секции или ключи.
Создаем переменные (variables) с версией и названием нашего проекта (artifact):
```
"artifact_description": "CentOS Stream 8 with kernel 6.x",
"artifact_version": "8",
"image_name": "centos-8"
```
В секции builders задаем исходный образ, для создания своего в виде ссылки и контрольной суммы. Параметры подключения к создаваемой виртуальной машине.
```
"iso_checksum": "b4bb35e2c074b4b9710419a9baa4283ce4a02f27d5b81bb8a714b576e5c2df7a",
"iso_url": "http://mirror.linux-ia64.org/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-20230209-boot.iso",
```
В секции post-processors указываем имя файла, куда будет сохранен образ, в случае успешной сборки
```
"output": "centos-{{ user `artifact_version` }}-kernel-6-x86_64-Minimal.box"
```
В секции provisioners указываем действия по обновлению ядра, установке дополнительных пакетов для virtualbox-guest-additions, установка virtualbox-guest-additions, чиска образа от ненужных пакетов и временных файлов.  Настройка системы выполняется 3-мя скриптами, заданными в секции scripts.
```
          "scripts": [
            "scripts/stage-1-kernel-update.sh",
            "scripts/stage-2-install-virtualbox-guest-additions.sh",
            "scripts/stage-3-clean.sh"
```
Скрипты будут выполнены в порядке указания. Первый скрипт включает себя набор команд, которые мы ранее выполняли вручную, чтобы обновить ядро. Второй скрипт занимается подготовкой системы к упаковке в образ. Она заключается в очистке директорий с логами, временными файлами, кешами. Это позволяет уменьшить результирующий образ. Более подробно можно ознакомиться с ними в директории packer/scripts
### packer build
Для проверки и дальнейшего создания образа системы достаточно перейти в директорию packer и в ней выполнить команды:
```
packer validate centos.json
packer build centos.json
```
В целях поиска ошибок в моменте создания образа может потребоваться более подробный вывод команд, это можно сделать определив локальную переменную:
```
export PACKER_LOG=1
```
Если все в порядке, то, согласно файла config.json будет скачан исходный iso-образ CentOS, установлен на виртуальную машину в автоматическом режиме, обновлено ядро и осуществлен экспорт в указанный нами файл. Если не вносилось изменений в предложенные файлы, то в текущей директории мы увидим файл centos-8-kernel-6-x86_64-Minimal.box. Он и является результатом работы packer.
### vagrant init (тестирование)
Проведем тестирование созданного образа. Выполним его импорт в vagrant:
```
vagrant box add centos8-kernel6 centos-8-kernel-6-x86_64-Minimal.box
```
Проверим его в списке имеющихся образов (ваш вывод может отличаться):
```
vagrant box list
centos/7                        (virtualbox, 2004.01)
centos/stream8                  (virtualbox, 20210210.0)
centos8-kernel6                 (virtualbox, 0)
ubuntu/focal64                  (virtualbox, 20230215.0.0)
```
Он называется centos8-kernel6, данное имя мы задали при помощи параметра name при импорте.
Теперь необходимо провести тестирование полученного образа. Для этого создадим новый Vagrantfile или воспользуемся имеющимся. Для нового создадим директорию test и в ней выполним:
```
vagrant init centos8-kernel6
```
Для появившегося Vagrantfile проверим значения box_name, который должен совпадать с именем импортированного образа. Соотвествующая строка примет вид:
```
:box_name => "centos8-kernel6",
```
Теперь запустим виртуальную машину, подключимся к ней и проверим, что у нас в ней новое ядро:
```
vagrant up
...
vagrant ssh   
```
и внутри виртуальной машины:
```
$ vagrant ssh
Last login: Fri Mar  3 06:23:03 2023 from 10.0.2.2
[vagrant@otus-c8 ~]$ uname -r
6.2.1-1.el8.elrepo.x86_64
```
Если все в порядке, то машина будет запущена и загрузится с новым ядром.

Удалим тестовый образ из локального хранилища:
```
vagrant destroy --force
```

------------
# Vagrant cloud
Поделимся полученным образом с сообществом. Для этого зальем его в Vagrant Cloud. Можно залить через web-интерфейс, но так же vagrant позволяет это проделать через CLI. Логинимся в vagrant cloud, указывая e-mail, пароль и описание выданого токена (можно оставить по-умолчанию)
```
vagrant cloud auth login
Vagrant Cloud username or email: <user_email>
Password (will be hidden): 
Token description (Defaults to "Vagrant login from DS-WS"):
You are now logged in.
```
Теперь публикуем полученный бокс:
```
vagrant cloud publish --release altynkenzhebaev/centos8-kernel6 1.0 virtualbox centos-8-kernel-6-x86_64-Minimal.box
```
здесь:
- cloud publish - загрузить образ в облако;
- altynkenzhebaev/centos8-kernel6  - altynkenzhebaev - это username, указаный при публикации и имя образа;
- 1.0 - версия образа;
- virtualbox - провайдер;
- centos-8-kernel-6-x86_64-Minimal.box - имя файла загружаемого образа.
После успешной загрузки вы получите сообщение:
```
Complete! Published altynkenzhebaev/centos8-kernel6
username:        altynkenzhebaev
name:            centos8-kernel6
private:         false
...
providers:       virtualbox
```
В целях безопасности можем собрать хеш-сумму бокса коммандой:
```
sha256sum centos-8-kernel-6-x86_64-Minimal.box
```
А затем внести значения через веб-портал https://app.vagrantup.com/

В результате создан и загружен в vagrant cloud образ виртуальной машины. Данный подход позволяет создать базовый образ виртульной машины с необходимыми обновлениями или набором предустановленного ПО.
