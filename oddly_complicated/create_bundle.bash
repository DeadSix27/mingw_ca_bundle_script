# #################################################################################################################
# Copyright (C) 2017 DeadSix27
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# #################################################################################################################

#!/bin/bash

srcdir="$PWD/output"
prefix="./installed/"

if [ -z "$1" ] ; then
	echo "Syntax is: create_bundle.bash install/uninstall <prefix>"
fi

unisntall="$1"

if [ ! -z "$2" ] ; then
	prefix=$2 #/xc/gcc7/workdir/xcompilers/mingw-w64-x86_64
fi

if [ "$1" == "install" ] ; then

	mkdir -p "./output"

	cd output

	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/ca-certificates-i686.install
	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/ca-certificates-x86_64.install
	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/certdata.txt
	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/certdata2pem.py
	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/nssckbi.h
	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/trust-fixes
	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/update-ca-trust
	# wget https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-ca-certificates/update-ca-trust.8

	wget -q --no-check-certificate https://www.startssl.com/certs/sca.server1.crt -O StartSSL.sca.server1.crt

	mkdir certs
	mkdir certs/legacy-default
	mkdir certs/legacy-disable
	mkdir java
	# cp certdata.txt certs/

	pushd certs > /dev/null
	python2 ../scripts/certdata2pem.py >c2p.log 2>c2p.err
	popd > /dev/null

	( cat "# This is a bundle of X.509 certificates of public Certificate\n# Authorities.  It was generated from the Mozilla root CA list.\n# These certificates and trust/distrust attributes use the file format accepted\n# by the p11-kit-trust module.\n#\n# Source: nss/lib/ckfw/builtins/certdata.txt\n# Source: nss/lib/ckfw/builtins/nssckbi.h\n#\n# Generated from:"
	  cat ../scripts/nssckbi.h | grep -w NSS_BUILTINS_LIBRARY_VERSION | awk '{print "# " $2 " " $3}';
	  echo '#';
	) > ${srcdir}/ca-bundle.trust.crt

	touch ca-bundle.legacy.default.crt
	NUM_LEGACY_DEFAULT=`find certs/legacy-default -type f | wc -l`
	if [ $NUM_LEGACY_DEFAULT -ne 0 ]; then
		 for f in certs/legacy-default/*.crt; do
			 echo "processing $f"
			 tbits=`sed -n '/^# openssl-trust/{s/^.*=//;p;}' $f`
			 alias=`sed -n '/^# alias=/{s/^.*=//;p;q;}' $f | sed "s/'//g" | sed 's/"//g'`
			 targs=""
			 if [ -n "$tbits" ]; then
					for t in $tbits; do
						 targs="${targs} -addtrust $t"
					done
			 fi
			 if [ -n "$targs" ]; then
					echo "legacy default flags $targs for $f" >> info.trust
					openssl x509 -text -in "$f" -trustout $targs -setalias "$alias" >> ca-bundle.legacy.default.crt
			 fi
		 done
	fi

	touch ca-bundle.legacy.disable.crt
	NUM_LEGACY_DISABLE=`find certs/legacy-disable -type f | wc -l`
	if [ $NUM_LEGACY_DISABLE -ne 0 ]; then
		 for f in certs/legacy-disable/*.crt; do
			 echo "processing $f"
			 tbits=`sed -n '/^# openssl-trust/{s/^.*=//;p;}' $f`
			 alias=`sed -n '/^# alias=/{s/^.*=//;p;q;}' $f | sed "s/'//g" | sed 's/"//g'`
			 targs=""
			 if [ -n "$tbits" ]; then
					for t in $tbits; do
						 targs="${targs} -addtrust $t"
					done
			 fi
			 if [ -n "$targs" ]; then
					echo "legacy disable flags $targs for $f" >> info.trust
					openssl x509 -text -in "$f" -trustout $targs -setalias "$alias" >> ca-bundle.legacy.disable.crt
			 fi
		 done
	fi

	# Add custom certificate
	echo '# alias="StartCom Class 1 Primary Intermediate Server CA"' > certs/StartSSL.sca.server1.crt
	echo '# trust=CKA_TRUST_CODE_SIGNING CKA_TRUST_EMAIL_PROTECTION CKA_TRUST_SERVER_AUTH' >> certs/StartSSL.sca.server1.crt
	echo '# distrust=' >> certs/StartSSL.sca.server1.crt
	echo '# openssl-trust=codeSigning emailProtection serverAuth' >> certs/StartSSL.sca.server1.crt
	cat ${srcdir}/StartSSL.sca.server1.crt >> certs/StartSSL.sca.server1.crt

	P11FILES=`find certs -name \*.tmp-p11-kit | wc -l`
	if [ $P11FILES -ne 0 ]; then
		for p in certs/*.tmp-p11-kit; do
			cat "$p" >> ${srcdir}/ca-bundle.trust.crt
		done
	fi

	# Append our trust fixes
	# cat trust-fixes >> ${srcdir}/ca-bundle.trust.crt

	mkdir -p p11kit_output/openssl
	mkdir p11kit_output/pem
	mkdir p11kit_output/java

	p11-kit extract --format=openssl-bundle --filter=certificates --overwrite ./p11kit_output/openssl/ca-bundle.trust.crt
	p11-kit extract --format=pem-bundle     --filter=ca-anchors   --overwrite --purpose server-auth ./p11kit_output/pem/tls-ca-bundle.pem
	p11-kit extract --format=pem-bundle     --filter=ca-anchors   --overwrite --purpose email ./p11kit_output/pem/email-ca-bundle.pem
	p11-kit extract --format=pem-bundle     --filter=ca-anchors   --overwrite --purpose code-signing ./p11kit_output/pem/objsign-ca-bundle.pem
	p11-kit extract --format=java-cacerts   --filter=ca-anchors   --overwrite --purpose server-auth ./p11kit_output/java/cacerts


	cd ..

	echo "--------------------------"
	echo "Installing to:"
	echo ${prefix}
	echo "--------------------------"

	mkdir -pv ${prefix}/ssl/certs
	cp -v "$srcdir/p11kit_output/pem/tls-ca-bundle.pem" "${prefix}/ssl/certs/ca-bundle.crt"
	cp -v "$srcdir/p11kit_output/pem/tls-ca-bundle.pem" "${prefix}/ssl/cert.pem"
	cp -v "$srcdir/p11kit_output/openssl/ca-bundle.trust.crt" "${prefix}/ssl/certs/ca-bundle.trust.crt"
	cp -v "$srcdir/p11kit_output/openssl/ca-bundle.trust.crt" "${prefix}/ssl/certs/curl-ca-bundle.crt"
	rm -rf ./output/
elif [ "$1" == "uninstall" ] ; then
	echo "--------------------------"
	echo "UNinstalling from:"
	echo ${prefix}
	echo "--------------------------"
	
	rm -v "${prefix}/ssl/certs/ca-bundle.crt"
	rm -v "${prefix}/ssl/cert.pem"
	rm -v "${prefix}/ssl/certs/ca-bundle.trust.crt"
fi

