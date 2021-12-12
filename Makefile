.PHONY: all
all:
	$(MAKE) -C lib/github.com/melsman/mlkit-postgresql all

.PHONY: test
test:
	$(MAKE) -C lib/github.com/melsman/mlkit-postgresql test

.PHONY: clean
clean:
	$(MAKE) -C lib/github.com/melsman/mlkit-postgresql clean
	rm -rf MLB *~ .*~
