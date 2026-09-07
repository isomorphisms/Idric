action: wrap the connected socket in a BIO and transfer it to SSL
symbols: BIO_new, BIO_s_socket, BIO_set_fd, SSL_set_bio
source: https://github.com/openssl/openssl/blob/openssl-4.0.2/demos/guide/tls-client-block.c
