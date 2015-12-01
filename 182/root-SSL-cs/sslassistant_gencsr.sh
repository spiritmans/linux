#!/bin/bash
# ex30a.sh: "Colorized version of ex30.sh

Escape="\033";

BlackF="${Escape}[30m"; RedF="${Escape}[31m"; GreenF="${Escape}[32m";
YellowF="${Escape}[33m"; BlueF="${Escape}[34m"; Purplef="${Escape}[35m";
CyanF="${Escape}[36m"; WhiteF="${Escape}[37m";

BlackB="${Escape}[40m"; RedB="${Escape}[41m"; GreenB="${Escape}[42m";
YellowB="${Escape}[43m"; BlueB="${Escape}[44m"; PurpleB="${Escape}[45m";
CyanB="${Escape}[46m"; WhiteB="${Escape}[47m";

BoldOn="${Escape}[1m"; BoldOff="${Escape}[22m";
ItalicsOn="${Escape}[3m"; ItalicsOff="${Escape}[23m";
UnderlineOn="${Escape}[4m"; UnderlineOff="${Escape}[24m";
BlinkOn="${Escape}[5m"; BlinkOff="${Escape}[25m";
InvertOn="${Escape}[7m"; InvertOff="${Escape}[27m";

Reset="${Escape}[0m";

backupDateTime="%m%d%Y%H%M%S"
timestamp=`date +"$backupDateTime"`

#Change terminal to display UTF-8
LANG=en_US.UTF-8

#=========================================HEADER END=======================================================
#=========================================BRAND START=====================================================
brand="Symantec"
#=========================================BRAND END=======================================================



#Create SSL directory if it does not exist
symantecDir="${HOME}/${brand}/ssl"
mkdir -p ${symantecDir} >/dev/null 2>&1
if [ "$?" = 1 ]
then
    echo "Unable to create the directory '$HOME/${brand}/ssl'"
	exit 1
fi

logFile=${symantecDir}/sslassistant_${timestamp}.log
log()
{
	time=`date +"%t %x %k:%M:%S%t"`
        logentry="INFO "$time$1
	echo -e $logentry >> $logFile
}

logError()
{

	time=`date +"%t %x %k:%M:%S%t"`
	logerror="ERROR"$time$1
	echo -e $logerror >>$logFile
}
# Check to see if openssl is available
checkOpenSSLInstalled()
{
	command -v openssl &>/dev/null || { echo "Cannot locate openssl." >&2; exit 1; }
	if [ "$(id -u)" != "0" ]; then
	   echo "Please run the SSL Assitant Tool as root" 1>&2
           exit 1
         fi
}

# Check to see if curl is available
checkCurlInstalled()
{
     command -v curl &>/dev/null || { echo "Cannot locate curl.To auto download and install certificate please install curl." >&2; exit 1; }
}

# Check apache version greater than 2.2
checkApacheVersionGreaterThan_2_2()
{
   version="2.2.0"

    IFS=$'.'
    arr1=($fullVersion)
    arr2=($version)
    unset IFS

    for ((i=0;i<${#arr1[@]};++i)); do

	   if (( ${arr1[i]} == ${arr2[i]} )); then
     		apacheVersionGreaterThan_2_2="equal"
     		continue
       elif (( ${arr1[i]} < ${arr2[i]} )); then
            apacheVersionGreaterThan_2_2="false"
            break
       elif (( ${arr1[i]} > ${arr2[i]} )); then
            apacheVersionGreaterThan_2_2="true"
            break
           fi
    done
}



# Check apache version smaller than 2.4.8
checkApacheVersionGreaterThan_2_4_8()
{
    version="2.4.8"

    IFS=$'.'
    arr1=($fullVersion)
    arr2=($version)
    unset IFS

    for ((i=0;i<${#arr1[@]};++i)); do

          if (( ${arr1[i]} == ${arr2[i]} )); then
             apacheVersionGreaterThan_2_4_8="equal"
             continue
          elif (( ${arr1[i]} < ${arr2[i]} )); then
             apacheVersionGreaterThan_2_4_8="false"
             break
          elif (( ${arr1[i]} > ${arr2[i]} )); then
             apacheVersionGreaterThan_2_4_8="true"
             break
          fi
     done
}

jsonValue()
{
  KEY=$1
  num=$2
  awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}



requiredPrompt()
{
	echo -e -n "$1"
	read result;
        log "Value entered for $1 $result"

	while [ -z "$result" ]; do
		echo "The value entered is invalid. Re-enter the information."
		logError "Invalid value entered for $1 $result"
                echo -e -n "$1"
		read result;
		log "Value entered for $1 $result"
    done
}

requiredFilePrompt()
{
	read -e -p "$1" result
        log "Filename entered for $1 $result"

	while [ -z "$result" ]; do
		echo "The value entered is invalid. Re-enter the information."
		logError "Invalid filename entered for $1 $result"
                read -e -p "$1" result
		log "Filename entered for $1 $result"
	done
}

requiredTwoCharPrompt()
{
	echo -e -n "$1"
	read result;
        log "Value entered for $1 $result"

	while [ "${#result}" -ne "2" ]; do
		echo "The value entered is invalid. Re-enter the information."
		logError "Invalid value entered for $1 $result"
                echo -e -n "$1"
		read result;
		log "Value entered for $1 $result"
    done
}

requiredSecretPrompt()
{
	echo -e -n "$1"
	read -s result;
	log "Value entered for Password '******'"
	echo

	while [ -z "$result" ]; do
		echo "The value entered is invalid. Re-enter the information."
		logError "Invalid value entered for Password"
                echo -e -n "$1"
		read -s result;
		echo
		log "Value entered for Password '******'"
    done
}

#Check that HTTPD version 2 is installed and mod_ssl.so is available.
checkHttpd()
{
	log  "Checking to see if httpd is available..."
        # Check to see if httpd is available
	command -v httpd &>/dev/null || { echo "Cannot locate Apache 2.0 in system path." >&2; log "Cannot locate Apache in system path."; exit 1; }

	apache=`httpd -v | grep Apache/`
	fullVersion=${apache#*/}
	fullVersion=${fullVersion% *}
	version=${fullVersion%%.*}
	
	log "Checking if httpd -v command returns valid version..."
	if [ -z "$version" ]
	then
	       echo ""httpd -v" command did not return a valid version.Please ensure you have Apache version 2.0 and above installed"
		
	else
		log  "Checking to see if httpd is version 2..."
        	if [ $version != "2" ]
		then
			echo "Apache 2.0 not found. "'('"Found version $fullVersion"')'""
			logError "Apache 2.0 not found. Found version $fullVersion"
			exit 1
		fi
	fi

	log  "Checking to see if mod_ssl is available..."
        if [ ! -e "/etc/httpd/modules/mod_ssl.so" ]
	then
		echo "Unable to find /etc/httpd/modules/mod_ssl.so. Make sure that the mod_ssl"
		echo "module is installed on this server."
		logError "Unable to find /etc/httpd/modules/mod_ssl.so. Make sure that the mod_ssl module is installed on this server."
		log "module is installed on this server."
		exit 1;
	fi
}

showEula()
{
	echo -e -n "${BoldOn}Do you accept the End User Software Licence Agreement in the eula.txt file? (y/n):${BoldOff} "
	log "Presenting End User Software Licence Agreement..."
        while [ "$accept" != "y" ]; do
		read -s -n1 accept
                log "End User Software Licence Agreement accepted."
		if [ "$accept" = "n" ]
		then
			echo n
			log "End User Software Licence Agreement declined."
			exit 0
		fi
	done
	echo y
}
getCipher(){
echo
        echo "The RSA encryption algorithm is typical for most cases, while the DSA encryption algorithm"
        echo " is a requirement for some U.S. government agencies. Only use DSA if you are sure that you need it."
        echo -e -n "${BoldOn}Please specify the cipher algorithm. ${BoldOff}\n"
	if [[ "$brand" == "Symantec" ]]
	then
		echo -e -n "${BoldOn}Choose between ${CyanF} RSA ${Reset} ${BoldOn}or ${CyanF} DSA ${Reset} ${BoldOn}or ${CyanF} ECC ${Reset}:"
	else
		echo -e -n "${BoldOn}Choose between ${CyanF} RSA ${Reset} ${BoldOn}or ${CyanF} DSA ${Reset}"
	fi

	read algo
	algo=$(echo $algo | tr '[:lower:]' '[:upper:]')
        
		if [ -z "${algo##[R][S][A]}" ]
                 then
                      cipher="RSA"
                      
                elif [ -z "${algo##[D][S][A]}" ]
                then
                      cipher="DSA"
                elif [ -z "${algo##[E][C][C]}" ] && [[ "$brand" == "Symantec" ]]
	        then
		    cipher="ECC"
  
		else
                   cipher="RSA"
                    echo
                    echo -e -n "\tInvalid selection. Defaulting to RSA"
                    echo
	fi
}
checkAlgorithmEntered(){

	count=$((count+1))
	if  echo "${AlgoOptions[@]}" | fgrep --word-regexp "$UserInput">/dev/null 2>&1; 
	then
          
	     cipher="$UserInput"
	     result=1
	    
	elif [ $count -lt 2 ]
	then
	     echo "Type the name of your preferred encryption algorithm from following value/s: "
	     for (( i=${cipherOptions}-1; i>=0; i-- ));
	     do
	              echo -e -n "${BoldOn}.${AlgoOptions[i]}${BoldOff}\n"
	     done
	     echo -n "Enter the encryption algorithm:"
    	     read UserInput
	     UserInput=$(echo $UserInput | tr '[:lower:]' '[:upper:]')
	else
   	    cipher=$defaultalgo
	    
     fi
} 

setCipher(){
	declare -i count=0
	declare -i result=0
	declare -i cipherOptions=0
	
	cipher=$(echo ${cipher} | tr '[:lower:]' '[:upper:]')
	IFS="," read -ra AlgoOptions<<<"$cipher"               
	defaultalgo="${AlgoOptions[0]}"
	cipherOptions=${#AlgoOptions[@]}

	if [ $cipherOptions -eq 1 ]
	then
	  checkAlgorithmEntered

	   if [ $result -eq 1 ]
	   then
		log "setting cipher value to $cipher" 
	   else
         	checkAlgorithmEntered
	   fi
 	else
	echo "Type the name of your preferred encryption algorithm from following value/s: "

	for (( i=${cipherOptions}-1; i>=0; i-- ));
	  do
			    
		echo -e -n "${BoldOn}.${AlgoOptions[i]}${BoldOff}\n"
	  done
		echo -n "Enter the encryption algorithm:"		
		read UserInput
		UserInput=$(echo $UserInput | tr '[:lower:]' '[:upper:]')
		checkAlgorithmEntered

		if [ $result -eq 1 ]
		then
			log "setting cipher value to $cipher" 
		else
        	 	checkAlgorithmEntered
		fi
	fi
}



#=========================================SUBJECT START=====================================================

getSubject1()
{
        echo
        echo "Enter the fully-qualified domain name for the Web server where"
	echo "you plan to request the certificate. Examples are"
	echo "\"server.example.com\" and \"www.example.com\""
	echo
	requiredPrompt "${BoldOn}Your web server's FQDN is:${BoldOff} "
	if [[ "$result" =~ "'" || "$result" =~ "\"" ]]
        then
            echo "Quotes are not allowed in Domain Name"
            exit 1
        fi

        commonName=$result
	echo

	requiredTwoCharPrompt "${BoldOn}Enter the two letter country code:${BoldOff} "
	country=$result
        echo

	echo "For the US and Canada, enter the state or province name."
	echo "Do not abbreviate it. For example, do not use OH, instead use Ohio."
	echo "All other customers enter N/A."
	echo
	requiredPrompt "${BoldOn}State or Province:${BoldOff} "
	state=$result
	echo

	requiredPrompt "${BoldOn}Enter the name of the server's locality or city:${BoldOff} "
	city=$result
	echo

	echo "Enter the full legal name of the organization as it appears on your"
	echo "account. This field is case sensitive."
	echo
	requiredPrompt "${BoldOn}Organization:${BoldOff} "
	org=$result
	echo

	echo "You can optionally use an organization unit to help specify"
	echo "certificates. For example, you could use ENG for engineering."
	echo
	echo -e -n "${BoldOn}Enter the Organization Unit. Press Enter to skip this field:${BoldOff} "
	read orgunit
	echo

	if [ -z "$orgunit" ]
	then
		subject="/C=$country/ST=$state/L=$city/O=$org/CN=$commonName"
	else
		subject="/C=$country/ST=$state/L=$city/O=$org/OU=$orgunit/CN=$commonName"
	fi
}

#=========================================SUBJECT END=======================================================


#=========================================SUBJECT START=====================================================
getSubject2()
{
 commonName="www.eachbuyer.com"
 country="HK"
 state="HONG KONG ISLAND"
 city="CENTRAL"
 org="WINNET TRADING LTD"
 orgunit=""

 defaultCommonName="__COMMONNAME__"
 defaultCountry="__COUNTRY__"
 defaultState="__PROVINCE__"
 defaultCity="__CITY__"
 defaultOrg="__ORGANIZATION__"
 defaultOrgUnit="__ORGANIZATIONALUNIT__"

if [[ "$state" =~ "$defaultState" || "$city" =~ "$defaultCity" || "$commonName" =~ "$defaultCommonName" || "$country" =~ "$defaultCountry" || "$org" =~ "$defaultOrg" || -z "$state" || -z "$city" || -z "$commonName" || -z "$country" || -z "$org" ]]
then
	getSubject1
else
	 if [[ "$orgunit" =~ "verisign" || "$orgunit" =~ "$defaultOrgUnit" ]]
	 then
		orgunit=""
	 fi
	 if [ -z "$orgunit" ]
	 then
		subject="/C=$country/ST=$state/L=$city/O=$org/CN=$commonName"
	 else
		subject="/C=$country/ST=$state/L=$city/O=$org/OU=$orgunit/CN=$commonName"
	fi

	displaySubject
fi

 log "CSR subject is $subject"
}

displaySubject()
{

echo
#echo -e "${BoldOn}Welcome to the ${brand} Certificate Signing Request Generation Assistant Version 5 ${BoldOff}"
echo "Log file for this session created at $logFile"
echo
cipher=$(echo ${cipher} | tr '[:lower:]' '[:upper:]')
echo -e "${BoldOn}This tool will generate a $cipher certificate signing request "'('"CSR"')'" with the given Distinguished Name: ${BoldOff}"
echo
echo -e "${BoldOn}Encryption Algorithm: ${BoldOff}$cipher"
echo -e "${BoldOn}Common Name: ${BoldOff}         $commonName"
echo -e "${BoldOn}Organization: ${BoldOff}        $org"  | sed 's/[\\]//g'
echo -e "${BoldOn}Organization Unit: ${BoldOff}   $orgunit"
echo -e "${BoldOn}City: ${BoldOff}                $city"
echo -e "${BoldOn}State: ${BoldOff}               $state"
echo -e "${BoldOn}Country: ${BoldOff}             $country"
echo

}
#=========================================SUBJECT END=======================================================

genCsr_preprocessing()
{

	echo
	echo "Enter a new passphrase. This protects the private key that you are"
	echo "about to create. You will need to put this password into Apache\'s"
	echo "configuration file. This field is required."
	echo
	requiredSecretPrompt "${BoldOn}Your passphrase is:${BoldOff} "
	passphrase=$result
	requiredSecretPrompt "${BoldOn}Re-enter your passphrase:${BoldOff} "
	passphraseVerify=$result

	if [ "${passphrase}" != "${passphraseVerify}" ];
	then
		echo -e "Passphrases do not match"
		log "Passphrases do not match"
		exit 1
	fi
	echo

	modifiedCommonName=${commonName//./_}
        csr="$HOME/${brand}/ssl/${modifiedCommonName}_${cipher}_csr.txt"
	privateKey="$HOME/${brand}/ssl/${modifiedCommonName}_${cipher}_private.key"
	


	#Backup old CSR and private key if they already exist
	timestamp=`date +"$backupDateTime"`

	if [ -e "$csr" ]
	then
		echo "Backing up $csr to ${csr}.${timestamp}.bak"
	 	log "Backing up $csr to ${csr}.${timestamp}.bak"
                mv "$csr" ${csr}.${timestamp}.bak
	fi

	if [ -e "$privateKey" ]
	then
		echo "Backing up $privateKey to ${privateKey}.${timestamp}.bak"
		log "Backing up $privateKey to ${privateKey}.${timestamp}.bak"
	 	mv "$privateKey" ${privateKey}.${timestamp}.bak
	fi
	
	if [ "${cipher}" == "ECC" ]
	then
		privateKeytempFile="$HOME/${brand}/ssl/${modifiedCommonName}_${cipher}_private_temp.key"
	fi
}

genCsr_RSA()
{
	echo "Writing new RSA CSR to \"$csr\""
	log "Writing new RSA CSR to $csr..."
	openssl req -out "$csr" -utf8 -nameopt -utf8 -subj "$subject" -new -newkey rsa:2048 -keyout "$privateKey" -passout pass:$passphrase >/dev/null 2>&1

	if [ -e "$csr" ]
	then
		echo "Success."
		log "Success."
	else
		echo "Failed."
		log "Failed."
	fi

	cat "$csr"
}
genCsr_DSA()
{
        echo "Writing new DSA CSR to \"$csr\""
	log "Writing new DSA CSR to $csr..."
	pathline="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	openssl gendsa $pathline/Pem-2048-256.pem  -out "$privateKey" -des3 -passout pass:$passphrase >/dev/null 2>&1
	openssl req -inform PEM -newkey dsa:$pathline/Pem-2048-256.pem -key "$privateKey" -sha256 -out "$csr" -utf8 -nameopt -utf8 -subj "$subject" -passin pass:"$passphrase" >/dev/null 2>&1

	if [ -e "$csr" ]
	then
		echo "Success."
		log "Success."
	else
		echo "Failed."
		log "Failed."
	fi

	cat "$csr"
}

genCsr_ECC()
{
        echo "Writing new ECC CSR to \"$csr\""
	log "Writing new ECC CSR to $csr..."
		
	openssl ecparam -out "$privateKeytempFile" -name prime256v1  -genkey >/dev/null 2>&1
	openssl ec -in "$privateKeytempFile" -out "$privateKey" -des3 -passout pass:"$passphrase" >/dev/null 2>&1
	openssl req -new -key "$privateKey" -sha256 -out "$csr" -utf8 -nameopt -utf8 -subj "$subject" -passin pass:"$passphrase" >/dev/null 2>&1

	if [ -e "$csr" ]
	then
		echo "Success."
		log "Success."
	else
		echo "Failed."
		log "Failed."
	fi

	cat "$csr"
	rm -rf "$privateKeytempFile"
}

clear
echo
echo
log "${brand} Certificate Signing Request Generation Assistant Log `date`"
checkOpenSSLInstalled
showEula
echo
	if [[ "$brand" == "Symantec" ]]
	then
		echo -e "${BoldOn}${UnderlineOn}Welcome to the ${brand} Certificate Assistant Version 5.0.${UnderlineOff}${BoldOff}"
	else 
		echo -e "${BoldOn}${UnderlineOn}Welcome to the ${brand} Certificate Assistant Version 4.0.${UnderlineOff}${BoldOff}"
	fi
echo
echo
echo "Log file for this session created at $logFile"
echo
echo
echo -e "${BoldOn} 1. Continue to generate a certificate signing request "'('"CSR"')'" ${BoldOff}"
echo -e "${BoldOn} q. Quit ${BoldOff}"
echo
echo -n "Enter the task number: ";

cipher="RSA,DSA"
defaultCipher="__CIPHER__"


while :
do
	read -s -n1 choice

	case $choice in
	1)
		echo 1
		log "Option chosen to generate a certificate signing request (CSR)"
		echo "Option chosen to generate a certificate signing request (CSR)"

		if [[ "$cipher" =~ "$defaultCipher" || -z "$cipher" ]]
		then
		    getCipher
		else
		    setCipher
		fi
		
                if [[ "$cipher" == "DSA" ]]
		then
		    echo "CSR algorithm type is DSA"
		    log "CSR algorithm type is DSA"
                    getSubject2
		    		genCsr_preprocessing
                    genCsr_DSA
                elif [[ "$cipher" == "ECC" ]]  && [[ "$brand" == "Symantec" ]]
		then
                     echo "CSR algorithm type is ECC"
                     log "CSR algorithm type is ECC"
                     getSubject2
		     		 genCsr_preprocessing
                     genCsr_ECC
                else
                     echo "CSR algorithm type is RSA"
                     log "CSR algorithm type is RSA"
                     getSubject2
		     		 genCsr_preprocessing
                     genCsr_RSA
                fi

		break
		;;
	q)
		echo q
		log "Option chosen to quit SSLAssistant tool"
		exit 0
	esac
done


echo "done."