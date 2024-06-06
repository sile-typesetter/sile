AC_DEFUN([QUE_SUBST_MAN_DATE], [
        ax_date_fmt="m4_default($1,%d %B %Y)"
        ax_src_file="m4_default($2,*.1.in)"
        AS_IF([test ! -e .gitignore],
                [
                        QUE_PROGVAR([date])
                        AX_BUILD_DATE_EPOCH(MAN_DATE, "$ax_date_fmt")
                ], [
                        QUE_PROGVAR([git])
                        MAN_DATE=$($GIT log -1 --format="%cd" --date=format:"$ax_date_fmt" -- $ax_src_file)
                ])
        AC_SUBST([MAN_DATE])
])
