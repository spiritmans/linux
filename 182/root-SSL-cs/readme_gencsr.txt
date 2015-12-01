Symantec SSL Certificate Assistant 5.0 for Red Hat Linux Servers

This readme describes how to use the Symantec SSL Certificate Assistant to generate certificate signing requests (CSRs).

- REQUIRED OPERATING SYSTEMS AND WEB SERVERS
- OTHER REQUIREMENTS
- NOTES
- GENERATE AND SUBMIT CSR
- CSR GENERATION WITHOUT USING THE ASSISTANT

REQUIRED OPERATING SYSTEMS AND WEB SERVERS

- Red Hat Enterprise Linux 5
- Red Hat Enterprise Linux 6
- Apache 2.0 for RSA or DSA
- Apache 2.3.4 or later for ECC

OTHER REQUIREMENTS

- Root access on the server where you want to install the certificate
- An Apache restart after you install the certificate
- OpenSSL
- mod_ssl module

NOTES

The generated private and public key pairs use:
  - RSA 2048
  - ECC 256
  - DSA 2048-256

The SSL Assistant supports:
  - RSA encryption algorithm, which is recommended for most cases.
  - ECC encryption algorithm, which has stronger encryption.
  - DSA encryption algorithm, which is a requirement for some U.S. government agencies.
	
- This script backs up the CSR and private key before making any changes to them. The script appends a time stamp (MonthDayYear24HourMinSec) to the file name. For example mycsr.txt becomes mycsr.12202011184932.txt.

GENERATE AND SUBMIT THE CSR

1. Move the sslassistant.sh, the eula.txt, and the readme.txt to the server where you will install the certificate.
2. Make sure that the Apache 2 executable is in the system PATH (usually /usr/sbin/httpd).
3. Log in as root and start the script.
# ./sslassistant.sh
4. Follow the on-screen instructions.
5. Note that the private key is put in the same directory as the CSR. You need the private key when you install the SSL certificate.
6. Sign in to your Trust Center account:
https://trustcenter.websecurity.symantec.com/process/retail/console_login?application_locale=VRSN_US
7. Copy the CSR text into the appropriate field.

CSR GENERATION WITHOUT USING THE ASSISTANT

- Visit our support site:
https://knowledge.verisign.com/support/ssl-certificates-support/index.html
- For CSR generation instructions, see:
https://knowledge.verisign.com/support/ssl-certificates-support/index?page=content&id=AR235&actp=LIST&viewlocale=en_US