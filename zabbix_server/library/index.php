<?php
  global $FileExtByOS;
  $FileExtByOS = array(
    'Win'  => '\.(bat|exe|vbs|ps1|vba|hta)$',
    'Unix' => '\.(ksh|sh|pl|bash|py)$'
  );
  global $File2Download;
  $DownloadStatus = "NF";
  $File2Download = "None";

  if( isset( $_GET[ 'Action' ])){
    $Action = $_GET[ 'Action' ];
    if( $Action == "Download" ){
      $DownloadFile = $_GET[ 'File' ];
      $OSName = $_GET[ 'OSName' ];
      
      if( $handle = opendir( '.' )){
        while( false !== ( $entry = readdir( $handle ))){
          if( $entry != "." && $entry != ".." & ( preg_match( "/$DownloadFile/i", $entry ))){
            if( $File2Download == "None" ){
              $GLOBALS[ 'File2Download' ] = $entry;
              $GLOBALS[ 'DownloadStatus' ] = "OK";
            } else {
              $RegexExt = $FileExtByOS[ $OSName ];
              print_r( $FileExtByOS );
              if( preg_match( "/$RegexExt/i", $entry )){
                $GLOBALS['File2Download'] = $entry;
                $GLOBALS[ 'DownloadStatus' ] = "OK";
                break;
              } else {
                if( preg_match( "/$RegexExt/i", $GLOBALS['File2Download'])){
                  break;
                } else {
                  $GLOBALS['File2Download'] = "None";
                  $GLOBALS[ 'DownloadStatus' ] = "NF";
                }
              }
            }
          }
        }
        closedir( $handle );
      }
      
      if( $DownloadStatus == "OK" ){
        $URL = (isset($_SERVER['HTTPS']) ? "https" : "http") . "://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]";
        $A = pathinfo($URL);
        $B = pathinfo(parse_url($URL)['path']);
        $FileMD5 = explode("  ", exec("md5sum $File2Download"));
        echo "$DownloadStatus;".$FileMD5[0].";".$A['dirname'].$B['dirname'].$File2Download;
      } else {
        echo "$DownloadStatus;;";
      }
      
      
      ### if( $File2Download != 'NotFound' ){
      ###   header( 'Expires: 0' );
      ###   header( 'Pragma: no-cache' );
      ###   header( 'Cache-Control: must-revalidate' );
      ###   header( 'Last-Modified: '.gmdate( 'D, d M Y H:i:s', filemtime( $File2Download )).' GMT' );
      ### 
      ###   header( "Content-type: application/octet-stream" );
      ###   header( "Content-Disposition: attachment; filename=\"$File2Download\"" );
      ###   readfile( $File2Download );     
      ### } else {
      ###   echo "$File2Download";
      ### }
    }
  } else {
    # Caso o parametro enviado nao seja nenhum dos esperados, redireciona
    # para o ROOT do site:
    header( 'Location:/' );
  }
?>