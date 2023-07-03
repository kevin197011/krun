# Copyright (c) 2023 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# lastet_version=$(curl -s https://github.com/cloudflare/cfssl/tags | perl -ne 'print $1."\n" if /(v\d+\.\d+\.\d+)/' | uniq | head -n 1)

@pkgs = qw(
    https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
    https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
);

foreach( @pkgs ) {
    if ($_ =~ /.*\/(.*)\_.*/) {
        unless ( -e "/usr/local/bin/$1" ) {
            print "Download $1 ...\n";
            system "curl -L -s -o /usr/local/bin/$1 '$_' -H 'authority: pkg.cfssl.org'";
            chmod 0755, "/usr/local/bin/$1";
            print "Download $1 sucessed!\n";
        }
    }
}

my $ca_csr_json = <<EOF;
{
    "CN": "*",
    "hosts": [
        "*"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "US",
            "L": "CA",
            "ST": "SF"
        }
    ]
}
EOF

open(DES,'>', 'ca-csr.json') or die $!;
print(DES $ca_csr_json);
close(DES);

system "cfssl gencert -initca ca-csr.json  | cfssljson -bare server"
