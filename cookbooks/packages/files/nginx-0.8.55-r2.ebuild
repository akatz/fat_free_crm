# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/nginx/nginx-0.7.62.ebuild,v 1.3 2009/09/18 19:22:29 keytoaster Exp $

EAPI=1

inherit eutils flag-o-matic perl-module ssl-cert toolchain-funcs

ACCEPTLANGUAGE_VER="nginx_accept_language_module-2009081001"
HEADERSMORE_VER="nginx_headers_more_module-v0.14rc1"
PASSENGER_VER="passenger-3.0.8"
PUSH_VER="nginx_http_push_module-0.692"
REDIS2_VER="redis2_nginx_module-v0.06"
UPLOAD_VER="nginx_upload_module-2.2.0"
UPLOADPROGRESS_VER="nginx_uploadprogress_module-0.8.2"

DESCRIPTION="Robust, small and high performance http and reverse proxy server"

HOMEPAGE="http://nginx.net/"
SRC_URI="http://sysoev.ru/nginx/${P}.tar.gz
	acceptlanguage? ( http://distfiles.engineyard.com/${ACCEPTLANGUAGE_VER}.tar.gz )
	headersmore? ( http://distfiles.engineyard.com/${HEADERSMORE_VER}.tar.bz2 )
	passenger? ( mirror://rubyforge/passenger/${PASSENGER_VER}.tar.gz
		http://distfiles.engineyard.com/${PASSENGER_VER}.tar.gz
		mirror://rubyforge/rake/rake-0.8.3.tgz
		http://distfiles.engineyard.com/rake-0.8.3.tgz )
	push? ( http://distfiles.engineyard.com/${PUSH_VER}.tar.gz )
	redis2? ( http://distfiles.engineyard.com/${REDIS2_VER}.tar.gz )
	upload? ( http://distfiles.engineyard.com/${UPLOAD_VER}.tar.gz
		http://www.grid.net.ru/nginx/download/${UPLOAD_VER}.tar.gz )
	uploadprogress? ( http://distfiles.engineyard.com/${UPLOADPROGRESS_VER}.tar.bz2 )"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="addition debug fastcgi flv imap pcre perl random-index ssl status sub webdav zlib acceptlanguage accesskey +geoip google_perftools +gzip_static headersmore lvssilence +passenger push readcookies +redis2 upload uploadprogress imagefilter"

DEPEND="dev-lang/perl
	pcre? ( >=dev-libs/libpcre-4.2 )
	ssl? ( dev-libs/openssl )
	zlib? ( sys-libs/zlib )
	perl? ( >=dev-lang/perl-5.8 )
	geoip? ( dev-libs/geoip )
	google_perftools? ( dev-util/google-perftools )
	passenger? ( dev-ruby/rubygems )
	media-libs/gd"

pkg_setup() {
	ebegin "Creating nginx user and group"
	enewgroup ${PN}
	enewuser ${PN} -1 -1 -1 ${PN}
	eend ${?}
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -i 's/ make/ \\$(MAKE)/' auto/lib/perl/make || die

	epatch "${FILESDIR}"/${PN}-0.7.65-add-start_time-variable.patch

	use lvssilence && epatch "${FILESDIR}"/${PN}-0.7.65-lvs_silence.patch

	if use passenger ; then
		use debug && append-cxxflags -DPASSENGER_DEBUG
		cd "${WORKDIR}/${PASSENGER_VER}"
		echo "${WORKDIR}/${PASSENGER_VER}"
		echo `pwd`
		epatch "${FILESDIR}"/${PN}-passenger3-add-basic-PATH-to-spawn-server.patch \
			"${FILESDIR}"/${PN}-passenger3-compile-flags.patch \
			"${FILESDIR}"/${PN}-passenger3-install-paths.patch \
			"${FILESDIR}"/${PN}-passenger3-configurable-backlog.patch \
			"${FILESDIR}"/${PN}-passenger3-fix-null-host-segv.patch
		cd "${S}"
	fi
}

src_compile() {
	local myconf

# threads support is broken atm.
#	if use threads; then
#		einfo
#		ewarn "threads support is experimental at the moment"
#		ewarn "do not use it on production systems - you've been warned"
#		einfo
#		myconf="${myconf} --with-threads"
#	fi

	use addition && myconf="${myconf} --with-http_addition_module"
	use fastcgi  || myconf="${myconf} --without-http_fastcgi_module"
	use fastcgi  && myconf="${myconf} --with-http_realip_module"
	use flv      && myconf="${myconf} --with-http_flv_module"
	use zlib     || myconf="${myconf} --without-http_gzip_module"
	use pcre     || myconf="${myconf} --without-pcre --without-http_rewrite_module"
	use debug    && myconf="${myconf} --with-debug"
	use ssl      && myconf="${myconf} --with-http_ssl_module"
	use imap     && myconf="${myconf} --with-imap"
	use perl     && myconf="${myconf} --with-http_perl_module"
	use status   && myconf="${myconf} --with-http_stub_status_module"
	use webdav   && myconf="${myconf} --with-http_dav_module"
	use sub      && myconf="${myconf} --with-http_sub_module"
	use random-index        && myconf="${myconf} --with-http_random_index_module"

	use geoip    && myconf="${myconf} --with-http_geoip_module"
	use push     && myconf="${myconf} --add-module=${WORKDIR}/${PUSH_VER}"
	use redis2   && myconf="${myconf} --add-module=${WORKDIR}/${REDIS2_VER}"
	use upload   && myconf="${myconf} --add-module=${WORKDIR}/${UPLOAD_VER}"
	use acceptlanguage      && myconf="${myconf} --add-module=${WORKDIR}/${ACCEPTLANGUAGE_VER}"
	use accesskey           && myconf="${myconf} --add-module=${FILESDIR}/${PN}-accesskey-2.0.3"
	use google_perftools    && myconf="${myconf} --with-google_perftools_module"
	use gzip_static         && myconf="${myconf} --with-http_gzip_static_module"
	use headersmore         && myconf="${myconf} --add-module=${WORKDIR}/${HEADERSMORE_VER}"
	use readcookies         && myconf="${myconf} --add-module=${FILESDIR}/mod-read-cookies-0.1"
	use uploadprogress      && myconf="${myconf} --add-module=${WORKDIR}/${UPLOADPROGRESS_VER}"

	if use passenger ; then
		myconf="${myconf} --add-module=${WORKDIR}/${PASSENGER_VER}/ext/nginx"
		export RUBYLIB="${WORKDIR}/rake-0.8.3/lib"
		export PATH="${WORKDIR}/rake-0.8.3/bin:${PATH}"
	fi

	if use imagefilter ; then
		myconf="${myconf} --with-http_image_filter_module"
	fi

	tc-export CC
	./configure \
		--prefix=/usr \
		--conf-path=/etc/${PN}/${PN}.conf \
		--http-log-path=/var/log/${PN}/access_log \
		--error-log-path=/var/log/${PN}/error_log \
		--pid-path=/var/run/${PN}.pid \
		--http-client-body-temp-path=/var/tmp/${PN}/client \
		--http-proxy-temp-path=/var/tmp/${PN}/proxy \
		--http-fastcgi-temp-path=/var/tmp/${PN}/fastcgi \
		--with-md5-asm --with-md5=/usr/include \
		--with-sha1-asm --with-sha1=/usr/include \
		${myconf} || die "configure failed"

	emake LINK="${CC} ${LDFLAGS}" OTHERLDFLAGS="${LDFLAGS}" || die "failed to compile"
}

src_install() {
	keepdir /var/log/${PN} /var/tmp/${PN}/{client,proxy,fastcgi}

	dosbin objs/nginx
	cp "${FILESDIR}"/nginx-r1 "${T}"/nginx
	doinitd "${T}"/nginx

	if use passenger ; then
		cp "${FILESDIR}"/nginx-passenger.conf conf/nginx.conf
	else
		cp "${FILESDIR}"/nginx.conf-r4 conf/nginx.conf
	fi

	dodir /etc/${PN}
	insinto /etc/${PN}
	doins conf/*

	dodoc CHANGES{,.ru} README

	if use perl ; then
		cd "${S}"/objs/src/http/modules/perl/
		einstall DESTDIR="${D}"|| die "failed to install perl stuff"
		fixlocalpod
	fi

	if use passenger ; then
		local P_LIBDIR="/usr/libexec/passenger"
		local P_UTLIBDIR="/usr/$(get_libdir)"
		local P_SHAREDIR="/usr/share/passenger"

		cd "${WORKDIR}/${PASSENGER_VER}"

		dobin bin/passenger{,-config}
		rm -f bin/passenger-install* bin/passenger{,-config}
		dosbin bin/*
		insinto "${P_UTLIBDIR}"
		doins -r lib/*

		exeinto "${P_LIBDIR}"/agents/nginx
		doexe agents/nginx/Passenger*
		exeinto "${P_LIBDIR}"/agents
		doexe agents/Passenger*
		exeinto "${P_LIBDIR}"/bin
		doexe helper-scripts/passenger-spawn-server helper-scripts/prespawn
		dosym ../../lib "${P_LIBDIR}"/lib

		insinto "${P_SHAREDIR}"
		doins resources/mime.types
		insinto "${P_SHAREDIR}"/source/ext/ruby
		doins ext/ruby/*
		dodir "${P_SHAREDIR}"/plugins

		doman man/*
		dodir "/usr/share/doc/${PF}/${PASSENGER_VER}/doc"
		docinto "${PASSENGER_VER}"
		dodoc DEVELOPERS.TXT INSTALL LICENSE NEWS README
		insinto "/usr/share/doc/${PF}/${PASSENGER_VER}/doc"
		doins -r doc/*
	fi
}

pkg_postinst() {
	if use ssl ; then
		if [ ! -f "${ROOT}"/etc/ssl/${PN}/${PN}.key ]; then
			install_cert /etc/ssl/${PN}/${PN}
			chown ${PN}:${PN} "${ROOT}"/etc/ssl/${PN}/${PN}.{crt,csr,key,pem}
		fi
	fi
}
