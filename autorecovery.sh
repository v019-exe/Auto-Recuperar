#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo -e "[\033[0;35m\e[1mVOID\e[0m\033[0m][$(date +"%H:%M:%S")]: Ejecuta el script como root"
  exit
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  echo "No se pudo detectar la distribución."
  exit 1
fi

case $DISTRO in
  ubuntu | debian)
    echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Comprobando si está instalado scalpel."
    if command -v scalpel >/dev/null 2>&1; then
      echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Ya está instalado"
    else
      echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Ejecutando apt, instalando scalpel"
      apt install -y scalpel >/dev/null
      clear
    fi
    ;;
  fedora)
    echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Comprobando si está instalado scalpel."
    if command -v scalpel >/dev/null 2>&1; then
        echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Ya está instalado"
    else
        echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Instalando scalpel"
        dnf install -y scalpel >/dev/null
        clear
    fi
    ;;
  arch)
    echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Comprobando si está instalado scalpel."
    if command -v scalpel >/dev/null &>1; then
      echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Ya está instalado"
    else
      echo -e "[INSTALLER][$(date +"%H:%M:%S")]: Instalando scalpel, ejecutando pacman"
      pacman -S --noconfirm scalpel > /dev/null
      clear
    fi
    ;;
  *)
    echo -e "No soportado"
    exit 1
    ;;
esac

color_negro="\033[40m"
color_rojo="\033[41m"
color_verde="\033[42m"
color_amarillo="\033[43m"
color_azul="\033[44m"
color_magenta="\033[45m"
color_cian="\033[46m"
color_blanco="\033[47m"
reset="\033[0m"
negrita="\033[1m"

echo -e "\033[0;35m
            _    __
 _  _____  (_)__/ /
| |/ / _ \/ / _  / 
|___/\___/_/\_,_/  
                   
[*] Github: github.com/v019-exe
[*] Script hecha por v019.exe
[*] OS: $DISTRO
\033[0m"

LOG_FILE="testdisk_recovery.log"

echo -ne "[${color_magenta}${negrita}V0ID${reset}][$(date +"%H:%M:%S")]: Introduce la ruta del disco (ej. /dev/sdb): "
read ruta
echo -ne "[${color_magenta}${negrita}V0ID${reset}][$(date +"%H:%M:%S")]: Introduce el nombre del archivo: "
read nombre_archivo
echo -ne "[${color_magenta}${negrita}V0ID${reset}][$(date +"%H:%M:%S")]: Introduce la ruta de montaje: "
read ruta_montaje
echo -ne "[${color_magenta}${negrita}V0ID${reset}][$(date +"%H:%M:%S")]: Introduce el contenido del archivo: "
read content

autorecovery() {
  echo -e "[${color_amarillo}${negrita}TESTING${reset}][$(date +"%H:%M:%S")]: Comprobando que el disco existe..."

  if [ ! -b "$ruta" ]; then
    echo -e "[${color_rojo}${negrita}ERROR${reset}][$(date +"%H:%M:%S")]: El disco no existe."
    exit 1
  fi

  echo -e "[${color_azul}${negrita}INFO${reset}][$(date +"%H:%M:%S")]: Comprobando si el disco está montado en alguna ubicación..."
  
  if [ -b "$ruta" ] && blkid "$ruta" >/dev/null; then
    FSTYPE=$(lsblk -nr -o FSTYPE $ruta | head -n 3 | tr -d '\n')
    echo -e "[${color_azul}${negrita}DISK INFO${reset}][$(date +"%H:%M:%S")]: El disco está formateado con $FSTYPE"
    echo -e "[${color_amarillo}${negrita}DISK WARN${reset}][$(date +"%H:%M:%S")]: Reformateando el disco duro"
    
    dd if=/dev/zero of=$ruta bs=4M status=progress 2>/dev/null || true
    if [ $? -eq 0 ]; then
      echo -e "[${color_verde}${negrita}DISK SUCCESS${reset}][$(date +"%H:%M:%S")]: El disco ha sido rellenado con ceros correctamente."
    else
      echo -e "[${color_rojo}${negrita}DISK ERROR${reset}][$(date +"%H:%M:%S")]: Ha fallado al rellenar con ceros el disco."
      exit 1
    fi

    mkfs.ext4 "$ruta" >/dev/null
    if [ $? -eq 0 ]; then
      echo -e "[${color_verde}${negrita}DISK SUCCESS${reset}][$(date +"%H:%M:%S")]: Se ha formateado correctamente el disco con ext4"
      echo -e "[${color_amarillo}${negrita}DISK TEST${reset}][$(date +"%H:%M:%S")]: Intentando montar el disco"
      
      mount $ruta $ruta_montaje
      if [ $? -eq 0 ]; then
        echo -e "[${color_verde}${negrita}DISK SUCCESS${reset}][$(date +"%H:%M:%S")]: Disco montado correctamente"
        echo -e "[${color_azul}${negrita}DISK INFO${reset}][$(date +"%H:%M:%S")]: Creando el archivo con el contenido"
        
        echo "$content" >"$ruta_montaje/$nombre_archivo"
        if [ $? -eq 0 ]; then
          echo -e "[${color_azul}${negrita}DISK INFO${reset}][$(date +"%H:%M:%S")]: Se ha creado el archivo correctamente"
          echo -e "[${color_amarillo}${negrita}DISK REMOVAL${reset}][$(date +"%H:%M:%S")]: Eliminando el archivo de forma permanente"
          
          rm -rf "$ruta_montaje/$nombre_archivo"
          if [ $? -eq 0 ]; then
            echo -e "[${color_verde}${negrita}DISK REMOVAL SUCCESS${reset}][$(date +"%H:%M:%S")]: El archivo ha sido eliminado completamente"
          else
            echo -e "[${color_rojo}${negrita}DISK REMOVAL ERROR${reset}][$(date +"%H:%M:%S")]: Error al eliminar el archivo"
            exit 1
          fi
        else
          echo -e "[${color_rojo}${negrita}DISK ERROR${reset}][$(date +"%H:%M:%S")]: Error al crear el archivo con el contenido"
          exit 1
        fi
      else
        echo -e "[${color_rojo}${negrita}DISK ERROR${reset}][$(date +"%H:%M:%S")]: Error al montar el disco $ruta en $ruta_montaje"
        exit 1
      fi
    fi
  else
    echo -e "[${color_azul}${negrita}DISK INFO${reset}][$(date +"%H:%M:%S")]: El disco no tiene formato"
    echo -e "[${color_amarillo}${negrita}DISK WARN${reset}][$(date +"%H:%M:%S")]: Inicializando el formateo"

    dd if=/dev/zero of=$ruta bs=4M status=progress 2>/dev/null || true
    if [ $? -eq 0 ]; then
      echo -e "[${color_verde}${negrita}DISK SUCCESS${reset}][$(date +"%H:%M:%S")]: El disco ha sido rellenado con ceros correctamente."
    else
      echo -e "[${color_rojo}${negrita}DISK ERROR${reset}][$(date +"%H:%M:%S")]: Ha fallado al rellenar con ceros el disco."
      exit 1
    fi

    mkfs.ext4 "$ruta" >/dev/null
    if [ $? -eq 0 ]; then
      echo -e "[${color_verde}${negrita}DISK SUCCESS${reset}][$(date +"%H:%M:%S")]: Se ha formateado correctamente el disco con ext4"
      echo -e "[${color_amarillo}${negrita}DISK TEST${reset}][$(date +"%H:%M:%S")]: Intentando montar el disco"
      
      mount $ruta $ruta_montaje
      if [ $? -eq 0 ]; then
        echo -e "[${color_verde}${negrita}DISK SUCCESS${reset}][$(date +"%H:%M:%S")]: Disco montado correctamente"
        echo -e "[${color_azul}${negrita}DISK INFO${reset}][$(date +"%H:%M:%S")]: Creando el archivo con el contenido"
        
        echo "$content" >"$ruta_montaje/$nombre_archivo"
        if [ $? -eq 0 ]; then
          echo -e "[${color_azul}${negrita}DISK INFO${reset}][$(date +"%H:%M:%S")]: Se ha creado el archivo correctamente"
          echo -e "[${color_amarillo}${negrita}DISK REMOVAL${reset}][$(date +"%H:%M:%S")]: Eliminando el archivo de forma permanente"
          
          rm -rf "$ruta_montaje/$nombre_archivo"
          if [ $? -eq 0 ]; then
            echo -e "[${color_verde}${negrita}DISK REMOVAL SUCCESS${reset}][$(date +"%H:%M:%S")]: El archivo ha sido eliminado completamente"
            echo -e "[${color_azul}${negrita}DISK UMOUNT${reset}][$(date +"%H:%M:%S")]: Intentando desmontar el disco"
            umount "$ruta"
            if [ $? -eq 0 ]; then
              echo -e "[DISK UMOUNT SUCCESS][$(date +"%H:%M:%S")]: El disco ha sido desmontado correctamente"
              echo -e "[CONFIG][$(date +"%H:%M:%S")]: Configurando scapel..."
              echo "txt     y       100000" | sudo tee -a /etc/scalpel/scalpel.conf
              if [ $? -eq 0 ]; then
                echo -e "[CONFIG SUCCESS][$(date +"%H:%M:%S")]: Se ha configurado correctamente"
                echo -e "[CONFIG][$(date +"%H:%M:%S")]: Verificando si se ha configurado correctamente"
                grep "txt" /etc/scalpel.conf > /dev/null
                if [ $? -eq 0 ]; then
                  echo -e "[CONFIG SUCCESS][$(date +"%H:%M:%S")]: La verificación ha tenido éxito"
                  echo -e "[RECOVERY INIT][$(date +"%H:%M:%S")]: Iniciando la recuperación"
                  echo -e "[RECOVERY INIT][$(date +"%H:%M:%S")]: Creando la carpeta de archivos recuperados"
                  mkdir ./recovery
                  if [$? -eq 0 ]; then
                    echo -e "[RECOVERY INIT][$(date +"%H:%M:%S")]: Se ha creado la carpeta correctamente"
                    echo -e "[RECOVERY][$(date +"%H:%M:%S")]: Recuperando archivos..."
                    sudo scalpel "$ruta" -o /home/usuario/recuperados
                    if [ $? -eq 0 ]; then
                      echo -e "[RECOVERY][$(date +"%H:%M:%S")]: Comprueba si se han recuperado los archivos en ./recovery"
                    else
                      echo -e "[RECOVERY ERROR][$(date +"%H:%M:%S")]: Error al recuperar los archivos"
                      exit 1
                    fi
                  else
                    echo -e "[RECOVERY ERROR][$(date +"%H:%M:%S")]: Hubo un error al crear la carpeta."
                  fi
                else
                  echo -e "[CONFIG ERROR][$(date +"%H:%M:%S")]: Hubo un error al verificar, error en la configuración"
                  exit 1
                fi
              else
                echo -e "[CONFIG ERROR][$(date +"%H:%M:%S")]: Error al configurar scapel"
                exit 1
              fi
            else
              echo -e "[ERROR][$(date +"%H:%M:%S")]: Error al desmontar el disco"
            fi
          else
            echo -e "[${color_rojo}${negrita}DISK REMOVAL ERROR${reset}][$(date +"%H:%M:%S")]: Error al eliminar el archivo"
            exit 1
          fi
        else
          echo -e "[${color_rojo}${negrita}DISK ERROR${reset}][$(date +"%H:%M:%S")]: Error al crear el archivo con el contenido"
          exit 1
        fi
      else
        echo -e "[${color_rojo}${negrita}DISK ERROR${reset}][$(date +"%H:%M:%S")]: Error al montar el disco $ruta en $ruta_montaje"
        exit 1
      fi
    fi
  fi
}

autorecovery

