
gen_cert_authority_key:
	openssl genrsa 4096 \
		    -des3 \
		    -out ca.key

gen_cert_authority_cert: ca.key
	openssl req -new \
		    -x509 \
		    -days 365 \
		    -key ca.key \
		    -out ca.cert

gen_ca: ca.cert

gen_email_key: ca.cert
	openssl genrsa 4096 \
		    -des3 \
		    -out ${ADDR}.key

gen_email_csr: ${ADDR}.key
	openssl req -new \
		    -key ${ADDR}.key \
		    -out ${ADDR}.csr


sign_email_cert: ${ADDR}.csr
	openssl x509 -req \
		    -days 365 \
		    -in ${ADDR}.csr \
		    -CA ca.cert \
		    -CAkey ca.key \
		    -set_serial 1 \
		    -out ${ADDR}.cert \
		    -setalias "${ADDR}'s email certificate" \
		    -addtrust emailProtection \
		    -ADDReject clientAuth \
		    -ADDReject serverAuth \
		    -trustout

gen_email_cert: ${ADDR}.cert

export_p12:
	openssl pkcs12 -export \
		    -in ${ADDR}.cert \
		    -inkey ${ADDR}.key \
		    -out ${ADDR}.p12

all: export_p12

help: 
	@echo "usage: make ADDR=<email_address_without_domain>"
	@echo ""
	@echo "stages:"
	@echo "  gen_ca 		Create private Certification Authority"
	@echo "  gen_email_cert  	Create Self-signed email certification (format: PEM)"
	@echo "  export_p12 		Export .p12 format for use in S/MIME applications"
	@echo ""

