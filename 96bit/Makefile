ifeq ($(CONFIG),debug)
	OPT = - Wall -O0 -g
else
	OPT =
endif

all: arxtoolbox

arxtoolbox: arxtoolbox.cpp Makefile
	g++ arxtoolbox.cpp -framework OpenCL -oARXTOOLBOX $(OPT)

clean:
	rm -f arxtoolbox
	
#  LINUX -lOpenCL
#  OSX -framework OpenCL
