DESTDIR     =
PREFIX      = /usr/local
EXEC_PREFIX = $(PREFIX)
BINDIR      = $(EXEC_PREFIX:/=)/bin

EXEMODE ?= 0755
INSMODE ?= 0644
DIRMODE ?= 0755

INSTALL ?= install

RM      ?= rm
RMF      = $(RM) -f

DODIR    = $(INSTALL) -d -m $(DIRMODE)
DOEXE    = $(INSTALL) -D -m $(EXEMODE)
DOINS    = $(INSTALL) -D -m $(INSMODE)

PHONY =

PHONY += all
all:

PHONY += install
install:
	$(DOEXE) names.pl $(DESTDIR)$(BINDIR)/names

PHONY += readme
readme: README.txt

README.txt: names.pl
	perl ./names.pl -h > $(@).make_tmp
	mv -f -- $(@).make_tmp $(@)


.PHONY: $(PHONY)
