
# Lista de featerus
- [OK] Restart remoto do Zabbix Agent;
- [OK] Hot Deploy de scripts de monitoração;
- [DV] Atualização automática dos scripts de monitoração;
- [OK] Variáveis de ambiente para facilitar a criação dos scripts;
- [DV] Alteração de parâmetros de configuração do Zabbix Agent/Zattols;


# Keys suportadas

- zagent.restart
   Reinicia o serviço do Zabbix Agent remotamente.

- zagent.config[action,field,<valuer>]
   Consulta/Altera os parâmetros do arquivo de configuração do Zabbix Agent. As acoes possiveis sao: set, get, add e del.

- ztools.config[action,field,<valuer>]
   Consulta/Altera os parâmetros do arquivo de configuração do ZTools. As acoes possiveis sao: set, get, add e del.

- ztools.library.run[script,<parametros>]
   Executa o script presente na library local do ZTools e retorna seu resultado.

- ztools.library.update[<script>]
   Atualiza todos os scripts da library do ZTools que precisam de atualização.

- ztools.user_parameter.update
   Atualiza o arquivo de configuração de user_parameter do ZTools.


# Arvore de diretorio padrao:
```
### ZABBIX AGENT 
.
└─ opt
   └─ ZTools   
      ├─ etc
      │  ├─ UserParameter
      │  │  └─ ztools_userParameter.conf
      │  ├─ ztools.conf
      │  ├─ ztools.conf_last-change-by-ztools
      │  └─ ztools_sudo_include.conf
      ├─ include
      │  └─ perl
      │     └─ File
      │        └─ Fetch.pm
      ├─ library
      │  ├─ script01.sh
      │  ├─ script02.ksh
      │  ├─ script03.py
      │  ├─ script04.pl
      │  ├─ zagent.config.pl
      │  ├─ zagent.restart.sh
      │  ├─ ztools.config.pl
      │  ├─ ztools.library.run.pl
      │  └─ ztools.library.update.pl
      └─ tmp
         └─ library.md5

### ZABBIX SERVER/PROXY 
.
└─ opt
   └─ ZTools   
      ├─ generateMD5.ksh
      ├─ index.php
      ├─ library
      │  ├─ dummy.script.sh
      │  ├─ index.php
      │  ├─ md5
      │  ├─ service.discovery.bash
      │  ├─ system.info.sh
      │  └─ system.info.vbs
      └─ modules
         ├─ index.php
         └─ md5
```

# Nome das variaveis criadas no contexto de execusao do zagent:
- ZTOOLS_VERSION
- ZTOOLS_HOME
- ZTOOLS_TMP
- ZTOOLS_BIN
- ZTOOLS_SBIN
- ZTOOLS_INCLUDE
- ZTOOLS_LIBRARY
- ZTOOLS_SCRIPTS
=======
# ZTools
A Tool for Zabbix Agent