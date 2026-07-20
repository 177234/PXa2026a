*! Minimal bootstrap script to run the master.R file from Stata.
version 17
                                                                               
*––– Display current directory and indicate Rscript call ––––––––––––––––––––
di as text  "Bootstrap: current directory is:  `c(pwd)'"
di as text  "Bootstrap: calling Rscript master.R"

*––– Specify the full path to Rscript. Change this path if needed. ––––––––
local rscript_cmd "/usr/local/bin/Rscript"  

* If Rscript is not found, update the above line to the correct full path to Rscript.
* For example, on some systems it might be:
* local rscript_cmd "C:/Program Files/R/R-4.3.3/bin/Rscript.exe"
* 
* To find the full path to Rscript, you can use the following command:
* which Rscript in terminal on mac/linux echo %R_HOME% in terminal on windows

*––– Call R using the full path ––––––––––––––––––––––––––––––––––––––––––––
shell "`rscript_cmd'" master.R

*––– Check for errors and exit with proper code ––––––––––––––––––––––––––––––
if (_rc) {
    di as error "Bootstrap: R returned non-zero exit code = " _rc
    exit _rc
}

exit 0 