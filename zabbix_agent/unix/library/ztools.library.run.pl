#!/bin/env perl
#===============================================================================
#         FILE: ztools.library.run
#        USAGE: ./ztools.library.run
#  DETARGET_SCRIPTION: 
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

  #-----------------------------------------------------------------------------
  # Adiciona o diretorio de include de modulos do perl existente no ztools:
  BEGIN { push @INC, $ENV{ ZTOOLS_INCLUDE }}
  
  use strict;             # Garante que nao sera usada praticas inseguras ou nao
                          # aconselhadas de programacao.
  use POSIX qw(strftime); # Format date and timeerl
  use IO::Socket::INET;   #
  use File::Copy;         # 

# Para mais informacoes pesquise em http://search.cpan.org utilizando o nome
# especifico de cada modulo.
#===============================================================================

  my $Version = '20160218.1157'; # Versao do arquivo.

#===============================================================================
# Configuracoes globais:

  #-----------------------------------------------------------------------------
  # Definicao das variaveis de ambiete:
  my $BASEDIR="/opt/ZTools";
  $ENV{ 'ZTOOLS_HOME' } = "${BASEDIR}";
  $ENV{ 'ZTOOLS_ETC' } = "${BASEDIR}/etc";
  $ENV{ 'ZTOOLS_TMP' } = "${BASEDIR}/tmp";
  $ENV{ 'ZTOOLS_INCLUDE' } = "${BASEDIR}/include";
  $ENV{ 'ZTOOLS_LIBRARY' } = "${BASEDIR}/library";
  
  #-----------------------------------------------------------------------------
  # Nome do script que sera executado.
  my $TARGET_SCRIPT;
  if( scalar( @ARGV ) > 0 ){
    $TARGET_SCRIPT = shift( @ARGV );
  } else {
    print "ZBX_NOTSUPPORTED: Voce precisa especificar um script para ser executado.\n";
    exit( 4 );
  }
    
  #-----------------------------------------------------------------------------
  # Lista de arquivos de configuracao que seram carregados:
  my @ConfigFiles = (
    $ENV{ 'ZTOOLS_ETC' }."/ztools.conf"
  );

  #-----------------------------------------------------------------------------
  # Encontra o arquivo de configuracao do zabbix
  my $CMD = "ps -eo cmd|grep zabbix|grep '\\-c'|grep -v grep;ps -eo cmd|grep zabbix|grep '\\-\\-config'|grep -v grep";
  if( open( CMDExec, "$CMD|" )){
    while( <CMDExec> ){
      if(( $_ =~ m/zabbix_agent/ ) && ( $_ =~ m/conf/ )){
        my $ZBXConfig = &CleanUpData(( split( / /, $_ ))[ -1 ]);
        push( @ConfigFiles, $ZBXConfig ) if( -e "$ZBXConfig" );
      }
    }
    close( CMDExec );
  }

  #-----------------------------------------------------------------------------
  # Hash para receber as configuracoes do arquivo de conf do ztools.
  my $Conf = &ReadConfigFile( );

  #-----------------------------------------------------------------------------
  # Lista de binarios utilizados pelo script:
  my %BINTools = (
    'WGET', &CleanUpData( `which wget 2>/dev/null` ),
    'CURL', &CleanUpData( `which curl 2>/dev/null` ),
    'BASH', &CleanUpData( `which bash 2>/dev/null` ),
     'PHP', &CleanUpData( `which php 2>/dev/null` ), 
     'KSH', &CleanUpData( `which ksh 2>/dev/null` ),
      'PL', &CleanUpData( `which perl 2>/dev/null` ),
      'PY', &CleanUpData( `which python 2>/dev/null` ),
      'SH', &CleanUpData( `which sh 2>/dev/null` ),
  );

  #-----------------------------------------------------------------------------
  my @UpdateListOK; # Vai receber a lista de arquivos atualizados.
  my @UpdateListER; # Vai receber a lista de arquivos que nao foram atualizados.
  my %MD5Remote;    # Vai receber a lista de MD5 dos scripts no repositorio remoto.
  my %MD5Local;     # Vai receber a lista de MD5 dos scripts locais.

  #-----------------------------------------------------------------------------
  # Key para envio do status de atualizacao dos scripts:
  my $UpdateStatusKEY = "ztools.runscripts[updateEnvironment]";

  #-----------------------------------------------------------------------------
  # Lista de Caminhos:
  my $PATH_TMP = $ENV{ 'ZTOOLS_TMP' };
  my $PATH_LIBRARY = $ENV{ 'ZTOOLS_LIBRARY' };

  #-----------------------------------------------------------------------------
  # Path e nome do arquivo de controle para update dos script do ztools:
  my $UPDATE_CTRL_FILE = "$PATH_TMP/.update_time.ctrl";

  #-----------------------------------------------------------------------------
  # URL base para o repositorio do ztools:
  my $REPO_BASEURL = $Conf->{ 'ztools' }->{ 'protourl' }."://".$Conf->{ 'ztools' }->{ 'reposerver' }.":".$Conf->{ 'ztools' }->{ 'updateport' };

  #-----------------------------------------------------------------------------
  # Tempo de espera para resposta de conexao com o repositorio:
  my $REPO_COMM_TOUT = $Conf->{ 'ztools' }->{ 'timeout' };

#===============================================================================
# Funcao principal do script.
MAIN: {

  #-----------------------------------------------------------------------------
  # Verifica a data de modificacao do arquivo de controle:
  my $UPDATE_TIME = 0;
  if( -e $UPDATE_CTRL_FILE ){
    $UPDATE_TIME = ( time( ) - ( stat( "$UPDATE_CTRL_FILE" ))[ 9 ]);
  } else {
    $UPDATE_TIME = ( $Conf->{ 'ztools' }->{ 'updatethr' } + 1 );
  }

  #-----------------------------------------------------------------------------
  # Identifica sera sera executada a rotina de update dos scripts do ztools:
  if(( $TARGET_SCRIPT =~ m/^UPDATE_ENVIRONMENT$/ ) || ( $UPDATE_TIME > $Conf->{ 'ztools' }->{ 'updatethr' })){
    #---------------------------------------------------------------------------
    # Atualiza a data da ultima atualizacao dos scripts:
    if( open( FH_CTRL, ">$UPDATE_CTRL_FILE" )){
      printf FH_CTRL localtime( time ( ));
      close( FH_CTRL );
    }

    #---------------------------------------------------------------------------
    #               EXECUTA A ATUALIZACAO DOS SCRIPTS DA LIBRARY               #
    &UpdateScripts( $Conf->{ 'ztools' }->{ 'urilibrary' }, $ENV{ 'ZTOOLS_LIBRARY' });

    #---------------------------------------------------------------------------
    #          EXECUTA A ATUALIZACAO DO ARQUIVO USERPARAMETER_SCRIPTS          #
    &UpdateScripts( $Conf->{ 'ztools' }->{ 'uriuserparameter' }, $ENV{ 'ZTOOLS_ETC' }.'/UserParameter' );

    #---------------------------------------------------------------------------
    # Verifica se foi atualizado algum arquivo:
    if( scalar( @UpdateListOK ) > 0 ){
      &ZabbixSendEvent( $UpdateStatusKEY, "OK: @UpdateListOK" );

    #---------------------------------------------------------------------------
    # Verifica se houve falha na atualizado algum arquivo:
    } elsif( scalar( @UpdateListER ) > 0 ){
      &ZabbixSendEvent( $UpdateStatusKEY, "ER: @UpdateListER" );
    }

    #---------------------------------------------------------------------------
    # Destrui as variaveis que nao serao mais usadas:
    undef( @UpdateListOK ); undef( @UpdateListER ); undef( $UPDATE_TIME );

    #---------------------------------------------------------------------------
    # Finaliza o script se foi solicitado expressamente a execusao do update:
    exit( 0 ) if( $TARGET_SCRIPT =~ m/^UPDATE_ENVIRONMENT$/ );
  }

  #-----------------------------------------------------------------------------
  # Verifica se o script solicitado realmente existe e o executa:
  #-----------------------------------------------------------------------------
  if( opendir( DH_Library, $PATH_LIBRARY )){
    my @AllFiles = readdir( DH_Library );
    closedir ( DH_Library );
    foreach( @AllFiles ){
      if( $_ =~ m/$TARGET_SCRIPT/ ){
        $TARGET_SCRIPT = $_;
      }
    }
  }

  if( -f "$PATH_LIBRARY/${TARGET_SCRIPT}" ){
    
    #---------------------------------------------------------------------------
    # Executa e exibe o retorno do script executado:
    print &RunScript( $PATH_LIBRARY, $TARGET_SCRIPT );
  
  } else {
    my( $RC, $ErMsg ) = &DownloadMissinScript( $TARGET_SCRIPT, $PATH_LIBRARY, "$REPO_BASEURL/library" );
    if( $RC == 1 ){
      #-------------------------------------------------------------------------
      # Quando o processo de download do arquivo eh executado com sucesso, em vez
      # de mandar uma mensagem de erro como 2 paramentro, eh enviado o nome real
      # do script para ser usado na execusao do mesmo:
      $TARGET_SCRIPT = $ErMsg;
      
      #-------------------------------------------------------------------------
      # Executa e exibe o retorno do script executado:
      print &RunScript( $PATH_LIBRARY, $TARGET_SCRIPT );

    } else {
      print "ZBX_NOTSUPPORTED: $ErMsg;";
      exit( 2 );
    }
  }
}

#===============================================================================
# Executa o script com os parametros enviados:
sub RunScript( ){
  my( $Library, $Script ) = @_;
 
  #---------------------------------------------------------------------------
  # Verifica qual o interpretador/binario correto para executar o script com
  # base na extensao do arquivos:
  my $Bin2ExecExt;
  if( $Script =~ m/\./ ){
    my $ScriptExt = uc(( split( /\./, $Script ))[ -1 ]);
    if( defined( $BINTools{ $ScriptExt })){
      $Bin2ExecExt = $BINTools{ $ScriptExt };
    }
    undef( $ScriptExt );
  }

  #-----------------------------------------------------------------------------
  # Verifica qual o interpretador/binario correto para executar o script com
  # base na primeira linha do script marcada com "#!", destinada para esse uso.
  my $Bin2ExecScript;
  if( open( FH_Script, "<${Library}/${Script}" )){
    while( <FH_Script> ){
      $_ = &CleanUpData( $_ );
      if( $_ =~ m/^#\!/ ){
        $_ =~ s/#\!//g;
        $Bin2ExecScript = $_ if( -e $_ );
        last( );
      }
    }
  }

  #-----------------------------------------------------------------------------
  # Verifica qual informacao esta diponivel para eleger qual sera utilizada:
  my $BIN;
  if( defined( $Bin2ExecScript )){
    $BIN = $Bin2ExecScript;
  } elsif( defined( $Bin2ExecExt )){
    $BIN = $Bin2ExecExt;
  }
  undef( $Bin2ExecExt ); undef( $Bin2ExecScript );

  if( defined( $BIN )){
    #-----------------------------------------------------------------------------
    # Monta a linha de comando que sera usada para executar o script solicitado
    # com todos os seus paramentros, sendo que cada um deles sera envolto por (").
    my @CMD2Exec = ( "${Library}/${Script}" );
    foreach my $Parm ( @ARGV ){
      if( $Parm !~ m/^$/ ){
        push( @CMD2Exec, "\"$Parm\"" );
      }
    }
    undef( $Library ); undef( $Script );
    
    #-----------------------------------------------------------------------------
    # Executa a linha de comando montada anteriormente e captura o seu retorno para
    # exibir ao termino do script:
    my @OUTPUT;
    if( open( FH_CMD2Exec, "$BIN @{CMD2Exec}|" )){
      while ( <FH_CMD2Exec> ){
        push( @OUTPUT, $_ );
      }
      close ( FH_CMD2Exec );
    } else {
      print "ZBX_NOTSUPPORTED: Falha ao executar [$Script]\n";
    }
    undef( $BIN ); undef( @CMD2Exec); undef( );
    return( @OUTPUT )
  } else {
    print "ZBX_NOTSUPPORTED: Nao foi possivel identificar o interpletador (binario) para executar o script.\n";
    exit( 4 );
  }  
}

#===============================================================================
# Tenta fazer download o script que nao foi encontrado na library
sub DownloadMissinScript {
  my( $TargetFile, $Path, $LibraryURI ) = @_;
  my( $RC, $MSG ) = &CheckPORT( $Conf->{ 'ztools' }->{ 'reposerver' }, $Conf->{ 'ztools' }->{ 'updateport' }, $REPO_COMM_TOUT );
   
  if( $RC == 1 ){
    #-----------------------------------------------------------------------------
    my $URL = $LibraryURI."/?Action=Download&File=${TargetFile}&OSName=Unix";
    
    #-----------------------------------------------------------------------------
    my $Status;
    my $DownloadURL;
    my $FileRemoteMD5;
    my $FileLocalMD5;
    my $RealScriptName;
    # Download utilizando o wget:
    if ( $BINTools{ 'WGET' } !~ m/^$/ ){ # Verifica se o OS eh windows

      #---------------------------------------------------------------------------
      # Efetua o download o arquivo:
      if( open( CMD_Handle, $BINTools{ 'WGET' }." --no-check-certificate -qO- \'$URL\' 2>&1|" )){
        while( <CMD_Handle> ){
          ( $Status, $FileRemoteMD5, $DownloadURL ) = split( /;/, &CleanUpData( $_ ));
          $RealScriptName = ( split( /\//, $DownloadURL ))[ -1 ];
        }
        close( CMD_Handle );
      }
      if( "$Status" eq 'OK' ){
        system( $BINTools{ 'WGET' }." --no-check-certificate --directory-prefix=\"$Path\" \'$DownloadURL\' 1>/dev/null 2>&1\n" );
        
        if( -f "$Path/$RealScriptName" ){
          if(( stat( "$Path/$RealScriptName" ))[ 7 ] > 0 ){
            #-------------------------------------------------------------------------
            # Verifica a integridade do arquivo transferido:
            if( $^O =~ m/AIX/i ){
              $FileLocalMD5 = &CleanUpData( `csum "$Path/$RealScriptName" |awk '{print \$1}'` );
            } elsif( $^O =~ m/SOLARIS/i ){
              $FileLocalMD5 = &CleanUpData( `digest -a md5 -v "$Path/$RealScriptName" |awk '{print \$NF}'` );
            } else {
              $FileLocalMD5 = &CleanUpData( `md5sum "$Path/$RealScriptName" |awk '{print \$1}'` );
            }
          } else {
            unlink( "$Path/$RealScriptName" );
          }
        } else {
          return( 0, "Falha no download do arquivo." );
        }
      } else {
        return( 0, "O arquivo \"$TargetFile\" nao foi encontrado no repositorio do ZTools." );
      }
    
    # Download utilizando o cURL
    } elsif( $BINTools{ 'CURL' } !~ m/^$/ ){ # Verifica se o OS eh windows

      #---------------------------------------------------------------------------
      # Efetua o download o arquivo:
      if( open( CMD_Handle, $BINTools{ 'CURL' }." --insecure -s \'$URL\' 2>&1|" )){
        while( <CMD_Handle> ){
          ( $Status, $FileRemoteMD5, $DownloadURL ) = split( /;/, &CleanUpData( $_ ));
          $RealScriptName = ( split( /\//, $DownloadURL ))[ -1 ];
        }
        close( CMD_Handle );
      }
      if( "$Status" eq 'OK' ){
        system( $BINTools{ 'CURL' }." --insecure -o \"$Path/$RealScriptName\" \'$URL\' 1>/dev/null 2>&1" );
        
        #-------------------------------------------------------------------------
        # Verifica a integridade do arquivo transferido:
        if( -f "$Path/$RealScriptName" ){
          if(( stat( "$Path/$TargetFile" ))[ 7 ] > 0 ){
            if( $^O =~ m/AIX/i ){
              $FileLocalMD5 = &CleanUpData( `csum "$Path/$RealScriptName" |awk '{print \$1}'` );
            } elsif( $^O =~ m/SOLARIS/i ){
              $FileLocalMD5 = &CleanUpData( `digest -a md5 -v "$Path/$RealScriptName" |awk '{print \$NF}'` );
            } else {
              $FileLocalMD5 = &CleanUpData( `md5sum "$Path/$RealScriptName" |awk '{print \$1}'` );
            }
          } else {
            unlink( "$Path/$RealScriptName" );
          }
        } else {
          return( 0, "Falha no download do arquivo." );
        }
      } else {
        return( 0, "O arquivo \"$TargetFile\" nao foi encontrado no repositorio do ZTools." );
      }
    } 
    
    if( "$FileRemoteMD5" eq "$FileLocalMD5" ){
      system( "chmod +x \"$Path/$RealScriptName\"" );
      return( 1, $RealScriptName );
    } else {
      unlink( "$Path/$RealScriptName" );
      return( 0, "Nao foi possivel garantir a integridade do script" );
    }
  } else {
    return( 0, $MSG );
  }
}

#===============================================================================
# Gera uma lista com o MD5 de todos os scripts locais:
sub GenerateMD5Local {
  my( $PATH ) = @_;
  my @AllFiles;
  my %MD5List;

  #-----------------------------------------------------------------------------
  # Carrega a lista de arquivos na queue para processamento:
  if( opendir( DH_DIR, $PATH )){
    @AllFiles = map{ "${PATH}/${_}" } # Terceiro: Adiciona o caminho completo
      grep { -f "${PATH}/${_}" }      # Segundo.: Pega somente os arquivos
      readdir DH_DIR;                 # Primeiro: consulta o conteudo do diretorio.
    closedir( DH_DIR );               # Fecha o diretorio aberto para consulta.
  }

  #-----------------------------------------------------------------------------
  # Gera o MD5 para cada um dos arquivos da library de scripts:
  foreach my $File ( @AllFiles ){
    my $HASH_MD5;
    if( $^O =~ m/AIX/i ){
      $HASH_MD5 = &CleanUpData( `csum "${File}" |awk '{print \$1}'` );
    } elsif( $^O =~ m/SOLARIS/i ){
      $HASH_MD5 = &CleanUpData( `digest -a md5 -v "${File}" |awk '{print \$NF}'` );
    } else {
      $HASH_MD5 = &CleanUpData( `md5sum "${File}" |awk '{print \$1}'` );
    }

    my( $FName ) = ( split( /\//, $File ))[ -1 ];
    $MD5List{ $FName } = $HASH_MD5;
    undef( $FName ); undef( $HASH_MD5 );
  }

  #-----------------------------------------------------------------------------
  # Retorna a Lista de arquivos x md5
  if( scalar( keys( %MD5List )) > 0 ){
    return( %MD5List );
  } else {
    return( undef( ));
  }
}

#===============================================================================
# Efetua o download do arquivo contento o MD5 e retorna uma hash com esse conteudo
sub GenerateMD5Remote {
  my( $URI ) = @_;
  my $CMD2Download;
  my %MD5List;

  #-----------------------------------------------------------------------------
  # URL para download da lista de MD5 dos scripts remotos:
  my $RemoteMD5URL = $Conf->{ 'ztools' }->{ 'protourl' }."://".$Conf->{ 'ztools' }->{ 'reposerver' }.":".$Conf->{ 'ztools' }->{ 'updateport' }."/".$Conf->{ 'ztools' }->{ 'urilibrary' }."/md5";
  #-----------------------------------------------------------------------------
  # Caminho para o local que a lista remota de MD5 sera gravada:
  my $MD5TFile = "${PATH_TMP}/library.md5";
  unlink( "$MD5TFile" );

  #-----------------------------------------------------------------------------
  # Monta o comando que sera usado para fazer o download do arquivo:
  if ( $BINTools{ 'WGET' } !~ m/^$/ ){
    $CMD2Download = $BINTools{ 'WGET' }." --no-check-certificate --output-document=\"$MD5TFile\" \'$RemoteMD5URL\' 1>/dev/null 2>&1";
  } elsif( $BINTools{ 'CURL' } !~ m/^$/ ){
    $CMD2Download = $BINTools{ 'CURL' }." --insecure -o \"$MD5TFile\" \'$RemoteMD5URL\' 1>/dev/null 2>&1";
  }
  undef( $RemoteMD5URL );

  #-----------------------------------------------------------------------------
  # Efetua o download do arquivo MD5 e converte em hash:
  system( $CMD2Download );
  if( open( FH_MD5, "<$MD5TFile" )){
    while( <FH_MD5> ){
      my( $HASH, $FName ) = split( / /, &CleanUpData( $_ ));
      $MD5List{ $FName } = $HASH;
      undef( $HASH ); undef( $FName );
    }
    close( FH_MD5 );
    return( %MD5List );
  }
  return( undef( ));
}

#===============================================================================
# Limpa o dado enviado, removendo os espacos no inicio e final, quebla de linha,
# tabulacao e curso.
sub CleanUpData {
  my ( $DATA ) = @_;
  $DATA =~ s/[\r\n\t]//g;  # Remove quebra de linha, Return Carrier e tab.
  $DATA =~ s/\s{2,}/ /g;   # Substitui 2 espacor por 1 espaco.
  $DATA =~ s/^\s+|\s+$//g; # Remove todos os espacos do inicio/final.
  return( $DATA );
}

#===============================================================================
# Atualiza os scripts locais do ztools:
sub UpdateScripts {
  my( $URI, $PATH ) = @_;

  #-----------------------------------------------------------------------------
  # lista de MD5:
  ( %MD5Remote ) = GenerateMD5Remote( $URI );
  ( %MD5Local ) = GenerateMD5Local( $PATH );

  #-----------------------------------------------------------------------------
  # Inicia a validacao dos scripts:
  foreach my $LocalFile ( keys ( %MD5Local )){
    #---------------------------------------------------------------------------
    # Verifica se o arquivo existe na lista remota de MD5:
    if( defined( $MD5Remote{ $LocalFile })){
      #-------------------------------------------------------------------------
      # Verifica se o MD5 do arquivo remoto eh igual ao local:
      if( $MD5Remote{ $LocalFile } !~ m/$MD5Local{ $LocalFile }/ ){
        my( $RC, $ErMsg ) = &DownloadMissinScript( $LocalFile, $PATH_TMP, $URI );
        if( $RC == 1 ){
          unlink( "$PATH/$LocalFile" );
          move( "$PATH_TMP/$LocalFile", "$PATH/$LocalFile" );
          push( @UpdateListOK, $LocalFile );
        } else {
          push( @UpdateListER, $LocalFile );
        }
      }
    }
  }
}

#===============================================================================
# Envia metricas coletadas utilziando o zabbix sender:
sub ZabbixSendEvent {
  my ( $ZBXKey, $Value ) = @_;

  #-----------------------------------------------------------------------------
  # Carrega a servidor ativo do zabbix para enviar os dados coletados:
  my( @ActiveServer ) = split( /\,/, $Conf->{ 'zabbix_agentd' }->{ 'serveractive' });

  #-----------------------------------------------------------------------------
  # Identifica se o zabbix_sender esta disponivel para utilizacao:
  my $ZBXSender = "";
  if( defined( $ENV{ 'ZTOOLS_BIN' } )){
    if( -e $ENV{ 'ZTOOLS_BIN' }."/zsender" ){
      $ZBXSender = $ENV{ 'ZTOOLS_BIN' }."/zsender";
    } elsif( -e $ENV{ 'ZTOOLS_BIN' }."/zabbix_sender" ){
      $ZBXSender = $ENV{ 'ZTOOLS_BIN' }."/zabbix_sender";
    }
  } 
  if( ! -e "${ZBXSender}" ){
    return( 1 );
  }

  #-----------------------------------------------------------------------------
  # Envia o evento para todos os servidores identificado como "ServerActive".
  foreach my $ZBXServer ( @ActiveServer ){
    my $CMD2Exec = "\'$ZBXSender\' --zabbix-server $ZBXServer --host ".$Conf->{ 'zabbix_agentd' }->{ 'hostname' }." --key \'$ZBXKey\' --value \'$Value\'";
    system( "$CMD2Exec 1>/dev/null 2>&1" );
    undef( $ZBXServer );
  }
}

#===============================================================================
# Carrega as configuracoes de um arquivo INI:
sub ReadConfigFile( ){

  #-----------------------------------------------------------------------------
  # Hash para o retorno dos paramentros carregados do arquivo INI:
  my $Config = { };
  # Carrega o arquivo INI e separa os parametros dentro da hash:
  #-----------------------------------------------------------------------------
  foreach my $ConfFile ( @ConfigFiles ){
    my $ConfName = ( split( /\./, ( split( /\//, $ConfFile ))[ -1 ]))[ 0 ];
    if( open( FH_Conf, "<$ConfFile" )){
      while( <FH_Conf> ){
        if( "$_" !~ m/^#/ ){
          if( "$_" =~ m/\=/ ){
            my( $PARM, $VALUE ) = split( /\=/, &CleanUpData( $_ ));
            $Config->{ $ConfName }->{ lc( $PARM )} = $VALUE;
          }
        }
      }
      close( FH_Conf );
      #-------------------------------------------------------------------------
      # Envia de volta a HASH com os paramentros carregados:
    } else {
      print "ZBX_NOTSUPPORTED: Erro ao carregar o arquivo de configuracao \"$ConfFile\".\n";
      exit( 1 );
    }
    undef( $ConfName );
  }
  if( scalar( keys ( %{ $Config })) > 0 ){
    return( $Config );   
  } else {
  return( undef );
  }
}

#===============================================================================
# Verifica se o host responde pacotes ICMP.
sub CheckPORT {
  my( $Host, $Port, $TOut ) = @_;
  my $Status = 0;

  #---------------------------------------------------------------------------
  # creating object interface of IO::Socket::INET modules which internally creates
  # socket, binds and connects to the TCP server running on the specific port.
  my $SocketOBJ = new IO::Socket::INET (
    Timeout  => $TOut,
    PeerHost => $Host,
    PeerPort => $Port,
    Proto    => 'tcp',
  );

  #---------------------------------------------------------------------------
  # Verifica o resultado do teste executado:
  if( defined( $SocketOBJ )){
    $SocketOBJ->close( );
    undef( $SocketOBJ );
    return( 1, undef( ));
  }

  undef( $SocketOBJ );
  return( $Status, "Sem conectividade com a porta TCP:$Port" );
}