#!/bin/bash

# Вывод справки
usage() {
  echo "Usage: $0 -i <input_device> -o <output_directory> -b <buffer_size> -s <split_size> -c <compression_level> [-u <restore_device>]"
  exit 1
}

# Проверка наличия пакетов без установки
check_packages() {
  local missing_packages=()

  for pkg in "$@"; do
    if ! dpkg -l | grep -qw "$pkg"; then
      missing_packages+=("$pkg")
    fi
  done

  # Если отсутствуют какие-то пакеты, выводим сообщение
  if [ ${#missing_packages[@]} -ne 0 ]; then
    echo "The following packages are missing: ${missing_packages[@]}. Install them? (y/n)"
    read -r answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      sudo apt-get update && sudo apt-get install -y "${missing_packages[@]}"
    else
      echo "Required packages are not installed. Exiting."
      exit 1
    fi
  fi
}

# Проверка, что выбрано устройство, а не раздел
check_device() {
  local device="$1"
  if [[ "$device" =~ [0-9]+$ ]]; then
    echo "Error: $device is a partition, not a whole device. Specify the whole device (e.g., /dev/mmcblk0)."
    exit 1
  fi
}

# Проверка пустоты устройства
check_device_empty() {
  local device="$1"
  if sudo fdisk -l "$device" | grep -q "Disk label type"; then
    echo "Device $device contains data. Do you want to erase it and continue? (y/n)"
    read -r answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
      echo "Operation cancelled."
      exit 1
    fi
  fi
}

# Проверка, смонтировано ли устройство
check_mount() {
  local mount_point="$1"
  if ! grep -qs "$mount_point" /proc/mounts; then
    echo "Error: mount point $mount_point is not mounted."
    exit 1
  fi
}

# Расширение раздела и файловой системы
expand_partition_and_filesystem() {
  local device="$1"
  local partition="${device}1"  # Первый раздел
  
  echo "Expanding partition on $device to maximum available size..."
  
  sudo parted "$device" resizepart 1 100%
  fs_type=$(sudo blkid -o value -s TYPE "$partition")
  echo "Filesystem type: $fs_type"

  case "$fs_type" in
    ext4)
      echo "Resizing ext4 filesystem..."
      sudo resize2fs "$partition"
      ;;
    xfs)
      echo "Resizing xfs filesystem..."
      sudo xfs_growfs "$partition"
      ;;
    btrfs)
      echo "Resizing btrfs filesystem..."
      sudo btrfs filesystem resize max "$partition"
      ;;
    vfat|fat32)
      echo "Warning: FAT32 does not support dynamic resizing. The remaining space will not be used."
      ;;
    *)
      echo "Unsupported filesystem type: $fs_type"
      ;;
  esac

  echo "Partition and filesystem expansion completed."
}

# Значения по умолчанию
split_size="2G"
compression_level="9"
buffer_size="auto"  # Значение по умолчанию для буфера - автоматический выбор

# Определение количества доступных ядер и использование 80% от общего количества
cpu_count=$(nproc)
thread_count=$(( cpu_count * 80 / 100 ))
if [ "$thread_count" -lt 1 ]; then
  thread_count=1
fi

# Обработка параметров командной строки
while getopts "i:o:b:s:c:u:" opt; do
  case $opt in
    i) input_device="$OPTARG"
    ;;
    o) output_directory="$OPTARG"
    ;;
    b) buffer_size="$OPTARG"
    ;;
    s) split_size="$OPTARG"
    ;;
    c) compression_level="$OPTARG"
    ;;
    u) restore_device="$OPTARG"  # Новый параметр для устройства восстановления
    ;;
    *) usage
    ;;
  esac
done

# Проверка, что заданы обязательные параметры
if [ -z "$output_directory" ]; then
  usage
fi

# Если задано устройство восстановления
if [ ! -z "$restore_device" ]; then
  check_device "$restore_device"
  check_device_empty "$restore_device"  # Проверка, не пустое ли устройство

  echo "Requesting sudo password..."
  sudo -v

  echo "Restoring archive and writing to $restore_device..."
  cat "$output_directory"/mmcblk0_backup.gz.part* | pigz -d | sudo dd of="$restore_device" bs=16M

  if [ $? -eq 0 ]; then
    echo "Restoration completed successfully."
    expand_partition_and_filesystem "$restore_device"
  else
    echo "Error during data restoration."
    exit 1
  fi

  exit 0
fi

# Проверка, что мы копируем с устройства, а не с раздела
check_device "$input_device"

# Проверка существования выходной директории
if [ ! -d "$output_directory" ]; then
  echo "Error: output directory $output_directory does not exist."
  exit 1
fi

# Проверка необходимых пакетов
check_packages pv parallel pigz blockdev parted

# Проверка монтирования устройства
check_mount "$output_directory"

echo "Requesting sudo password..."
sudo -v

echo "Using $cpu_count cores, $thread_count threads for compression."

# Определение исходного размера данных
dd_size=$(sudo blockdev --getsize64 "$input_device" | awk '{ printf "%.2fGB\n", $1/1024/1024/1024 }')
echo "Original data size: $dd_size"

# Основная команда копирования и сжатия
if [ "$buffer_size" == "auto" ]; then
  sudo dd if="$input_device" bs=16M | pv | pigz -$compression_level -p $thread_count | split -b "$split_size" - "$output_directory/mmcblk0_backup.gz.part"
else
  sudo dd if="$input_device" bs=16M | pv | parallel --pipe --block "$buffer_size" -j $thread_count "pigz -$compression_level" | split -b "$split_size" - "$output_directory/mmcblk0_backup.gz.part"
fi

# Определение и вывод сжатого размера данных
compressed_size=$(du -sh "$output_directory/mmcblk0_backup.gz.part"* | cut -f1)
echo "Compressed data size: $compressed_size"
