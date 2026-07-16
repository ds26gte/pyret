export MAKE_DIR = $(CURDIR)

poly_pm_files := $(shell grep -oP '[\w/.-]+\.html' index.ptree | sed 's/\.html$$/.poly.pm/')

.PHONY: all debug-examples debug-tests clean cleanglob

all:
	@if [ ! -f _glossary.rkt ] || [ -f .xref-changed ]; then \
		rm -f .xref-changed; \
		raco pollen render -f index.ptree; \
	else \
		stale=''; \
		for f in $(poly_pm_files); do \
			html="$${f%.poly.pm}.html"; \
			if [ ! -f "$$html" ] || [ "$$f" -nt "$$html" ]; then \
				stale="$$stale $$f"; \
			fi; \
		done; \
		if [ -n "$$stale" ]; then \
			for f in $$stale; do raco pollen render -f $$f || true; done; \
		fi; \
	fi
	racket make-globals.rkt

debug-examples:
	./debug-examples.sh

debug-tests:
	./debug-tests.sh

clean:
	find . -name compiled -type d -exec rm -fr {} \; || true
	find [^pms]* -name \*.html -delete || true
	find pl* -name \*.html -delete || true
	find . -name .image\*.png -delete || true
	find . -name .examples\*.arr -delete || true
	make cleanglob

cleanglob:
	rm -f _glossary.rkt _xref.rkt globals.rkt .xref-changed
	find . -name '._glossary_*.rkt' -delete || true
	find . -name '._xref_*.rkt' -delete || true
