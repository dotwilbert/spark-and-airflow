ca-certificates dbus fontconfig-config fonts-dejavu-core java-common krb5-locales libapparmor1 libavahi-client3 libavahi-common-data libavahi-common3 libbsd0 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libfreetype6 libgssapi-krb5-2 libjpeg62-turbo libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblcms2-2 libnspr4 libnss3 libpcsclite1 libpng16-16 libsqlite3-0 libssl1.1 libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxext6 libxi6 libxrender1 libxtst6 lsb-base openssl sensible-utils ucf x11-common

openjdk-8-jre-headless
ca-certificates-java





export jinfo='/usr/lib/jvm/.java-1.8.0-openjdk-amd64.jinfo'; export sed_cmd='sed -i'; for f in $(awk '/^(hl|jre|jdk|plugin)/ {print $3}' ${jinfo}); do if [ ! -f "${f}" ]; then sed_cmd="${sed_cmd} -e \\#${f}#d"; fi; done; ${sed_cmd} ${jinfo}; unset jinfo; unset sed_cmd

```bash
export jinfo='/usr/lib/jvm/.java-1.8.0-openjdk-amd64.jinfo'; awk '/^(hl|jre|jdk|plugin)/ {print $2 " " $3}' ${jinfo} | sort -u | while read name location; do update-alternatives --install /usr/bin/${name} ${name} ${location} 1000; done; unset jinfo;
```