# Patch-clamp-analysis
MATLAB scripts for action potential waveform and AHP analysis of Neuronal Current-Clamp .abf files 

This script will create excel files of the analysis for each file type. See below how to process the excels

In MATLAB run: 
ephysanalysis (0,1,0)

Select your .abf files and then pick which kind of protocol or analysis you want to do...So the options for the analysis type is as follows:


Post-Burst AHP only: for post-burst AHP analysis following a train of current injection elicited APs to calculate the peak aftherhyperpolarization (mAHP) and 1 second after last spike for the sAHP

         1)	Select timing where baseline potential should be measured.
         2)	Select timing of the end of stimulation (i.e. end of current pulse train)


Accommodation: This is for action potential wave form analysis on ramps.  This is what you use for basic analysis of AP amplitude, threshold potential, AP half width and fAHP after single spike.

        1)	Select timing where baseline potential should be measured.
        2)	Input your dvdt threshold. (e.g. range from 5-20mV/ms)


I/V Analysis: For analysis of input resistance and sag step current injection protocols
        
        1) Select timing where baseline potential should be measured.


New Style Accommodation: For analysis of accommodation and counting spikes from current injection step pulses

        1)	Select timing where baseline potential should be measured.
        2)	Input your dvdt threshold. (e.g. range from 5-20mV/ms)


Other analysis protocol types:

    Full AHP analysis: for post-burst AHP analysis from orthodromically elicited APs.

    AreaUnderCurve Spikes: For ADP analysis.

    Burstanalysis: For counting spikes in a train pulse.

    AP Analysis: This is for action potential wave for orthodromically elicited AP.

    Drug Spikes: This is for AP files that have weird spikes with spontaneous activity in your desired baseline.

    Accommodation with PSP:  This is for action potential wave for orthodromically elicited AP and EPSP or IPSPs with subthreshold stimulation.




To combine the excel spredsheets of the same kind of analysis from multiple files into one file with multiple sheets:
This will put all files from one day on each sheet and make new sheet for new day of recording. 


In MATLAB run:

dinacombinexlsoutput

    Select all the files you want to combine.




For "Accommodation" files, to take average of all the AP metrics from only the first spike of each sweep:

This will add a summary page to your excel file

In MATLAB run:

dinasummarize1spike

    Select an excel file or a combined excel file.
    
    
    
