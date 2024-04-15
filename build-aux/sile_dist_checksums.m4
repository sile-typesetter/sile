AC_DEFUN_ONCE([SILE_DIST_CHECKSUMS], [

        QUE_DIST_CHECKSUMS

        AM_COND_IF([DEVELOPER_MODE], [

                AX_ADD_AM_MACRO([dnl
checksum_dist += \
	; \$(SHA256SUM) sile-\$(VERSION).pdf |\
		\$(TEE) -a \$(distdir).sha256.txt
])dnl

        ])
])

