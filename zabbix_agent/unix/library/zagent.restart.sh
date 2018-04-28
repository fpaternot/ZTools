#!/bin/sh
#===============================================================================
#         FILE: zagent.restart
#        USAGE: ./zagent.restart
#  DESCRIPTION: 
#
#      OPTIONS: 
# REQUIREMENTS:
#
#         BUGS: -*-*-*-*-*-*-*-*-*-*-*-*-*-
#        NOTES: -*-*-*-*-*-*-*-*-*-*-*-*-*-
#
#       AUTHOR:  (Igor Nicoli), <igor (dot) nicoli (at) gmail (dot) com>
#      VERSION:  1.0
#      CREATED:  16/09/2015 18:54:01 BRST
#     REVISION:  -*-*-*-*-*-*-*-*-*-*-*-*-*-
#    CHANGELOG:
#
#===============================================================================

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Nome do sistema operacional:
OSName=`uname|tr '[a-z]' '[A-Z]'`;

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Verifica se o linux esta utilizando init ou systemd:
[ "${OSName}" = "LINUX" ] && INITName=`cat /proc/1/comm`

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Identifica qual comando utilizar para reinicializar o Zabbix Agent com base no
# sistema operacional:
if [ "${OSName}" = "AIX" ]; then
  if [ -e "/etc/rc.d/init.d/zabbix-agent" ]; then
    nohup /etc/rc.d/init.d/zabbix-agent restart 1>/dev/null 2>&1 &
  else
    echo Script de gerenciamento do Zabbix Agent nao encontrado... Reporte esse problema ao desenvolvedor!
  fi

elif [ "${OSName}" = "HP-UX" ]; then
  if [ -e "/sbin/init.d/zabbix-agent" ]; then
    nohup /sbin/init.d/zabbix-agent restart 1>/dev/null 2>&1 &
  else
    echo Script de gerenciamento do Zabbix Agent nao encontrado... Reporte esse problema ao desenvolvedor!
  fi

elif [ "${OSName}" = "LINUX" -a "${INITName}" == "systemd" ]; then
  if [ -e "/usr/lib/systemd/system/zabbix-agent.service" ]; then
    nohup sudo systemctl restart zabbix-agent.service 1>/dev/null 2>&1 &
  else
    echo Script de gerenciamento do Zabbix Agent nao encontrado... Reporte esse problema ao desenvolvedor!
  fi

elif [ "${OSName}" = "LINUX" -a "${INITName}" == "init" ]; then
  if [ -e "/etc/init.d/zabbix-agent" ]; then
    nohup sudo /etc/init.d/zabbix-agent restart 1>/dev/null 2>&1 &
  else
    echo Script de gerenciamento do Zabbix Agent nao encontrado... Reporte esse problema ao desenvolvedor!
  fi

else
  echo Sistema no suportado... Reporte esse problema ao desenvolvedor!
fi

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Mensagem de retorno 
echo Reiniciando o Zabbix Agent...