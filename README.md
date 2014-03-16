README.captcha

Dead simple plugin-less  library-less framework-less filter for online content.

You have something you want to make available but discourage abuse 
so you use a reCaptcha, which is just generating a form and evaulating the 
response to determine whether or not to display the content. 
Google offers this as a service and uses the work done to digitise books
and street view images.  

To use put the (possibly edited) template files in the web directory 
you are using (probably along side the content page you are protecting)

Put the captcha.cgi where it can be executed by your webserver 
probably under cgi-bin. 

Edit captcha.cgi,  at minimum you need to 
	add your recaptcha keys for_the_domain_the_script_is_running_at 
	they are provided by Google at:
	https://www.google.com/recaptcha/admin/create 
	
	Add the name of the content to serve when a recaptcha is solved
	and possibly correct paths if you are moving things around. 
	
