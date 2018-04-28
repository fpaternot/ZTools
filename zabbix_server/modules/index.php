<?php
  if( isset( $_GET[ 'action' ])){
    $Action = $_GET[ 'action' ];
    $DirPath = "/opt/mrepo/www";
    if( $Action == "download" ){
      $DownloadFile = $_GET[ 'file' ];
      $DownloadPath = "files/PerlForWindows";

      header( "Content-Description: Text File" );
      header( 'Expires: 0' );
      header( 'Pragma: no-cache' );
      header( 'Cache-Control: must-revalidate' );
      header( 'Last-Modified: '.gmdate( 'D, d M Y H:i:s', filemtime( $DirPath."/".$File )).' GMT' );
      header( 'Content-Length: '.filesize( $DirPath."/".$File )); // provide file size
      header( 'Connection: close');
      
      if( preg_match( "/\.(exe)$/i", $File )) {
        header( "Content-Type: application/octet-stream" );
        header( 'Location:/'.$DirPath."/".$File );
      } else {
        header( "Content-Type: text/plain" );
        $handle = @fopen( $DefaultPath."/".$File, "r" );
        if( $handle ){
          while(( $buffer = fgets( $handle, 4096 )) !== false ){
            echo $buffer;
          }
          if( !feof( $handle )){
            exit( "Error: unexpected fgets( ) fail" );
          }
          fclose( $handle );
        } else{
          exit( "Error: open the file" );
        }
        exit( 0 );
      }
    }
  } else {
    # Caso o parametro enviado nao seja nenhum dos esperados, redireciona
    # para o ROOT do site forcando a cair na opcao padrao, que exibe a lista
    # de pacotes disponiveis para download e configuracao do repo linux:
    header( 'Location:/' );
  }
?>