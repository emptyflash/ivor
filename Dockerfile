FROM dgellow/idris:latest

WORKDIR /root/ivor/

RUN git clone https://github.com/ziman/lightyear.git \
  && cd lightyear \
  && idris --install lightyear.ipkg \
  && cd .. \
  && rm -rf lightyear \
  && git clone https://github.com/emptyflash/tomladris.git \
  && cd tomladris \
  && idris --install tomladris.ipkg \
  && cd .. \
  && rm -rf tomladris \
  && git clone https://github.com/emptyflash/idris-ipkg-parser \
  && cd idris-ipkg-parser \
  && idris --install ipkgparser.ipkg \
  && rm -rf idris-ipkg-parser

COPY . .

RUN idris --build ivor.ipkg

CMD /bin/bash
