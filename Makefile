PROLOG = swipl
INSTALL=/usr/bin/install -m 0644
PLBASE = $(shell eval `$(PROLOG) --dump-runtime-variables` && echo $$PLBASE)
DEST = $(PLBASE)/library
SRC = src/yamltiny.pl

test:
	$(PROLOG) -s src/tests -g run_tests -t halt
	
install:
	$(INSTALL) $(SRC) $(DEST)

uninstall:
	rm $(DEST)/yamltiny.pl

.PHONY: test install uninstall
