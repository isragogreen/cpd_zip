# Copy and Compress Utility

## English

This utility is designed to copy, compress, and restore entire devices, 
such as SD cards and USB sticks. It allows you to create backups of 
devices and store them in multiple compressed parts. When restoring 
data, it writes the backup directly to the target device and expands 
partitions if supported.

### Features

Multi-threaded compression using pigz
Parallel reading and writing of data to increase speed
Dynamic partition resizing for filesystems such as ext4, xfs, and btrfs
Detection of FAT32 with a warning about unused space after restoration
Splitting output files into multiple parts (volumes) for easier 
storage and transfer

### Requirements

Make sure the following packages are installed on your system:

- `pv`
- `parallel`
- `pigz`
- `blockdev`
- `parted`

Install them using the following command:

```bash
sudo apt-get install pv parallel pigz blockdev parted
sudo chmod +x cpd_zip.sh


Options
-i <input_device>
Specifies the device from which data will be copied. This option requires the 
full device path, not just a partition (e.g., /dev/mmcblk0, not /dev/mmcblk0p1).
Example: -i /dev/mmcblk0

-o <output_directory>
Specifies the directory where the compressed output files (volumes) will be saved.
Example: -o /media/user/backup

-b <buffer_size>
Sets the buffer size for reading data from the input device. If not specified, 
the buffer size will be determined automatically.
Example: -b 16M

-s <split_size>
Defines the size of each volume in the output. The output will be split 
into multiple compressed parts, each of the specified size. The default is 2G.
Example: -s 2G

-c <compression_level>
Specifies the compression level, from 1 (fastest, less compression) to 9
 (slowest, maximum compression). The default is 9.
Example: -c 9

-u <restore_device>
Specifies the device to which the backup will be restored. This should be the full device path
 (e.g., /dev/sdc). During restoration, the backup will overwrite the device and attempt to resize 
partitions based on the available space.
Example: -u /dev/sdc

Examples
1. Copy and Compress
To copy and compress data from a device (e.g., /dev/mmcblk0) and save it into multiple compressed volumes:

./scripts/cpd_zip.sh -i /dev/mmcblk0 -o /media/user/backup -b 16M -s 2G -c 9

This command will copy data from the device /dev/mmcblk0, compress it using 
pigz with a compression level of 9, and save the output into multiple parts 
of 2GB each in the directory /media/user/backup.

2. Restore
To restore the previously created backup to a target device (e.g., /dev/sdc):

bash
Copy code
./scripts/cpd_zip.sh -o /media/user/backup -u /dev/sdc

This command will read the compressed volumes from the directory 
/media/user/backup, decompress the data, and write it to the device 
/dev/sdc. If the device is larger than the original backup, the script 
will attempt to resize the partitions to use the entire available space.

Additional Information
Supported Filesystems
ext4: Automatically resized after restoration.
xfs: Automatically resized after restoration.
btrfs: Automatically resized after restoration.
FAT32: Does not support dynamic resizing. If the restored data is smaller 
than the target device, the remaining space will not be used.

Error Handling
If an error occurs during the restoration process, the script will terminate 
and display an error message.


To add the path to your script to the $PATH variable, follow these steps:

Open the shell configuration file
To permanently add the path to the $PATH variable, you need to 
edit the shell configuration file. This could be one of the following 
files, depending on the shell you are using:
For bash: the ~/.bashrc or ~/.bash_profile file
For zsh: the ~/.zshrc file
Example for bash:

nano ~/.bashrc

Add the following line at the end of the file
Assuming your script is located in the /path/to/your/scripts directory, add this line:
export PATH="$PATH:/path/to/your/scripts"

Save the file and apply the changes
Save the file and run the following command to apply the changes in the current session:
source ~/.bashrc
Now your script will be available to run from any directory without specifying the full path.

./cpd_zip.sh -i /dev/mmcblk0 -o /media/user/backup -b 16M -s 2G -c 9


Утилита для копирования и сжатия данных
Русский
Эта утилита предназначена для копирования, сжатия и восстановления 
целых устройств, таких как SD-карты и USB-накопители. Она позволяет 
создавать резервные копии устройств и сохранять их в несколько 
сжатых частей. При восстановлении данных утилита записывает резервную 
копию непосредственно на целевое устройство и расширяет разделы, 
если это поддерживается.

Особенности
Многопоточное сжатие с использованием `pigz`
- Параллельное чтение и запись данных для повышения скорости
- Динамическое расширение разделов для файловых систем, таких как `ext4`, `xfs` и `btrfs`
- Обнаружение FAT32 с предупреждением о неиспользуемом пространстве после восстановления
- Разделение выходных файлов на несколько частей (томов) для удобного хранения и передачи



Требования
Убедитесь, что на вашей системе установлены следующие пакеты:

pv
parallel
pigz
blockdev
parted
Установите их с помощью следующей команды:

sudo apt-get install pv parallel pigz blockdev parted
sudo chmod +x cpd_zip.sh

Опции
-i <устройство_ввода>
Указывает устройство, с которого будут копироваться данные. 
Эта опция требует указания полного пути к устройству, а не 
к разделу (например, /dev/mmcblk0, а не /dev/mmcblk0p1).
Пример: -i /dev/mmcblk0

-o <выходная_директория>
Указывает директорию, в которой будут сохранены сжатые файлы (тома).
Пример: -o /media/user/backup

-b <размер_буфера>
Задает размер буфера для чтения данных с устройства ввода. 
Если не указано, размер буфера будет определён автоматически.
Пример: -b 16M

-s <размер_тома>
Определяет размер каждого тома в выходных данных. Результат 
будет разделён на несколько сжатых частей заданного размера. 
По умолчанию размер тома — 2G.
Пример: -s 2G

-c <степень_сжатия>
Указывает уровень сжатия от 1 (самый быстрый, наименьшее сжатие) 
до 9 (самый медленный, максимальное сжатие). По умолчанию используется уровень 9.
Пример: -c 9

-u <устройство_для_восстановления>
Указывает устройство, на которое будет восстановлена резервная 
копия. Необходимо указать полный путь к устройству (например, /dev/sdc). 
Во время восстановления данные будут перезаписаны на устройство, 
и скрипт попытается расширить разделы в зависимости от доступного пространства.
Пример: -u /dev/sdc

Примеры
1. Копирование и сжатие
Чтобы скопировать и сжать данные с устройства (например, /dev/mmcblk0) 
и сохранить их в несколько сжатых томов:

./scripts/cpd_zip.sh -i /dev/mmcblk0 -o /media/user/backup -b 16M -s 2G -c 9

Эта команда скопирует данные с устройства /dev/mmcblk0, 
сожмёт их с помощью pigz с уровнем сжатия 9 и сохранит 
результат в виде нескольких файлов размером по 2 ГБ в 
директории /media/user/backup.

2. Восстановление
Чтобы восстановить ранее созданную резервную копию на целевое 
устройство (например, /dev/sdc):

./scripts/cpd_zip.sh -o /media/user/backup -u /dev/sdc


Эта команда прочитает сжатые тома из директории /media/user/backup, 
распакует данные и запишет их на устройство /dev/sdc. Если 
устройство больше, чем оригинальная резервная копия, 
скрипт попытается расширить разделы для использования всего доступного 
пространства.

Дополнительная информация
Поддерживаемые файловые системы
ext4: Автоматически расширяется после восстановления.
xfs: Автоматически расширяется после восстановления.
btrfs: Автоматически расширяется после восстановления.
FAT32: Не поддерживает динамическое расширение. Если восстановленные 
данные меньше, чем целевое устройство, оставшееся пространство не будет использовано.
Обработка ошибок
Если во время процесса восстановления произошла ошибка, скрипт завершит 
работу и выведет сообщение об ошибке.


Чтобы добавить путь к вашему скрипту в переменную $PATH, выполните следующие шаги:

1. Откройте файл конфигурации оболочки
Для постоянного добавления пути в переменную $PATH, нужно 
отредактировать файл конфигурации оболочки. Это может быть 
один из следующих файлов, в зависимости от используемой оболочки:

Для bash: файл ~/.bashrc или ~/.bash_profile
Для zsh: файл ~/.zshrc
Пример для bash:

nano ~/.bashrc

2. Добавьте следующую строку в конец файла
Предположим, что ваш скрипт находится в директории /path/to/your/scripts, добавьте эту строку:

export PATH="$PATH:/path/to/your/scripts"

3. Сохраните файл и примените изменения
Сохраните файл и выполните следующую команду, чтобы применить изменения в текущей сессии:

source ~/.bashrc
Теперь ваш скрипт будет доступен для запуска из любого каталога 
без указания полного пути.
./cpd_zip.sh -i /dev/mmcblk0 -o /media/user/backup -b 16M -s 2G -c 9
