
Simulating Manifest & Chunks publishing to two different servers
----------------------------------------------------------------

Requirment:
1) Linux machine where we can run the simulation script (Machine A)
2) TWO linux machine where httpd is avialable (Machine B and C)

--- Copy the publishingSimulation.sh file to machine A.

--- In machine B and C, enable .htaccess. This can be enabled at the httpd config
         file. Look for the root directory entry in httpd config. Typically, you 
		 will find <Directory "/var/www/html">  in the config file
		 Change "AllowOverride None" to " AllowOverride All"
		 Restart httpd 

--- In Machine B and C, create a directory inside the web root directory called 'data'
    Give write permission to apache for this directory 
	("# chown apache:apache data" should do the job)

--- Update the .htacces file in the webserver's root directory in both Machien A & B
    The .htacces file should have the following entry
			[root@ip-172-31-13-135 html]# cat .htaccess
			RewriteEngine On
			Rewriterule  (.m3u8) putHandler.php
			
		You may need to add the Rewriterule for m3u8 in one machine (eg:Machine A)
		and for ts file in Machine B. ("Rewriterule  (.ts) putHandler.php")
		
--- Copy the php script (putHandler.php) to both machine B & C's webserver's root directory
--- Update the IP address of Machine A and B in publishingSimulation.sh file 
     ( which we copied to Machine A)
	 The updation can be done at the following place in the script
					TS_CHUNK_URI_DIR="http://52.221.240.161/"
					M3U8_URI_DIR="http://52.221.239.89/"
	 
--- Run the script (publishingSimulation.sh) as root from Machine A
    Manifest files and chunks will be "created" and will be send to Machine B and C
	usign http PUT.
	

How it works?
-------------

The simulator script in Machine A is "generating" Manifest files and chunk files.
The Manifest files are send to one machine and the chunks to another machine.
The files are send using Curl -T option which is essentially using "PUT".

On the target machine'w webservers have the Rewrite rules in .htaccess. So when 
a m3u8 or ts file is received, the "putHandler.php" is invoked. This php script will
simply read the stdin and write to a file in webserver directory.



