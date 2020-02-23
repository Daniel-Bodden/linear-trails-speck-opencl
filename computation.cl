/*  Author. D.Bodden, 2015
*   used for publication : CRYPTO - Linear Cryptanalysis of Reduced-Round Speck with OPENCL
*    
*/ 


/* KERNEL FILE
 *
 *   SUPPORT FUNCTIONS :
 *   - inline int CountTwoConsecutiveBitsSets(int16  n, int localnrLoops)
 *   - inline int countOneBits(int k)
 *   - inline bool checkTwoConsecutiveBits(int16  mask, int localnrLoops)
 *   - inline int hammingWeight(int16  mask)
 *   - inline int16 rotate_left16(int16 value, int number)
 *   - inline int16 rotate_right16(int16 value, int number)
 *   - inline bool checkUpperBound(int bias)
 *
 *   KERNEL FUNCTION
 *
 *
 *
 */


//===============================================================
//FUNCTION RETURNS NUMBER OF PAIRS OF 2 BITS
inline int countTwoConsecutiveBitsSets(ulong n, int wordlength)
{
    //local variables
    int prev = 0;				// =1 if previous bit was =1 ; else = 0
    int current = 0;			// =1 if current bit is =0 ; else = 0
    int pairs = 0;				// the number of pairs in mask
    int count = 0;				// ...
    int temp = 0;				// ...
    
    for (int i = 0; i < wordlength; i++) //check
    {
        
        if (current == 1) {
            prev = 1;
        } else {
            //reset value
            prev = 0;
        }
        
        temp = n & 1;
        
        if (temp == 1)
        {
            current = 1;
            count++;
        }
        else
        {
            current = 0;
        }
        /*
         printf(" current = %x", current);
         printf("  prev = %x", prev);
         printf("  remain= %x", count%2);
         printf("  count= %x", count);
         */
        
        if (prev == 1 && current == 1)
        {
            //reset value
            count = 0;
        }
        
        if (prev == 1 && current == 1 && count % 2 == 0)
        {
            pairs++;
            //reset values
            count = 0;
            prev = 0;
            current = 0;
        }
        //printf("   number of sets= %x\n", sets);
        
        n >>= 1;
        /*
         printf(" next round mask in binary ");
         printBinary(n);
         printf("\n");
         */
    }
    return pairs;
}
//===============================================================


//===============================================================
//FUNCTION RETURNS THE NUMBER OF BITS IN A MASK
inline int countOneBits(ulong k)
{
    int bits = 0;
    int i = __builtin_popcountll(k); // returns number of one bits
    bits = i;
    
    return bits;
}
//===============================================================

//===============================================================
// CHECK FOR IF UPPERBOUND HAS BEEN MET - based on ...
inline bool checkUpperBound(int bias, int blocksize)
{
    bool checkUpperLimit = false;
    
    if (bias > ((blocksize/2)-1)) //fixed - see paper .....
    {
        checkUpperLimit =true;
    }
    
    return checkUpperLimit;
}
//===============================================================


//===============================================================
//CALCULATE HAMMINGWEIGHT
inline int hammingWeight(ulong mask)
{
    int value = 0;
    value = (countOneBits(mask)) / 2;
    
    return value;
};
//===============================================================


//===============================================================
//FUNCTION CHECKS IF MASK CONSIST EXCLUSIVELY OF CONSECUTIVE BITS
inline bool checkTwoConsecutiveBits(ulong mask, int wordlength)
{
    int n; //keep count number of 1 bits in mask
    bool check = false;
    
    n = countOneBits(mask); //count 1 bits
    //printf("number of 1 bits  %d", n);
    
    if (n == 0)
    {
        //all are even.
        check = true;
    }
    
    
    else if (n % 2 == 0)
    {
        //check if consecutive
        if (countTwoConsecutiveBitsSets(mask, wordlength) == (n / 2)) {
            // bits are consecutive
            check = true;
        }
        else
        {
            //not consecutive
            check = false;
        }
    }
    
    
    return check;
}
//===============================================================



//===============================================================

//CIRCULAR SHIFT FUNCTION LEFT
inline ulong rotate_left(ulong value, int number, int wordlength)
{
    return ((((value & 0xffff) << (number)) | ((value & 0xffff) >> ((wordlength) - number))) & 0xffff);;
};
//===============================================================



//===============================================================
//CIRECULAR SHIFT FUNCTION RIGHT
inline ulong rotate_right(ulong value, int number, int wordlength)
{
    
    return ((((value&0xffff) >> (number)) | ((value&0xffff) << ((wordlength) - number))) & 0xffff); ;
};
//===============================================================


//===============================================================
inline void cipherRoundFunction(
                                __private const ulong inMaskX,
				                __private const ulong inMaskY,
                                __private const uint blocksize,
                                __private const ulong nrRounds,
                                __global ulong *outputBestRoundCombo,               //OUTPUT - write the best round combo (forward, backward)
                                __global ulong *outMasksBestRoundBackward,          //OUTPUT - write the best round backward
                                __global ulong *outMasksOverallBackward,            //OUTPUT - write the best overall result backward
                                __global ulong *outMasksBestRoundForward,           //OUTPUT - write the best round forward
                                __global ulong *outMasksOverallForward              //OUTPUT - write the best overall result forward
                                )
{

		 //todo 


        //Create local result tables
        __private ulong roundResultBackward[22][6];
        __private ulong roundResultForward[22][6];
        
        //initalize
        for (__private int round = 0; round < 22; round++)
        {
            roundResultBackward[round][5] = 99 ;
            roundResultForward[round][5] = 99 ;
        }
        
        //==============================FORWARD================================================
        //Variables for round function
        __private ulong inputMaskX = 0x0;
        __private ulong inputMaskY = 0x0;
        __private ulong iMaskXRound = 0x0;
        __private ulong iMaskYRound = 0x0;
        __private uint lshift = 2;
        __private uint rshift = 7;
        __private bool xorCheck;
        __private ulong count = 0;
        __private ulong wordlength= blocksize/2;  //divided by the number of words in the round function
        __private ulong maskX = inMaskX;
        __private ulong maskY = inMaskY ;
        
        //==============================FORWARD================================================
        //LOOP OVER ALL POSSIBLE ROUNDS
        for(uint round = 1; round<=22;round++) // SPECK HAS 22 ROUNDS
        {
            //---------------------------------------------------------------------
            //KEEP INITIAL MASK
            if(round==1)
            {
                iMaskXRound = maskX;
                iMaskYRound = maskY;
            }
            //----------------------------------------------------------------------------------
            //CALL ROUND FUNCTION
            //Keep input mask
            inputMaskX = 0x0;
            inputMaskY = 0x0;
            inputMaskX = maskX;
            inputMaskY = maskY;
            
            //---------------------------------------------------------------------------------
            //CONDITIONS =============================
            xorCheck = checkTwoConsecutiveBits((rotate_right(inputMaskX,rshift,wordlength)),wordlength);
            
            //CALL ROUND FUNCTION ====================
            maskX = ((rotate_right(inputMaskX, rshift,wordlength)) ^ (rotate_left(( rotate_right(inputMaskX, rshift,wordlength)  ^ inputMaskY ), lshift,wordlength)));
            maskY = (rotate_left((rotate_right(inputMaskX, rshift,wordlength)  ^ inputMaskY ), lshift, wordlength));
            
            //------------------------------------------------------------------------------------
            //STOP CONDITIONS
            //CHECK XOR
            if(xorCheck==false)
            {
                //STOP CURRENT ITERATION
                break;
            }
            //Check UpperBoundLimit
	    /*
            else if (checkUpperBound(count + hammingWeight((rotate_right(inputMaskX,rshift,wordlength))),blocksize)==true)
            {
                //STOP CURRENT ITERATION
                break;
            }
	    */
            else
            {
                //Update BIAS COUNT ON ALL W-POSITIONS (transformed from non-linear to approx linear)
                count = count +  hammingWeight((rotate_right(inputMaskX,rshift,wordlength)));
                
                roundResultForward[round-1][0] = round;
                roundResultForward[round-1][1] = maskX;
                roundResultForward[round-1][2] = maskY;
                roundResultForward[round-1][3] = inputMaskX;
                roundResultForward[round-1][4] = inputMaskY;
                roundResultForward[round-1][5] = count;
                
                //GLOBAL CHECK BEST ROUND RESULTS
                /* OpenCL cannot deal with 2d arrays
                 * Round        (i-1)*6
                 * MaskX        ((i-1)*6) +1
                 * MaskY        ((i-1)*6) +2
                 * InputMaskX   ((i-1)*6) +3
                 * inputMaskY   ((i-1)*6) +4
                 * BIAS         ((i-1)*6) +5
                 */
                if(count < outMasksBestRoundForward[( (round-1)*6)+5]) //check against bias of current best for given ROUND
                {
                    outMasksBestRoundForward[(round-1)*6] = round;
                    outMasksBestRoundForward[((round-1)*6)+1] = maskX;
                    outMasksBestRoundForward[((round-1)*6)+2] = maskY;
                    outMasksBestRoundForward[((round-1)*6)+3] = inputMaskX;
                    outMasksBestRoundForward[((round-1)*6)+4] = inputMaskY;
                    outMasksBestRoundForward[((round-1)*6)+5] =  count;
                }
                //save best result
                if(round > outMasksOverallForward[0])
                {
                    outMasksOverallForward[0] = round;             //current round
                    outMasksOverallForward[1] = maskX; 			//inputmask X
                    outMasksOverallForward[2] = maskY;             //inputmask Y
                    outMasksOverallForward[3] = iMaskXRound;       //outputmask X at the start of round 1
                    outMasksOverallForward[4] = iMaskYRound;       //outputmask Y at the start of round 1
                    outMasksOverallForward[5] = count;              //BIAS
                }
                else if(round >= outMasksOverallForward[0] && count < outMasksOverallForward[5])
                {
                    outMasksOverallForward[0] = round;             //current round
                    outMasksOverallForward[1] = maskX; 			//inputmask X
                    outMasksOverallForward[2] = maskY;             //inputmask Y
                    outMasksOverallForward[3] = iMaskXRound;       //outputmask X at the start of round 1
                    outMasksOverallForward[4] = iMaskYRound;       //outputmask Y at the start of round 1
                    outMasksOverallForward[5] = count;              //BIAS
                }
            }// END ELSE
        }// END LOOP ROUND
        
        //==============================BACKWARD===============================================
        //=========Re-initialize
        
        //Variables for round function
        inputMaskX = 0x0;
        inputMaskY = 0x0;
        iMaskXRound = 0x0;
        iMaskYRound = 0x0;
        lshift = 7;
        rshift = 2;
        xorCheck = false;
        count = 0;
       // blocksize = 32;
        maskX =inMaskX;
        maskY = inMaskY ;
        
        //LOOP OVER ALL POSSIBLE ROUNDS
        for(__private uint round = 1; round <= 22 ;round++) // SPECK HAS 22 ROUNDS
        {
            //KEEP INITIAL MASK  =====================
            if(round==1)
            {
                iMaskXRound = maskX;
                iMaskYRound = maskY;
            }
            
            //Keep input mask   ====================
            inputMaskX = 0x0;
            inputMaskY = 0x0;
            inputMaskX = maskX;
            inputMaskY = maskY;
            
            //CONDITIONS =============================
            xorCheck = checkTwoConsecutiveBits((inputMaskX ^ inputMaskY), wordlength);
            
            //CALL ROUND FUNCTION ====================
            maskX = rotate_left((inputMaskX ^  inputMaskY),lshift,wordlength);
            maskY = (inputMaskX ^ inputMaskY) ^ (rotate_right( maskY , rshift,wordlength));
            
            ///UPDATE ROUND WITH CHECK ON CONDITIONS  ============================================================================
            if(xorCheck==false)
            {
                //STOP CURRENT ITERATION
                break;
            }
            //Check UpperBoundLimit
            /*
	    else if (checkUpperBound(count + hammingWeight((inputMaskX ^ inputMaskY)), blocksize)==true)
            {
                //STOP CURRENT ITERATION
                break;
            }
	    */
            else
            {
                //Update BIAS COUNT ON ALL W-POSITIONS (transformed from non-linear to approx linear)
                count = count + hammingWeight((inputMaskX ^ inputMaskY));
                
                //Save local round results
                
                roundResultBackward[round-1][0] = round;
                roundResultBackward[round-1][1] = maskX;
                roundResultBackward[round-1][2] = maskY;
                roundResultBackward[round-1][3] = inputMaskX;
                roundResultBackward[round-1][4] = inputMaskY;
                roundResultBackward[round-1][5] = count;
                
                //CHECK BEST ROUND RESULTS
                /* OpenCL cannot deal with 2d arrays
                 * Round        (i-1)*6
                 * MaskX        ((i-1)*6) +1
                 * MaskY        ((i-1)*6) +2
                 * InputMaskX   ((i-1)*6) +3
                 * inputMaskY   ((i-1)*6) +4
                 * BIAS         ((i-1)*6) +5
                 */
                
                if(count < outMasksBestRoundBackward[( (round-1)*6)+5]) //check against bias of current best for given ROUND
                {
                    outMasksBestRoundBackward[(round-1)*6] = round;
                    outMasksBestRoundBackward[((round-1)*6)+1] = maskX;
                    outMasksBestRoundBackward[((round-1)*6)+2] = maskY;
                    outMasksBestRoundBackward[((round-1)*6)+3] = inputMaskX;
                    outMasksBestRoundBackward[((round-1)*6)+4] = inputMaskY;
                    outMasksBestRoundBackward[((round-1)*6)+5] =  count;
                }
                
                //save best result
                if(round > outMasksOverallBackward[0])
                {
                    outMasksOverallBackward[0] = round;             //current round
                    outMasksOverallBackward[1] = maskX; 			//inputmask X
                    outMasksOverallBackward[2] = maskY;             //inputmask Y
                    outMasksOverallBackward[3] = iMaskXRound;       //outputmask X at the start of round 1
                    outMasksOverallBackward[4] = iMaskYRound;       //outputmask Y at the start of round 1
                    outMasksOverallBackward[5]= count;              //BIAS
                }
                else if(round >= outMasksOverallBackward[0] && count < outMasksOverallBackward[5])
                {
                    outMasksOverallBackward[0] = round;             //current round
                    outMasksOverallBackward[1] = maskX; 			//inputmask X
                    outMasksOverallBackward[2] = maskY;             //inputmask Y
                    outMasksOverallBackward[3] = iMaskXRound;       //outputmask X at the start of round 1
                    outMasksOverallBackward[4] = iMaskYRound;       //outputmask Y at the start of round 1
                    outMasksOverallBackward[5]= count;              //BIAS
                }
                
            } // END UPDATE BIAS
            
            
        } // End ROUNDFUNCTION BACKWARD
        
        
        
        
        //===============CHECK BEST ROUND RESULT GLOBAL===================================================
        
        // go over all rounds
        for(__private int round=1; round <= 14; round++)
        {
            
            //chekc all combinations
            for (__private int k =0 ; k <= round ; k++ )
            {
                /* a + b = i
                 * finding all possible combinations for i rounds
                 */
                __private int a = round-k;
                __private int b = k;
                
                if ( (a == 0 & b == 0))
                {
                    //do nothing
                }
                //Check bounds
                /*
	        if ( (a == 0 & b == 0) | ( checkUpperBound(roundResultForward[b-1][5], blocksize)) |  (checkUpperBound(roundResultBackward[a-1][5], blocksize)))
                {
                    //do nothing
                }
                */
                //Check if Backward is set to round 0
                else if(a==0)
                {
		    /*
                    // if bias of combination is bigger than the upperbound, then break of combo
                    if (checkUpperBound(roundResultForward[b-1][5], blocksize))
                    {
                        //do nothing
                    }
                    else
                    {
		    */	
                        //Check if result has improved
                        if (  0 + roundResultForward[b-1][5] < outputBestRoundCombo[((round-1)*6) +5] )
                        {
                            //CHECK BEST ROUND RESULTS
                            /* OpenCL cannot deal with 2d arrays
                             * Round            (i-1)*6
                             * MaskX            ((i-1)*6) +1
                             * MaskY            ((i-1)*6) +2
                             * #rounds backward ((i-1)*6) +3
                             * #rounds forward  ((i-1)*6) +4
                             * BIAS             ((i-1)*6) +5
                             */
                            
                            outputBestRoundCombo[(round-1)*6] = round ;                                           	//ROUND NUMBER
                            outputBestRoundCombo[((round-1)*6) +1] = roundResultForward[0][3];        	//starting MASK x
                            outputBestRoundCombo[((round-1)*6) +2] = roundResultForward[0][4];        	//starting MASK y
                            outputBestRoundCombo[((round-1)*6) +3] = a;                                        	//Backward rounds
                            outputBestRoundCombo[((round-1)*6) +4] = b;                                        	//Forward  rounds
                            outputBestRoundCombo[((round-1)*6) +5] = 0 	+ roundResultForward[b-1][5];        	//BIAS
                        }
                    //}
                }
                
                //Check if Forward is set to round 0
                else if (b==0)
                {
		   /*
                    // if bias of combination is bigger than the upperbound, then break of combo
                    if (checkUpperBound(0 + roundResultBackward[a-1][5], blocksize))
                    {
                        //do nothing
                        
                    }
                    else
		    */
                    //{
                        //check i improved
                        if ( 0 + roundResultBackward[a-1][5] < outputBestRoundCombo[((round-1)*6) +5] )
                            
                        {
                            outputBestRoundCombo[(round-1)*6] = round;                                           	//ROUND NUMBER
                            outputBestRoundCombo[((round-1)*6) +1] = roundResultBackward[0][3];        	//starting MASK x
                            outputBestRoundCombo[((round-1)*6) +2] = roundResultBackward[0][4];        	//starting MASK y
                            outputBestRoundCombo[((round-1)*6) +3] = a;                                        	//Backward rounds
                            outputBestRoundCombo[((round-1)*6) +4] = b;                                        	//Forward  rounds
                            outputBestRoundCombo[((round-1)*6) +5] = 0 	+ roundResultBackward[a-1][5]                        	;        	//BIAS
                        }
                    //}
                }
                
                //Both are not round 0
                else
                {
	   	    /*
                    // if bios of combination is bigger than the upperbound, then break of combo
                    if (checkUpperBound(roundResultBackward[a-1][5] + roundResultForward[b-1][5] , blocksize))
                    {
                        // do  nothing
                    }
                    else
                    {
	  	    */
                        //Check if improved
                        if (  (roundResultBackward[a-1][5] + roundResultForward[b-1][5]) < outputBestRoundCombo[((round-1)*6) +5] )
                        {
                            outputBestRoundCombo[(round-1)*6] = round;                                                                  //ROUND NUMBER
                            outputBestRoundCombo[((round-1)*6) +1] = roundResultBackward[0][3];                                         //starting MASK x
                            outputBestRoundCombo[((round-1)*6) +2] = roundResultBackward[0][4];                                         //starting MASK y
                            outputBestRoundCombo[((round-1)*6) +3] = a;                                                                 //Backward rounds
                            outputBestRoundCombo[((round-1)*6) +4] = b;                                                                 //Forward  rounds
                            outputBestRoundCombo[((round-1)*6) +5] = (roundResultBackward[a-1][5] + roundResultForward[b-1][5]);        	//BIAS
                            
                        }
                        
                    //}
                    
                } // END ELSE BOTH NOT zero
                
                
                
            } // End loop checking combinations
            
        } // end round loop
        
}
//=====================================================================================








//===================== Kernel ARX_TOOLBOXOL__kernel=========================================

__kernel void ARX_TOOLBOX_Cipher_kernel(
                                        __global ulong *outputBestRoundCombo,               //OUTPUT - write the best round combo (forward, backward)
                                        __global ulong *outMasksBestRoundBackward,          //OUTPUT - write the best round backward
                                        __global ulong *outMasksOverallBackward,            //OUTPUT - write the best overall result backward
                                        __global ulong *outMasksBestRoundForward,           //OUTPUT - write the best round forward
                                        __global ulong *outMasksOverallForward,             //OUTPUT - write the best overall result forward
                                        __global ulong *inWords
                                        )
{
    //==============================PRE-WORK & CHECKS================================================
    size_t lid = get_local_id(0);//get workgroup number
    size_t gid = get_global_id(0); // work item number
    
    if ((gid) > (556854*1597))
    {
        return; //don't execute round function if thread number is higher then the available pairs
    }
    //else if( (((inWords[gid])&0xff000)!= 0x18000 )  & ((inWords[gid] &  0xffff ) != 0x0 )  )  // word not zero and pairs are consequtive
    else if( (((inWords[gid])&0xff000)!= 0x18000 )  & ((inWords[gid] &  0xffffffff ) != 0x0 )  )  // word not zero and pairs are consequtive
    {
 	__private uint blocksize = 32;
        
        //check if incoming  masks are consequtive
	if ( checkTwoConsecutiveBits( (inWords[(gid)] &  0xffffffff ) ,blocksize)  ) 
         {

       
	cipherRoundFunction(
                                ((inWords[(gid)] >> 16 ) & 0xffff),
				(inWords[(gid)] &  0xffff),
                                32,
                                22,
                               outputBestRoundCombo,               //OUTPUT - write the best round combo (forward, backward)
                               outMasksBestRoundBackward,          //OUTPUT - write the best round backward
                               outMasksOverallBackward,            //OUTPUT - write the best overall result backward
                               outMasksBestRoundForward,           //OUTPUT - write the best round forward
                               outMasksOverallForward             //OUTPUT - write the best overall result forward
                                );

	if ( (inWords[(gid)] &  0xffff) !=0x0)
        {
	cipherRoundFunction(
                                0,
				(inWords[(gid)] &  0xffff),
                                32,
                                22,
                               outputBestRoundCombo,               //OUTPUT - write the best round combo (forward, backward)
                               outMasksBestRoundBackward,          //OUTPUT - write the best round backward
                               outMasksOverallBackward,            //OUTPUT - write the best overall result backward
                               outMasksBestRoundForward,           //OUTPUT - write the best round forward
                               outMasksOverallForward             //OUTPUT - write the best overall result forward
                                );
	cipherRoundFunction(
                                (inWords[(gid)] &  0xffff),
				0,
                                32,
                                22,
                               outputBestRoundCombo,               //OUTPUT - write the best round combo (forward, backward)
                               outMasksBestRoundBackward,          //OUTPUT - write the best round backward
                               outMasksOverallBackward,            //OUTPUT - write the best overall result backward
                               outMasksBestRoundForward,           //OUTPUT - write the best round forward
                               outMasksOverallForward             //OUTPUT - write the best overall result forward
                                );

	};


    


         } // end check if incomming word is consequtive
       
    } // END OF ELSE CONDITION THAT OUTSIDE MEMORY IS NOT USED
    
    
    
} // END OF KERNEL ARX_TOOLBOX
//==============================================================






/*=====================================================================================================================
 *   ARX TOOLBOX KERNEL GENERATING PAIRS
 *
 *
 */
__kernel void ARX_TOOLBOX_PAIRS_kernel(
                                       __constant ulong *blockSize,
                                       __constant ulong *nrRounds,
                                       __global ulong *inWords,
                                       __global ulong *outWords,
                                       __global ulong *leftPartWord
                                       )
{
    //get id's
    size_t lid = get_local_id(0);//get workgroup number
    size_t gid = get_global_id(0); // work item number
    size_t numberOfThreads =get_global_size(0);
    
    if (gid >= numberOfThreads)
    {
        return; //don't execute round function if thread number is higher then the available pairs
    }
    else // do computation
    {
      //Variables
        ulong counter = 0;                      //count number generated pairs
	ulong const firstJump = 1596;
        ulong const secondJump = 1597;
  	ulong const thirdJump = 1596;

	/************************************************************************************
        **************************CHECK 0x6... and 0x7... ***********************************/
        if (  (((inWords[gid]>>12)&0xf) == 0x6) | (((inWords[gid]>>12)&0xf) == 0x7)) 
        {
	 ulong const ti0= 0x3;                   //Starting position left side
         ulong const word_size = 0xffff;         //Needs to be changed        //Size of the word
         ulong const zeroRight =0x0000;       //right side is zero

	 if(gid==0)  //generate pairs with zero right 28 bits
         {
             ulong const initialBlock =16;           //28 bits generated on the host most right bits
             ulong counterZeros=0;	//count the zero pairs
             //if no pre-generated mask, then do the following two lines
             outWords[(counter+firstJump)] =  inWords[gid];
             counter++;
             for (ulong ti1=ti0;ti1<word_size;ti1=ti1*2)
             {
                outWords[(counterZeros)] =   (((ti1) << initialBlock) |( zeroRight));
                counterZeros++;
                outWords[(counter+firstJump)] = (((ti1) << initialBlock) |  ( inWords[gid]));
                counter++;
                for (ulong ti2=ti1<<2;ti2<word_size;ti2=ti2*2)
                {
                   outWords[(counterZeros)] =    (((ti1^ti2) << initialBlock) |( zeroRight));
                   counterZeros++;
                   outWords[(counter+firstJump)] =   (((ti1^ti2) << initialBlock) |  ( inWords[gid]));
                   counter++;
		   for (ulong ti3=ti2<<2;ti3<word_size;ti3=ti3*2)
                   {
                     outWords[(counterZeros)] =    (((ti1^ti2^ti3) << initialBlock) |( zeroRight));
                     counterZeros++;
                     outWords[(counter+firstJump)] =   (((ti1^ti2^ti3) << initialBlock) |  ( inWords[gid]));
                     counter++;
		     for (ulong ti4=ti3<<2;ti4<word_size;ti4=ti4*2)
                     {
                       outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4) << initialBlock) |( zeroRight));
                       counterZeros++;
                       outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4) << initialBlock) |  ( inWords[gid]));
                       counter++;
		       for (ulong ti5=ti4<<2;ti5<word_size;ti5=ti5*2)
                       {
                         outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5) << initialBlock) |( zeroRight));
                         counterZeros++;
                         outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5) << initialBlock) |  ( inWords[gid]));
                         counter++;
                         for (ulong ti6=ti5<<2;ti6<word_size;ti6=ti6*2)
                         {
                           outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5^ti6) << initialBlock) |( zeroRight));
                           counterZeros++;
                           outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5^ti6) << initialBlock) |  ( inWords[gid]));
                           counter++;
			   for (ulong ti7=ti6<<2;ti7<word_size;ti7=ti7*2)
                           {
                             outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5^ti6^ti7) << initialBlock) |( zeroRight));
                             counterZeros++;
                             outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5^ti6^ti7) << initialBlock) |  ( inWords[gid]));
                             counter++;
	  		     for (ulong ti8=ti7<<2;ti8<word_size;ti8=ti8*2)
                             {
                               outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5^ti6^ti7^ti8) << initialBlock) |( zeroRight));
                               counterZeros++;
                               outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5^ti6^ti7^ti8) << initialBlock) |  ( inWords[gid]));
                               counter++;
                             }//i8
                           }//i7
                         }//i6
                       }//i5
                     }//i4
                   }//i3
                }//i2
             }//i1
    	  }//end if work item equal == 0   

	  else // work item !=0
          {
	   ulong const initialBlock =15;           //15 bits generated on the host most right bits
	   counter = 0;
           for (ulong ti1=ti0;ti1<word_size;ti1=ti1*2)
           {
             outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1) << initialBlock) |  ( inWords[gid]));
             counter++;
             for (ulong ti2=ti1<<2;ti2<word_size;ti2=ti2*2)
             {
               outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2) << initialBlock) |  ( inWords[gid]));
               counter++;
	       for (ulong ti3=ti2<<2;ti3<word_size;ti3=ti3*2)
               {
               	outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3) << initialBlock) |  ( inWords[gid]));
               	counter++;
		for (ulong ti4=ti3<<2;ti4<word_size;ti4=ti4*2)
                {
               	  outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4) << initialBlock) |  ( inWords[gid]));
               	  counter++;
		  for (ulong ti5=ti4<<2;ti5<word_size;ti5=ti5*2)
                  {
               	    outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5) << initialBlock) |  ( inWords[gid]));
               	    counter++;
  		    for (ulong ti6=ti5<<2;ti6<word_size;ti6=ti6*2)
                    {
               	      outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5^ti6) << initialBlock) |  ( inWords[gid]));
               	      counter++;
 		      for (ulong ti7=ti6<<2;ti7<word_size;ti7=ti7*2)
                      {
               	        outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5^ti6^ti7) << initialBlock) |  ( inWords[gid]));
               	        counter++;
  			for (ulong ti8=ti7<<2;ti8<word_size;ti8=ti8*2)
                        {
               	           outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5^ti6^ti7^ti8) << initialBlock) |  ( inWords[gid]));
               	           counter++;
                        }//i8
                      }//i7
                    }//i6
                  }//i5
                 }//i4
               }//i3
             }//i2
           }//i1
	  } 
	
	}// end equal 0x6 or 0x7

        /************************************************************************************
        **************************not 0x6... and 0x7... ***********************************/
	else
	{
	 ulong const ti0= 0x3;                   //Starting position left side
         ulong const word_size = 0xffff;         //Needs to be changed        //Size of the word
         ulong const zeroRight =0x0000;         //right side is zero
         ulong const initialBlock =16;           //28 bits generated on the host most right bits
	 if(gid==0)  //generate pairs with zero right 28 bits
         {
             ulong counterZeros=0;	//count the zero pairs
             //if no pre-generated mask, then do the following two lines
             outWords[(counter+firstJump)] =  inWords[gid];
             counter++;
             for (ulong ti1=ti0;ti1<word_size;ti1=ti1*2)
             {
                outWords[(counterZeros)] =   (((ti1) << initialBlock) |( zeroRight));
                counterZeros++;
                outWords[(counter+firstJump)] = (((ti1) << initialBlock) |  ( inWords[gid]));
                counter++;
                for (ulong ti2=ti1<<2;ti2<word_size;ti2=ti2*2)
                {
                   outWords[(counterZeros)] =    (((ti1^ti2) << initialBlock) |( zeroRight));
                   counterZeros++;
                   outWords[(counter+firstJump)] =   (((ti1^ti2) << initialBlock) |  ( inWords[gid]));
                   counter++;
		   for (ulong ti3=ti2<<2;ti3<word_size;ti3=ti3*2)
                   {
                     outWords[(counterZeros)] =    (((ti1^ti2^ti3) << initialBlock) |( zeroRight));
                     counterZeros++;
                     outWords[(counter+firstJump)] =   (((ti1^ti2^ti3) << initialBlock) |  ( inWords[gid]));
                     counter++;
		     for (ulong ti4=ti3<<2;ti4<word_size;ti4=ti4*2)
                     {
                       outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4) << initialBlock) |( zeroRight));
                       counterZeros++;
                       outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4) << initialBlock) |  ( inWords[gid]));
                       counter++;
		       for (ulong ti5=ti4<<2;ti5<word_size;ti5=ti5*2)
                       {
                         outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5) << initialBlock) |( zeroRight));
                         counterZeros++;
                         outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5) << initialBlock) |  ( inWords[gid]));
                         counter++;
                         for (ulong ti6=ti5<<2;ti6<word_size;ti6=ti6*2)
                         {
                           outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5^ti6) << initialBlock) |( zeroRight));
                           counterZeros++;
                           outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5^ti6) << initialBlock) |  ( inWords[gid]));
                           counter++;
			   for (ulong ti7=ti6<<2;ti7<word_size;ti7=ti7*2)
                           {
                             outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5^ti6^ti7) << initialBlock) |( zeroRight));
                             counterZeros++;
                             outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5^ti6^ti7) << initialBlock) |  ( inWords[gid]));
                             counter++;
	  		     for (ulong ti8=ti7<<2;ti8<word_size;ti8=ti8*2)
                             {
                               outWords[(counterZeros)] =    (((ti1^ti2^ti3^ti4^ti5^ti6^ti7^ti8) << initialBlock) |( zeroRight));
                               counterZeros++;
                               outWords[(counter+firstJump)] =   (((ti1^ti2^ti3^ti4^ti5^ti6^ti7^ti8) << initialBlock) |  ( inWords[gid]));
                               counter++;
                             }//i8
                           }//i7
                         }//i6
                       }//i5
                     }//i4
                   }//i3
                }//i2
             }//i1
    	  }//end if  

	//Working item not  == 0
        else
	{
	  counter = 0;
          for (ulong ti1=ti0;ti1<word_size;ti1=ti1*2)
          {
             outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1) << initialBlock) |  ( inWords[gid]));
             counter++;
             for (ulong ti2=ti1<<2;ti2<word_size;ti2=ti2*2)
             {
               outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2) << initialBlock) |  ( inWords[gid]));
               counter++;
	       for (ulong ti3=ti2<<2;ti3<word_size;ti3=ti3*2)
               {
               	outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3) << initialBlock) |  ( inWords[gid]));
               	counter++;
		for (ulong ti4=ti3<<2;ti4<word_size;ti4=ti4*2)
                {
               	  outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4) << initialBlock) |  ( inWords[gid]));
               	  counter++;
		  for (ulong ti5=ti4<<2;ti5<word_size;ti5=ti5*2)
                  {
               	    outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5) << initialBlock) |  ( inWords[gid]));
               	    counter++;
  		    for (ulong ti6=ti5<<2;ti6<word_size;ti6=ti6*2)
                    {
               	      outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5^ti6) << initialBlock) |  ( inWords[gid]));
               	      counter++;
 		      for (ulong ti7=ti6<<2;ti7<word_size;ti7=ti7*2)
                      {
               	        outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5^ti6^ti7) << initialBlock) |  ( inWords[gid]));
               	        counter++;
  			for (ulong ti8=ti7<<2;ti8<word_size;ti8=ti8*2)
                        {
               	           outWords[((gid*thirdJump)+(counter+secondJump))] =  (((ti1^ti2^ti3^ti4^ti5^ti6^ti7^ti8) << initialBlock) |  ( inWords[gid]));
               	           counter++;
                        }//i8
                      }//i7
                    }//i6
                  }//i5
                 }//i4
               }//i3
             }//i2
           }//i1
	}//end else 
     }//end not 0x6 and 0x7
    }//end else    -- computing
}// END OF KERNEL ARX_TOOLBOX GENERATING PAIRS
//==============================================================


