FROM dgellow/idris:latest

WORKDIR /root/ivor/

RUN git clone https://github.com/ziman/lightyear.git \
  && cd lightyear \
  && git checkout dbcd847ed7a9e62fa0b502b3d89cca43a96f256c \
  && idris --install lightyear.ipkg \
  && cd .. \
  && rm -rf lightyear \
  && git clone https://github.com/emptyflash/tomladris.git \
  && cd tomladris \
  && git checkout ec324128ebe8b446e84d8be60b0ed085d07fd36d \
  && idris --install tomladris.ipkg \
  && cd .. \
  && rm -rf tomladris \
  && git clone https://github.com/emptyflash/idris-ipkg-parser \
  && cd idris-ipkg-parser \
  && git checkout 35cc2f54d4f3b3710f637d0a8c897bfbb32fe183 \
  && idris --install ipkgparser.ipkg \
  && rm -rf idris-ipkg-parser

COPY . .

RUN idris --build ivor.ipkg

CMD /bin/bash
