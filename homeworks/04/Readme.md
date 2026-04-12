# Домашнее задание к занятию «Продвинутые методы работы с Terraform»

### Задание 1
- ```sudo nginx -t```
![alt text](images/1.png)
![alt text](images/1.0.png)
- скриншот консоли ВМ yandex cloud с их метками
![alt text](images/1.1.png)
![alt text](images/1.1.2.png)
- ```terraform console```

![alt text](images/1.2.png)

### Задание 2
- ```terraform console```

![alt text](images/2.png)
- [документация к модулю с помощью terraform-docs](src/modules/vpc/README.md)

### Задание 3
1. Вывод списка ресурсов в стейте
   - ```terraform state list```
![alt text](images/3.png)
2. Полное удаление модулей из стейта
   - ```terraform state rm module.vpc```
![alt text](images/3.1.png)
   - ```terraform state rm module.marketing_vm```
![alt text](images/3.2.png)
   - ```terraform state rm module.analytics_vm```
![alt text](images/3.2.1.png)
3. Импорт ресурсов обратно:
   - Получение ID ресурсов:
![alt text](images/3.3.png)
   - Импорт сети и подсети (модуль vpc)
![alt text](images/3.3.1.png)
   - Импорт ВМ (модули marketing_vm и analytics_vm)
![alt text](images/3.3.2.png)
   - Проверка ```terraform plan```
![alt text](images/3.3.3.png)