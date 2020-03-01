ifeq ($(CONFIG),debug)
	OPT = - Wall -O0 -g
else
	OPT =
endif

all: translation

translation: translation.cpp Makefile
	g++ translation.cpp -framework OpenCL -oARXTOOLBOX $(OPT)

clean:
	rm -f translation

#  LINUX -lOpenCL
#  OSX -framework OpenCL