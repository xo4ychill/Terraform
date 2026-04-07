# Домашнее задание к занятию «Основы Terraform. Yandex Cloud»

### Задание 1
- [Основной код](<Task01/src/main.tf>)
- Скриншот ЛК Yandex Cloud с созданной ВМ, где видно внешний ip-адрес.
![alt text](<Task01/images/Задание 1.png>)
- Скриншот консоли, curl где видно внешний ip-адрес.
![alt text](<Task01/images/Задание 1.1.png>)
- Описание ошибок в коде:
  - ```Код (main.tf):```
    - Неверное значение параметра ```platform_id = "standart-v4"```
        Допущена орфографическая ошибка: правильное значение — "standard-v" (через d, а не t). Так же в Yandex Cloud нет конфигурации standard-v4, операция создания ВМ завершится ошибкой, правильное значение: standard-v3, standard-v2, standard-v1 и др.
    - Несовместимость количества ядер (cores) с платформой  ```cores  = 1``` минимальное количество vCPU — 2. 
    - Для параметра ```core_fraction = 5```  потребуется использовать платформу ```standard-v1 или standard-v2```
    Ссылки на документацию:
[Платформы виртуальных машин Yandex Cloud](https://yandex.cloud/ru/docs/compute/concepts/vm-platforms#standard-platforms)
[Уровни производительности ВМ (типы платформ)](https://yandex.cloud/ru/docs/compute/concepts/performance-levels#standard)
  - ```Код (providers.tf):```
    - ```service_account_key_file = file("~/.authorized_key.json")```
    Функция ```file()``` в Terraform не раскрывает символ ```~``` (тильда) как домашний каталог пользователя. В большинстве сред это приведёт к ошибке ```no such file or directory```
    [Документация Terraform:](https://developer.hashicorp.com/terraform/language/functions/file)
- Ответы на вопросы:
  - ```preemptible = true``` — создаёт прерываемые ВМ (живёт максимум 24 часа), стоит дешевле, могут быть принудительно остановлены Yandex Cloud в любой момент.
  - ```core_fraction = 5``` — доля гарантированных vCPU. ВМ получает 5 % от полного ядра. 
    - Польза в обучении:
      - снижает стоимость ВМ;
      - можно создавать несколько таких ВМ для изучения сетевого взаимодействия, кластеризации, балансировки и т.д.;
      - достаточно для лабораторных заданий.

### Задание 2
1. [Основной код](<Task02/src/main.tf>)
2. [Переменные](<Task02/src/variables.tf>)
3. terraform plan
    ![alt text](<Task02/images/Задание 2.png>)

### Задание 3
1. [файл 'vms_platform.tf'](<Task03/src/vms_platform.tf>)
2. [Вторая ВМ в файле main.tf: "netology-develop-platform-db"](<Task03/src/main.tf>)
3. ```terraform apply```
  ![alt text](<Task03/images/Задание 3.png>)

### Задание 4
- Вывод значений ip-адресов команды terraform output
- ![alt text](<Task04/images/Задание 4.png>)