#!/bin/env perl
#===============================================================================
#         FILE: zagent.config
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
#      CREATED:  25/04/2018 18:54:01 BRST
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
  use Data::Dumper; 

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
  # Encontra o arquivo de configuracao do zabbix
  my $ZBXConfig;
  my $CMD = "ps -eo cmd|grep zabbix|grep '\\-c'|grep -v grep;ps -eo cmd|grep zabbix|grep '\\-\\-config'|grep -v grep";
  if( open( CMDExec, "$CMD|" )){
    while( <CMDExec> ){
      if(( $_ =~ m/zabbix_agent/ ) && ( $_ =~ m/conf/ )){
        $ZBXConfig = &CleanUpData(( split( / /, $_ ))[ -1 ]);
      }
    }
    close( CMDExec );
  }

  #-----------------------------------------------------------------------------
  #
  my @OriginalINI;
  my $IndexCTRL = int( rand(1000));

  #-----------------------------------------------------------------------------
  #
  my $Action = uc( $ARGV[ 0 ]);
  my $KeyName = $ARGV[ 1 ];
  my $KeyValue = $ARGV[ 2 ] || 'undef';

#===============================================================================
# Funcao principal do script.
MAIN: {

  my $zagentConf = LoadINI( $ZBXConfig );
  
  if( "$Action" eq "SET" ){
    if( $zagentConf->{ $KeyName }->{ 'value' } != $KeyValue ){
      $zagentConf->{ $KeyName }->{ 'value' } = $KeyValue;
      $zagentConf->{ $KeyName }->{ 'change' } = 1;
      $zagentConf->{ $KeyName }->{ 'status' } = 1;
      &UpdateINI( $ZBXConfig, $zagentConf );
      print "1\n";
    } else {
      print "0\n";
    }

    
  } elsif( "$Action" eq "GET" ){
    if( $KeyName =~ m/all/i ){
      foreach my $KeyValue ( sort( keys( %{ $zagentConf }))){
        print "$KeyValue=".$zagentConf->{ $KeyValue }->{ 'value' }."\n";
      }
    } else {
      if( defined( $zagentConf->{ $KeyName }->{ 'value' })){
        print "$KeyName=".$zagentConf->{ $KeyName }->{ 'value' }."\n";
      } else {
        print "ZBX_NOTSUPPORTED: Parametro de configuracao [$KeyName] nao encontrado.\n";
      }
    }
    
  }

}

#===============================================================================
#
sub LoadINI { 
  my $ini = $_[ 0 ];
  my $conf;
  open( INI, "$ini" ) || die "Can't open $ini: $!\n";
  my $section = '_';
    while (<INI>) {
      ### print ">>> $_";
      $_ =~ s/[\n]//;
      if( $_ !~ m/^#\t/ ){
        chomp;
        
        if( /^\s*([^=]+?)=(.*?)$/g ){
          my $Key = &CleanUpData( $1 );
          my $Value = &CleanUpData(( split( /#/, $2 ))[ 0 ]);
          my $KeyStatus = 1;
          $KeyStatus = 0 if( $Key =~ m/^#/ );
          $Key =~ s/^#//;
          $conf->{ &CleanUpData( $Key )}->{ status } = $KeyStatus;
          $conf->{ &CleanUpData( $Key )}->{ change } = 0;
          $conf->{ &CleanUpData( $Key )}->{ index } = $IndexCTRL;
          $conf->{ &CleanUpData( $Key )}->{ value } = $Value;
          push( @OriginalINI, ">>>$IndexCTRL<<<\n" );
          undef( $KeyStatus );
          $IndexCTRL++;
        } else {
          push( @OriginalINI, $_ );
        }
      } else {
        push( @OriginalINI, $_ );
      }
    }
  close( INI );
  return $conf;
}

#===============================================================================
# 
sub UpdateINI {
  my $ini = $_[ 0 ];
  my $conf = $_[ 1 ];
  my $contents = '';
  my $UpdateINI = 0;

  foreach my $KeyValue ( keys( %{ $conf })){
    my $Index = $conf->{ $KeyValue }->{ 'index' };
    my $Value = $conf->{ $KeyValue }->{ 'value' };
    $UpdateINI = 1 if( $conf->{ $KeyValue }->{ 'change' } == 1 );
    
    my $KeyStatus = $conf->{ $KeyValue }->{ 'status' };
    ### print "$KeyValue\=$Value\n";
    if( $KeyStatus == 0 ){
      @OriginalINI = map { $_ =~ s/>>>$Index<<</# $KeyValue\=$Value/g; $_ } @OriginalINI;
    } else {
      @OriginalINI = map { $_ =~ s/>>>$Index<<</$KeyValue\=$Value/g; $_ } @OriginalINI;
    }
  }

  if( $UpdateINI == 1 ){
    unlink( "${ini}_last-change-by-ztools" ) if( -e "${ini}_last-change-by-ztools" );
    if( system( "cp -p $ini ${ini}_last-change-by-ztools" ) == 0 ){
      if( open( CONF, ">$ini" )){
        foreach ( @OriginalINI ){
          if( $_ !~ m/^>>>/ ){
            $_ =~ s/[\r\n]//g;  # Remove quebra de linha, Return Carrier e tab.
            $_ =~ s/\s{2,}/ /g;   # Substitui 2 espacor por 1 espaco.
            $_ =~ s/^\s+|\s+$//g; # Remove todos os espacos do inicio/final.
            print CONF "$_\n";
          }
        }
        close CONF;
      } else {
        print "ZBX_NOTSUPPORTED: Falha ao alterar o arquivo [$ini]\n";
      }
    }
  }
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