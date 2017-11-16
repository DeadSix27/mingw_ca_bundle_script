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
	
	cp "/etc/ssl/certs/ca-certificates.crt" "./ca-certificates.crt"

	# StartSSL cert is probably unessesary to add manually:
	# wget -q --no-check-certificate https://www.startssl.com/certs/sca.server1.crt -O StartSSL.sca.server1.crt
	
	# cat "StartSSL.sca.server1.crt" >> "ca-certificates.crt"
	
	cd ..

	echo "--------------------------"
	echo "Installing to:"
	echo ${prefix}
	echo "--------------------------"

	mkdir -pv ${prefix}/ssl/certs
	cp -v "$srcdir/ca-certificates.crt" "${prefix}/ssl/certs/ca-bundle.crt"
	cp -v "$srcdir/ca-certificates.crt" "${prefix}/ssl/cert.pem"
	cp -v "$srcdir/ca-certificates.crt" "${prefix}/ssl/certs/ca-bundle.trust.crt"
	cp -v "$srcdir/ca-certificates.crt" "${prefix}/ssl/certs/curl-ca-bundle.crt"
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

