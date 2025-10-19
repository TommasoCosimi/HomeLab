FROM sharelatex/sharelatex:latest

# Upgrade TeXLive
RUN tlmgr update --self
RUN tlmgr update --all
RUN tlmgr install scheme-full