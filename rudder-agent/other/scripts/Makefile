#####################################################################################
# Copyright 2011 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

.DEFAULT_GOAL := localdepends

RUDDER_VERSION_TO_PACKAGE = 2.10.0
CFENGINE_RELEASE = 3.5.3
FUSION_RELEASE = 2.3.6
TOKYOCABINET_RELEASE = 1.4.48
PCRE_RELEASE = 8.35
OPENSSL_RELEASE = 1.0.1g
ZLIB_RELEASE = 1.2.8
BZIP2_RELEASE = 1.0.6
BUILD_DIR = ../build
TMP_DIR := $(shell mktemp -dq /tmp/rudder.XXXXXX)
WGET := $(if $(PROXY), http_proxy=$(PROXY) ftp_proxy=$(PROXY)) /usr/sfw/bin/wget -q
PATCH = /usr/bin/gpatch
FIND = /opt/csw/bin/gfind
TAR = /opt/csw/bin/gtar

localdepends: $(BUILD_DIR) $(BUILD_DIR)/initial-promises $(BUILD_DIR)/files $(BUILD_DIR)/fusioninventory-agent $(BUILD_DIR)/zlib-source $(BUILD_DIR)/bzip2-source $(BUILD_DIR)/tokyocabinet-source $(BUILD_DIR)/pcre-source $(BUILD_DIR)/openssl-source $(BUILD_DIR)/cfengine-source $(BUILD_DIR)/rudder-agent.cron 
	rm -rf $(TMP_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/cfengine-source:
	# Original URL: http://cfengine.com/source-code/download?file=cfengine-$(CFENGINE_RELEASE).tar.gz
	$(WGET) -O $(TMP_DIR)/cfengine.tgz http://www.normation.com/tarball/cfengine-$(CFENGINE_RELEASE).tar.gz
	$(TAR) xzf $(TMP_DIR)/cfengine.tgz -C $(TMP_DIR)
	mv $(TMP_DIR)/cfengine-$(CFENGINE_RELEASE) $(BUILD_DIR)/cfengine-source
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0001-add-support-for-openvz.patch
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0002-cfengine-report-on-package-removal.patch
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0003-dont-remove-blank-line-in-templates.patch
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0004-partially-revert-a-change-intended-to-alter-the-log.patch
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0005-tiny-optimization-in-safe-open.patch
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0006-fix-failure-to-open-paths-ending-in-a-slash.patch
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0007-fix-incorrect-return-value-for-empty-string-in-safe.patch
	$(PATCH) -d $(BUILD_DIR)/cfengine-source -p1 < ../patches/cfengine/0008-make-safe-open-treat-trailing-slashes-like-open.patch

$(BUILD_DIR)/tokyocabinet-source:
	# Original URL: http://fallabs.com/tokyocabinet/tokyocabinet-${TOKYOCABINET_RELEASE}.tar.gz
	$(WGET) -O $(TMP_DIR)/tokyocabinet.tgz http://www.normation.com/tarball/tokyocabinet-${TOKYOCABINET_RELEASE}.tar.gz
	$(TAR) xzf $(TMP_DIR)/tokyocabinet.tgz -C $(TMP_DIR)
	mv $(TMP_DIR)/tokyocabinet-$(TOKYOCABINET_RELEASE) $(BUILD_DIR)/tokyocabinet-source

$(BUILD_DIR)/pcre-source:
	$(WGET) -O $(TMP_DIR)/pcre.tgz http://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$(PCRE_RELEASE).tar.gz
	$(TAR) xzf $(TMP_DIR)/pcre.tgz -C $(TMP_DIR)
	mv $(TMP_DIR)/pcre-$(PCRE_RELEASE) $(BUILD_DIR)/pcre-source

$(BUILD_DIR)/openssl-source:
	$(WGET) -O $(TMP_DIR)/openssl.tgz http://www.openssl.org/source/openssl-$(OPENSSL_RELEASE).tar.gz
	$(TAR) xzf $(TMP_DIR)/openssl.tgz -C $(TMP_DIR)
	mv $(TMP_DIR)/openssl-$(OPENSSL_RELEASE) $(BUILD_DIR)/openssl-source
#	$(PATCH) -d $(BUILD_DIR)/openssl-source -p1 < ../patches/openssl/0001-makefile-correct-ldflags.patch
	

$(BUILD_DIR)/zlib-source:
	$(WGET) -O $(TMP_DIR)/zlib.tgz http://zlib.net/zlib-$(ZLIB_RELEASE).tar.gz
	$(TAR) xzf $(TMP_DIR)/zlib.tgz -C $(TMP_DIR)
	mv $(TMP_DIR)/zlib-$(ZLIB_RELEASE) $(BUILD_DIR)/zlib-source

$(BUILD_DIR)/bzip2-source:
	$(WGET) -O $(TMP_DIR)/bzip2.tgz http://www.bzip.org/1.0.6/bzip2-$(BZIP2_RELEASE).tar.gz
	$(TAR) xzf $(TMP_DIR)/bzip2.tgz -C $(TMP_DIR)
	mv $(TMP_DIR)/bzip2-$(BZIP2_RELEASE) $(BUILD_DIR)/bzip2-source
	$(PATCH) -d $(BUILD_DIR)/bzip2-source -p1 < ../patches/bzip2/0001-makefile-wrong-opts-for-solaris-ld.patch

$(BUILD_DIR)/rudder-sources.tar.bz2:
	$(WGET) -O $(BUILD_DIR)/rudder-sources.tar.bz2 http://www.rudder-project.org/archives/rudder-sources-${RUDDER_VERSION_TO_PACKAGE}.tar.bz2

$(BUILD_DIR)/rudder-sources: $(BUILD_DIR)/rudder-sources.tar.bz2
	$(TAR) -xjf $(BUILD_DIR)/rudder-sources.tar.bz2 -C $(BUILD_DIR)
	mv $(BUILD_DIR)/rudder-sources-$(RUDDER_VERSION_TO_PACKAGE)/ $(BUILD_DIR)/rudder-sources/

$(BUILD_DIR)/initial-promises: $(BUILD_DIR)/rudder-sources
	rm -rf $(BUILD_DIR)/initial-promises/
	cp -a $(BUILD_DIR)/rudder-sources/rudder-techniques/initial-promises/node-server/ $(BUILD_DIR)/initial-promises

$(BUILD_DIR)/fusioninventory-agent:
	#Original URL: http://search.cpan.org/CPAN/authors/id/G/GR/GROUSSE/FusionInventory-Agent-$(FUSION_RELEASE).tar.gz
	#$(WGET) -O $(TMP_DIR)/fusion.tgz http://cpan.metacpan.org/authors/id/G/GR/GROUSSE/FusionInventory-Agent-$(FUSION_RELEASE).tar.gz
	$(WGET) -O $(TMP_DIR)/fusion.tgz http://www.normation.com/tarball/FusionInventory-Agent-$(FUSION_RELEASE).tar.gz
	$(TAR) zxf $(TMP_DIR)/fusion.tgz -C $(TMP_DIR)
	mv $(TMP_DIR)/FusionInventory-Agent-$(FUSION_RELEASE) $(BUILD_DIR)/fusioninventory-agent
	$(PATCH) -d $(BUILD_DIR)/fusioninventory-agent -p1 < ../patches/fusioninventory/0001-4096-char-line-truncation.patch
	$(PATCH) -d $(BUILD_DIR)/fusioninventory-agent -p1 < ../patches/fusioninventory/0002-install-d-mkdir-p.patch
	$(PATCH) -d $(BUILD_DIR)/fusioninventory-agent -p1 < ../patches/fusioninventory/0003-unix-ps-etime-usage.patch
	$(PATCH) -d $(BUILD_DIR)/fusioninventory-agent -p1 < ../patches/fusioninventory/0004-aix-microcode-version-retrieval.patch
	# Fix a lsusb invocation that crashes some SLES machines
	$(FIND) $(BUILD_DIR)/fusioninventory-agent -iname "USB.pm" -exec rm "{}" \;

$(BUILD_DIR)/files: 
	mkdir $(BUILD_DIR)/files
	#Original URL: http://www.cpan.org/modules/by-module/App/App-cpanminus-1.0004.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/App-cpanminus-1.0004.tar.gz http://www.normation.com/tarball/App-cpanminus-1.0004.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/Archive/Archive-Extract-0.42.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/Archive-Extract-0.42.tar.gz http://www.normation.com/tarball/Archive-Extract-0.42.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/Compress/Compress-Raw-Bzip2-2.027.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/Compress-Raw-Bzip2-2.027.tar.gz http://www.normation.com/tarball/Compress-Raw-Bzip2-2.027.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/Compress/Compress-Raw-Zlib-2.027.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/Compress-Raw-Zlib-2.027.tar.gz http://www.normation.com/tarball/Compress-Raw-Zlib-2.027.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/Crypt/Crypt-SSLeay-0.57.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/Crypt-SSLeay-0.57.tar.gz http://www.normation.com/tarball/Crypt-SSLeay-0.57.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/Digest/Digest-MD5-2.39.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/Digest-MD5-2.39.tar.gz http://www.normation.com/tarball/Digest-MD5-2.39.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/HTML/HTML-Parser-3.65.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/HTML-Parser-3.65.tar.gz http://www.normation.com/tarball/HTML-Parser-3.65.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/HTML/HTML-Tagset-3.20.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/HTML-Tagset-3.20.tar.gz http://www.normation.com/tarball/HTML-Tagset-3.20.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/IO/IO-Compress-2.027.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/IO-Compress-2.027.tar.gz http://www.normation.com/tarball/IO-Compress-2.027.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/IO/IO-Socket-SSL-1.33.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/IO-Socket-SSL-1.33.tar.gz http://www.normation.com/tarball/IO-Socket-SSL-1.33.tar.gz
	#Original URL: http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/libwww-perl-5.836.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/libwww-perl-5.836.tar.gz http://www.normation.com/tarball/libwww-perl-5.836.tar.gz
	#Orignal URL: http://www.cpan.org/modules/by-module/Net/Net-IP-1.25.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/Net-IP-1.25.tar.gz http://www.normation.com/tarball/Net-IP-1.25.tar.gz
	#Original URL: http://www.cpan.org/src/5.0/perl-5.12.4.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/perl-5.12.4.tar.gz http://www.normation.com/tarball/perl-5.12.4.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/UNIVERSAL/UNIVERSAL-require-0.13.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/UNIVERSAL-require-0.13.tar.gz http://www.normation.com/tarball/UNIVERSAL-require-0.13.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/URI/URI-1.56.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/URI-1.56.tar.gz http://www.normation.com/tarball/URI-1.56.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/XML/XML-SAX-0.96.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/XML-SAX-0.96.tar.gz http://www.normation.com/tarball/XML-SAX-0.96.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/XML/XML-Simple-2.18.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/XML-Simple-2.18.tar.gz http://www.normation.com/tarball/XML-Simple-2.18.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/File/File-Which-1.09.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/File-Which-1.09.tar.gz http://www.normation.com/tarball/File-Which-1.09.tar.gz
	#Original URL: http://www.cpan.org/modules/by-module/XML/XML-TreePP-0.41.tar.gz
	$(WGET) -O $(BUILD_DIR)/files/XML-TreePP-0.41.tar.gz http://www.normation.com/tarball/XML-TreePP-0.41.tar.gz

$(BUILD_DIR)/rudder-agent.cron: $(BUILD_DIR)/rudder-sources
	cp $(BUILD_DIR)/rudder-sources/rudder-techniques/techniques/system/common/1.0/rudder_agent_community_cron.st $(BUILD_DIR)/rudder-agent.cron
	# Set unexpanded variables of the cron file
	sed 's@\$${sys.workdir}@/var/rudder/cfengine-community@g' -i $(BUILD_DIR)/rudder-agent.cron
	sed 's@\$${g.rudder_base}@/opt/rudder@g' -i $(BUILD_DIR)/rudder-agent.cron
	sed  's@\\&\\&@\&\&@g' -i $(BUILD_DIR)/rudder-agent.cron
	sed  's@\\&1@\&1@g' -i $(BUILD_DIR)/rudder-agent.cron

localclean:
	rm -rf $(BUILD_DIR)/cfengine-source
	rm -rf $(BUILD_DIR)/tokyocabinet-source
	rm -rf $(BUILD_DIR)/initial-promises
	rm -rf $(BUILD_DIR)/detect_os.sh
	rm -rf $(BUILD_DIR)/fusioninventory-agent
	rm -rf $(BUILD_DIR)/files
	rm -rf $(BUILD_DIR)/rudder-sources
	rm -f $(BUILD_DIR)/rudder-agent.cron

veryclean:
	rm -f $(BUILD_DIR)/rudder-sources.tar.bz2

.PHONY: localclean localdepends veryclean
