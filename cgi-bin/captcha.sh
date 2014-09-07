#! /bin/bash

# implement a bare bones recaptcha
#	o present challenge page on GET
#	o proof results on POST 
#		- proof positive pass
#		- proof negative repeat w/new challenge	

# These will be the keys 
# For the domain the script is running at.
# They will be provided by Google at:
# https://www.google.com/recaptcha/admin/create
# yours will necessarily be different
#
# note we do not actually touch user input at all.

PUBLIC_KEY="XXXXXXXXXXXXXyyyyyyyyyyyyyyyyyyyyyyyyyyy"
PRIVATE_KEY="XXXXXXXXXXXXXzzzzzzzzzzzzzzzzzzzzzzzzzz"

# Path to the templates (move outside web root for more security)
TMPLT_PATH="${CONTEXT_DOCUMENT_ROOT}"

# what to serve if captcha is verified
SUCCESS="${TMPLT_PATH}/recaptcha_verified.tmplt"

#what to serve if the captcha has not been verified
FAIL="${TMPLT_PATH}/recaptcha_challenge.tmplt"

# path to, and name of the content you are serving to the not-bots
# EDIT ME
CONTENT_PATH=${TMPLT_PATH} 
CONTENT=whatever.typ
		
# making a more specific constant than 'recaptchatmp' 
# could help with cleanup 
CONST="recaptchatmp"

echo Content-type: text/html
echo -e "\r"

if  [ ${REQUEST_METHOD} == 'POST' ] ; then
	#	ahh google ... 
	#	produce different parameter names in "google.com/recaptcha/api/challenge" 
	#	than are consumed in "google.com/recaptcha/api/verify"
	#	so instead of simply passing them along we get to fix the field names first.

	VERIFY_ME="$(sed 's/recaptcha_//g;s/_field//g')&remoteip=${REMOTE_ADDR}&privatekey=${PRIVATE_KEY}"		
	RESULT=`curl -s --data "${VERIFY_ME}"  https://www.google.com/recaptcha/api/verify`

	if [ ${RESULT%%?success} == "true" ] ; then
		# avoid leaking the actual content filename
		# mktmp or uuid might be cleaner if available 
		ANON="${CONST}`date | md5sum`"    
		# give the alias the same suffix as the content 								
		ALIAS="${ANON%%  -*}.${CONTENT##*\.}"       		
		ln -s ${CONTEXT_DOCUMENT_ROOT}/${CONTENT} ${CONTEXT_DOCUMENT_ROOT}/${ALIAS}
		. "${SUCCESS}"
		# unlinking the alias on exit with trap is proving to be too soon
		#trap 'unlink ${CONTEXT_DOCUMENT_ROOT}/${ALIAS}' 0 1 2 3 15;
		# so find and unlink any from a day or more ago  
		# see: last line  (or use cron)
	else 
		ERROR_CODE="${RESULT##false?}"
		APOLOGIES="Hmmm, <br>Google returned your last submission with the hint: <br><b>'${ERROR_CODE}</b>'"
		. "${FAIL}"
	fi
else
	. "${FAIL}"
fi
# so unlink any from a day or more ago  (mostly for if you don't have cron)
find ${CONTEXT_DOCUMENT_ROOT} -type l -name ${CONST}\*.${CONTENT##*\.} -ctime +1 -exec unlink {} \;

