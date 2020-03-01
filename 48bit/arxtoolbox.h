#ifndef __LSARXCL__arxtoolbox__
#define __LSARXCL__arxtoolbox__

#include <stdio.h>

//Include source files for OPENCL
#ifdef __APPLE__
#include <OpenCL/cl.h>
#else
#include <CL/cl.h>
#endif

namespace arxtoolbox_lib
{
    class Arxtoolbox
    {
    public:
        Arxtoolbox();      //contructor
        void generateKernel();
        void displayInfo();
        void runCipher();
        void checkErr(cl_int err, const char * name);
        void printBinary(cl_long n, cl_long blocksize);
        void saveRoundResultsComboToFile(cl_ulong *arrayResults, const char* filename, cl_ulong nrRounds, int typeOfoutput);
        double get_wall_time();
        double get_cpu_time();
        virtual ~Arxtoolbox();  // Destructor
        
        private:
        
        
        
    };// END CLASS
    
};//END NAMESPACE

#endif /* defined(__LSARXCL__computation__) */
