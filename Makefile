help:
	@echo "usage: make ADDR=<email_address_without_domain>"
	@echo ""
	@echo "stages:"
	@echo "  gen_ca 		Create private Certification Authority"
	@echo "  gen_email_cert  	Create Self-signed email certification (format: PEM)"
	@echo "  export_p12 		Export .p12 format for use in S/MIME applications"
	@echo ""


# ----------------------------------------------------------------------------
# -- Certificate Authority Generation
# ----------------------------------------------------------------------------

ca.key:
	@echo "-notice- Generation CA key..."
	openssl genrsa \
	    -des3 \
	    -out $@ \
	    4096
	chmod 600 $@

ca.cert: ca.key
	@echo "-notice- Generation CA certification..."
	openssl req -new \
		    -x509 \
		    -days 365 \
		    -key $< \
		    -out $@
	chmod 600 $@

gen_ca: ca.cert

# ----------------------------------------------------------------------------
# -- Email Certificate Generation
# ----------------------------------------------------------------------------

$(ADDR).key: ca.cert
	@echo "-notice- Generation email key..."
	@[ -n "$(ADDR)" ] || ( echo "-error-  E-mail Address Name was not specified" 1>&2; exit 1 )
	openssl genrsa \
		    -des3 \
		    -out $@ \
		    4096
	chmod 600 $@

$(ADDR).csr: $(ADDR).key
	@echo "-notice- Generation email signature..."
	@[ -n "$(ADDR)" ] || ( echo "-error-  E-mail Address Name was not specified" 1>&2; exit 1 )
	openssl req -new \
		    -key $< \
		    -out $@
	chmod 600 $@

$(ADDR).cert: $(ADDR).csr
	@echo "-notice- Generation email certificate..."
	@[ -n "$(ADDR)" ] || ( echo "-error-  E-mail Address Name was not specified" 1>&2; exit 1 )
	openssl x509 -req \
		    -days 365 \
		    -CA ca.cert \
		    -CAkey ca.key \
		    -set_serial 1 \
		    -setalias "$(ADDR)'s email certificate" \
		    -addtrust emailProtection \
		    -addreject clientAuth \
		    -addreject serverAuth \
		    -trustout \
		    -in $< \
		    -out $@
	chmod 600 $@

gen_email_cert: $(ADDR).cert

# ----------------------------------------------------------------------------
# -- Export to formats
# ----------------------------------------------------------------------------

$(ADDR).p12: $(ADDR).cert
	@echo "-notice- Exporting to .p12 format..."
	@[ -n "$(ADDR)" ] || ( echo "-error-  E-mail Address Name was not specified" 1>&2; exit 1 )
	openssl pkcs12 -export \
		    -in $(ADDR).cert \
		    -inkey $(ADDR).key \
		    -out $(ADDR).p12
	chmod 600 $@

export_p12: $(ADDR).p12

# ----------------------------------------------------------------------------

all: export_p12

clean:
	@[ -n "$(ADDR)" ] || ( echo "-error-  E-mail Address Name was not specified" 1>&2; exit 1 )
	rm -f ca.* $(ADDR).*
