<?php
/**
    PHP script to dump the input stream to a file
    sudheer@dexiva.com  - 06 June 2016
    
    The files are dumped to a directory mentioned in the $dir varible.
    The directory need to be  created first and write permission need to be
    given to apache - '#chown apache:apache data' should do the job
*/

// Logging the information to apache error log
error_log("Request Method: " . $_SERVER['REQUEST_METHOD']);
error_log("URI from the request" . $_SERVER['REQUEST_URI']);


/* PUT data comes in on the stdin stream */
$putdata = fopen("php://input", "r");

$dir = 'data';

if ( !file_exists($dir)){
    error_log("Directory". $dir . "not exists, create it & give the \
        write access to apache");
    fclose($putdata);
    exit(1);
}

// Our taget file is the name of the file in PUT request.
$myFile = $dir . $_SERVER['REQUEST_URI'];

$fp = fopen($myFile, "w");

// We are reading 1024 Bytes and write to the file
while ($data = fread($putdata, 1024))
  fwrite($fp, $data);

// Do a proper exit
fclose($fp);
fclose($putdata);
exit(0);
?>
