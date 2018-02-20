#!/bin/bash
# 	check-user-tls.sh	3.10.311	2018-02-20_16:07:47_CST uadmin six-rpi3b.cptx86.com 3.9-4-g2cf76f8 
# 	   added file check for ca.pem, cert.pem, key.pem; closes #8 
# 	check-user-tls.sh	3.7.291	2018-02-18_23:16:00_CST uadmin six-rpi3b.cptx86.com 3.7 
# 	   New release, ready for production 
# 	check-user-tls.sh	3.6.286	2018-02-15_13:21:37_CST uadmin six-rpi3b.cptx86.com 3.6-19-g7e77a24 
# 	   added --version and -v close #9 
#	check-user-tls.sh	3.6.276	2018-02-10_19:26:37_CST uadmin six-rpi3b.cptx86.com 3.6-9-g8424312 
#	docker-scripts/docker-TLS; modify format of display_help; closes #6 
#
#	set -x
#	set -v
#
display_help() {
echo -e "\n${0} - Check public, private keys, and CA for a user"
echo -e "\nUSAGE\n   ${0} <user-name> <home-directoty>"
echo    "   ${0} [--help | -help | help | -h | h | -? | ?] [--version | -v]"
echo -e "\nDESCRIPTION\nUsers can check their public, private keys, and CA in /home or other"
echo    "non-default home directories.  The file and directory permissions are also"
echo    "checked.  Administrators can check other users certificates by using"
echo    "sudo ${0} <TLS-user>."
echo -e "\nOPTIONS"
echo    "   TLSUSER   user, default is user running script"
echo    "   USERHOME  location of user home directory, default /home/"
echo    "      Many sites have different home directories locations (/u/north-office/)"
echo -e "\nDOCUMENTATION\n   https://github.com/BradleyA/docker-scripts/tree/master/docker-TLS"
echo -e "\nEXAMPLES\n   User sam can check their certificates\n\t${0}"
echo -e "   User sam checks their certificates in a non-default home directory\n\t${0} sam /u/north-office/"
echo -e "   Administrator checks user bob certificates\n\tsudo ${0} bob"
echo -e "   Administrator checks user sam certificates in a different home directory\n\tsudo ${0} sam /u/north-office/"
}
if [ "$1" == "--help" ] || [ "$1" == "-help" ] || [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "h" ] || [ "$1" == "-?" ] || [ "$1" == "?" ] ; then
	display_help
	exit 0
fi
if [ "$1" == "--version" ] || [ "$1" == "-v" ] ; then
        head -2 ${0} | awk {'print$2"\t"$3'}
        exit 0
fi
###
TLSUSER=${1:-${USER}}
USERHOME=${2:-/home/}
#	Root is required to check other users or user can check their own certs
if ! [ $(id -u) = 0 -o ${USER} = ${TLSUSER} ] ; then
	display_help
	echo "${0} ${LINENO} [ERROR]:   Use sudo ${0}  ${TLSUSER}"	1>&2
	echo -e "\n>>   SCRIPT MUST BE RUN AS ROOT TO CHECK <another-user>/.docker DIRECTORY. <<\n"	1>&2
	exit 1
fi
#	Check if user has home directory on system
if [ ! -d ${USERHOME}${TLSUSER} ] ; then 
	display_help
	echo -e "${0} ${LINENO} [ERROR]:	${TLSUSER} does not have a home directory\n\ton this system or ${TLSUSER} home directory is not ${USERHOME}${TLSUSER}"	1>&2
	exit 1
fi
#	Check if user has .docker directory
if [ ! -d ${USERHOME}${TLSUSER}/.docker ] ; then 
	display_help
	echo -e "\n${0} ${LINENO} [ERROR]:	${TLSUSER} does not have a .docker directory"	1>&2
	exit 1
fi
#	Check if user has .docker ca.pem file
if [ ! -e ${USERHOME}${TLSUSER}/.docker/ca.pem ] ; then 
	echo -e "\n${0} ${LINENO} [ERROR]:	${TLSUSER} does not have a .docker/ca.pem file"	1>&2
	exit 1
fi
#	Check if user has .docker cert.pem file
if [ ! -e ${USERHOME}${TLSUSER}/.docker/cert.pem ] ; then 
	echo -e "\n${0} ${LINENO} [ERROR]:	${TLSUSER} does not have a .docker/cert.pem file"	1>&2
	exit 1
fi
#	Check if user has .docker key.pem file
if [ ! -e ${USERHOME}${TLSUSER}/.docker/key.pem ] ; then 
	echo -e "\n${0} ${LINENO} [ERROR]:	${TLSUSER} does not have a .docker/key.pem file"	1>&2
	exit 1
fi
#	View user certificate expiration date of ca.pem file
echo -e "\nView ${USERHOME}${TLSUSER}/.docker certificate expiration date of ca.pem file."
openssl x509 -in  ${USERHOME}${TLSUSER}/.docker/ca.pem -noout -enddate
#	View user certificate expiration date of cert.pem file
echo -e "\nView ${USERHOME}${TLSUSER}/.docker certificate expiration date of cert.pem file"
openssl x509 -in ${USERHOME}${TLSUSER}/.docker/cert.pem -noout -enddate
#	View user certificate issuer data of the ca.pem file.
echo -e "\nView ${USERHOME}${TLSUSER}/.docker certificate issuer data of the ca.pem file."
openssl x509 -in ${USERHOME}${TLSUSER}/.docker/ca.pem -noout -issuer
#	View user certificate issuer data of the cert.pem file.
echo -e "\nView ${USERHOME}${TLSUSER}/.docker certificate issuer data of the cert.pem file."
openssl x509 -in ${USERHOME}${TLSUSER}/.docker/cert.pem -noout -issuer
#	Verify that user public key in your certificate matches the public portion of your private key.
echo -e "\nVerify that user public key in your certificate matches the public portion of your private key."
(cd ${USERHOME}${TLSUSER}/.docker ; openssl x509 -noout -modulus -in cert.pem | openssl md5 ; openssl rsa -noout -modulus -in key.pem | openssl md5) | uniq
echo -e "If only one line of output is returned then the public key matches the public portion of your private key.\n"
#	Verify that user certificate was issued by the CA.
echo    "Verify that user certificate was issued by the CA."
openssl verify -verbose -CAfile ${USERHOME}${TLSUSER}/.docker/ca.pem ${USERHOME}${TLSUSER}/.docker/cert.pem
#	Verify and correct file permissions for ${USERHOME}${TLSUSER}/.docker/ca.pem
echo    "Verify and correct file permissions for ${USERHOME}${TLSUSER}/.docker"
if [ $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker/ca.pem) != 444 ]; then
	echo -e "${0} ${LINENO} [ERROR]:	File permissions for ${USERHOME}${TLSUSER}/.docker/ca.pem\n\tare not 444.  Correcting $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker/ca.pem) to 0444 file permissions"	1>&2
	chmod 0444 ${USERHOME}${TLSUSER}/.docker/ca.pem
fi
#	Verify and correct file permissions for ${USERHOME}${TLSUSER}/.docker/cert.pem
if [ $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker/cert.pem) != 444 ]; then
	echo -e "${0} ${LINENO} [ERROR]:	File permissions for ${USERHOME}${TLSUSER}/.docker/cert.pem\n\tare not 444.  Correcting $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker/cert.pem) to 0444 file permissions"	1>&2
	chmod 0444 ${USERHOME}${TLSUSER}/.docker/cert.pem
fi
#	Verify and correct file permissions for ${USERHOME}${TLSUSER}/.docker/key.pem
if [ $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker/key.pem) != 400 ]; then
	echo -e "${0} ${LINENO} [ERROR]:	File permissions for ${USERHOME}${TLSUSER}/.docker/key.pem\n\tare not 400.  Correcting $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker/key.pem) to 0400 file permissions"	1>&2
	chmod 0400 ${USERHOME}${TLSUSER}/.docker/key.pem
fi
#	Verify and correct directory permissions for ${USERHOME}${TLSUSER}/.docker directory
if [ $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker) != 700 ]; then
	echo -e "${0} ${LINENO} [ERROR]:	Directory permissions for ${USERHOME}${TLSUSER}/.docker\n\tare not 700.  Correcting $(stat -Lc %a ${USERHOME}${TLSUSER}/.docker) to 700 directory permissions"	1>&2
	chmod 700 ${USERHOME}${TLSUSER}/.docker
fi
echo -e "\n${0} ${LINENO} [INFO]:	Done.\n"	1>&2
#
#	May want to create a version of this script that automates this process for SRE tools,
#		but keep this script for users to run manually,
#	open ticket and remove this comment
###
