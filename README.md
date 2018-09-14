# nginx-tls1.3
 Use docker to quickly build a nginx image that supports TLSv1.3 draft 23, 26, 28, final


# OVERVIEW


Nginx can only use a certain version of tls1.3, such as 23, 26, 28, final.

In fact, many browsers currently use only one version of the tls1.3 beta.

So it is very necessary to use nginx to support multiple versions of the patch.

Many thanks to "hakasenyang" for creating a nginx patch that supports multiple versions of tls1.3.

The project I created was just using the "hakasenyang" patch to quickly build a docker image.

Hakasenyang's nginx patch URL is https://github.com/hakasenyang/openssl-patch
