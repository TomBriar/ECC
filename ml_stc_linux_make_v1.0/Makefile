CC =       g++
CXX =      g++
CXXFLAGS = -I ../include
VPATH =    ../ml_stc_src

all: r g
targets: example1_ml_stc example2_ml_stc
example1_ml_stc: example1_ml_stc.o stc_embed_c.o stc_extract_c.o common.o stc_ml_c.o
example2_ml_stc: example2_ml_stc.o stc_embed_c.o stc_extract_c.o common.o stc_ml_c.o

r:
	make -f ../Makefile -C release "CPPFLAGS=-O3" "LDFLAGS=-O3" targets
g:
	make -f ../Makefile -C debug "CPPFLAGS=-ggdb" "LDFLAGS=-ggdb" targets
clean:
	rm -f debug/* release/*
# use this configuration for valgrind tests
valgrind: g
	valgrind --leak-check=full ./debug/example2_ml_stc
