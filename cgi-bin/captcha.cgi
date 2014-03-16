#!/usr/bin/env bash

# implement a bare bones recaptcha
#	o present challenge page on GET
#	o proof results on POST 
#		- proof positive pass
#		- proof negative repeat w/new challenge	

# These are the keys 
#	*For the domain the script is running at* 
# they provided by Google at:
#	https://www.google.com/recaptcha/admin/create
# yours *will* be different
#
# note we do not actually touch user input at all.


PUBLIC_KEY="XXXXXXXXXXXXXyyyyyyyyyyyyyyyyyyyyyyyyyyy"
PRIVATE_KEY="XXXXXXXXXXXXXzzzzzzzzzzzzzzzzzzzzzzzzzz"

# what to serve if captcha is verified
SUCCESS="${CONTEXT_DOCUMENT_ROOT}/recaptcha_verified.tmplt"

#what to serve if the captcha has not been verified
FAIL="${CONTEXT_DOCUMENT_ROOT}/recaptcha_challenge.tmplt"

# name of the content you are serving to the not-bots
CONTENT=whatever.typ # EDIT ME 

echo Content-type: text/html
echo -e "\r"

if  [ ${REQUEST_METHOD} == 'POST' ] ; then
	#	ahh google ... 
	#	produce different param names in "google.com/recaptcha/api/challenge" 
	#	than are consumed in "google.com/recaptcha/api/verify"
	#	
	#	so instead of simply passing them on
	#	we get to fix the field names first
	#   ... I'm sure it is brilliant choice from some point of view
	

	VERIFY_ME="$(sed 's/recaptcha_//g;s/_field//g')&remoteip=${REMOTE_ADDR}&privatekey=${PRIVATE_KEY}"		
	RESULT=`curl -s --data "${VERIFY_ME}"  https://www.google.com/recaptcha/api/verify`
		
	if [ ${RESULT%%?success} == "true" ] ; then		
		# avoid leaking the actual content filename
		HASH="tmp`date | md5sum`"     # mktmp or uuid might be cleaner if available 
		ALIAS="${HASH%%  -*}.${CONTENT##*\.}"  # give the alias the same suffix as the content      		
		ln -s ${CONTEXT_DOCUMENT_ROOT}/${CONTENT} ${CONTEXT_DOCUMENT_ROOT}/${ALIAS}
	
		. "${SUCCESS}"
		
		# unlinking the alias on exit with trap is proving to be too soon
		#trap 'unlink ${CONTEXT_DOCUMENT_ROOT}/${ALIAS}' 0 1 2 3 15; # disapear the temporary link 
		# so unlink any from a day or more ago  (mostly for if you don't have cron)
		find ${CONTEXT_DOCUMENT_ROOT} -type l -name tmp\*.${CONTENT##*\.} -ctime +1 -exec unlink {} \; 			
	
	else 
		ERROR_CODE="${RESULT##false?}"
		APOLOGIES="Hmmm, <br>Google returned your last submision with the hint: <br><b>'${ERROR_CODE}</b>'"
		. "${FAIL}"
	fi
else
	. "${FAIL}"
fi

find ${CONTEXT_DOCUMENT_ROOT} -type l -name tmp\*.${CONTENT##*\.}" -ctime +1 -exec unlink {} \; 

