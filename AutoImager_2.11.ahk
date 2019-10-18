#CommentFlag // ; Set C++ comment style.
//*********************************************************************//
//Autorun FTK Imager
//Authored by: Bryan Koehn
//
//The purpose of this code is to be auto run when the drive is plugged
//  into a windows machine.  The drive is preconfigured using the
//  config.ini to run FTk or Robocopy to remotely image the custodian
//  PC with little or no interaction from a forensic engineer.
// 
//
//*********************************************************************

//Set version and splashscreen timeout.
//Standard splash screen is 5000
ver = 2.11
HardCodedPassword = 3p1qremote
SplashScreenTimeout = 5000
ImageTypes=FTKP,FTKL,FTKF,Robocopy,BKF
ADImageTypes=FTKP,FTKL,FTKF

JigglerName=JigglerNoNET_Epiq.exe

StringLen,Dirlength, A_WorkingDir
StringTrimRight, DestinationDrive, A_WorkingDir, Dirlength - 1


//*********************************************************************
//Defining functions
//*********************************************************************
//Mouse jiggler function
Jiggle(){

   MouseGetPos, xPos, yPos
   MouseMove, xPos -25, yPos - 50
   MouseMove, xPos, yPos
}

//Mount truecrypt vault
TCMount(TCPassword){
   global TCPWorkingDir
   SetWorkingDir, %TCPWorkingDir%

   run, %comspec% /c truecrypt.exe /a devices /p "%TCPassword%" /q,,hide,TCPID
   
   WinWait, TrueCrypt,,10
   WinClose, TrueCrypt
   ReturnValue = ErrorLevel
   Return ReturnValue
}

//Dismount truecrypt vault
TCDismount(){
   global TCPWorkingDir
   SetWorkingDir, %TCPWorkingDir%
   run, %comspec% /c "truecrypt.exe /d /a /f /q",,hide,TCPID
   
   Process, WaitClose, %TCPID%, 10
}

//********************************************************************
//End function definition
//********************************************************************

//Define working directories.
OriginalWorkingDir = %A_WorkingDir%
if StrLen(A_WorkingDir) = 3
{
   RoboWorkingDir = %A_WorkingDir%Apps\Robocopy
   TCPWorkingDir = %A_WorkingDir%Apps\TCP
   FTKCWorkingDir = %A_WorkingDir%Apps\FTKImagerCL
   FTKGWorkingDir = %A_WorkingDir%Apps\FTKImagerLite
   NTBWorkingDir = %A_WorkingDir%Apps\NTBackup
   Apps = %A_WorkingDir%Apps
}else{
   RoboWorkingDir = %A_WorkingDir%\Apps\Robocopy
   TCPWorkingDir = %A_WorkingDir%\Apps\TCP
   FTKCWorkingDir = %A_WorkingDir%\Apps\FTKImagerCL
   FTKGWorkingDir = %A_WorkingDir%\Apps\FTKImagerLite
   NTBWorkingDir = %A_WorkingDir%\Apps\NTBackup
   Apps = %A_WorkingDir%\Apps
}
ImageDir = %A_WorkingDir%\El


Loop
{
   FileReadLine, line, %A_WorkingDir%\config.ini, %A_Index%
   if ErrorLevel
      break
   If A_Index = 1
      CName = %line%
   If A_Index = 2
      INumber = %line%
   If A_Index = 3
      //DTI=DriveToImage
      DTI = %line%
   If A_Index = 4
      IType = %line%
   If A_Index = 5
      FType = %line%
}



If IType not in %ImageTypes%
{
   IType = ERROR
   MsgBox, Configuration error, please contact Epiq support.
   ExitApp
}

//********************************* Splash Screen ****************
If IType in %ADImageTypes%
{
   SplashImage, %ImageDir%\Logo_AD.jpg
}else{
   SplashImage, %ImageDir%\Logo.jpg

}
Sleep, %SplashScreenTimeout%
SplashImage, Off


MsgBox, Please make sure all other applications are closed, including your mail client.

Process,Exist,Outlook.exe
OutlookPID = %ErrorLevel%
If %OutlookPID%
{
   MsgBox, Outlook is currently running, please shut down outlook and click OK.
}

Process,Exist,notes.exe
OutlookPID = %ErrorLevel%
If %OutlookPID%
{
   MsgBox, Lotus Notes is currently running, please shut down notes and click OK.
}
Process,Exist,nlnotes.exe
OutlookPID = %ErrorLevel%
If %OutlookPID%
{
   MsgBox, Lotus Notes is currently running, please shut down notes and click OK.
}

//********************************** Input GUI *******************

Gui, Add, Text, x22 y30 h20 , Custodian first name:
Gui, add, Edit, vCustodianFName x140 y30 w160 h20, First Name 
//Gui, Add, Text, x22 y70 h20 , Custodian middle name:
//Gui, add, Edit, vCustodianMName x140 y70 w160 h20, Middle Name
Gui, Add, Text, x22 y70 h20 , Custodian last name:
Gui, add, Edit, vCustodianLName x140 y70 w160 h20, Last Name
Gui, Add, Text, x22 y110 h20 , Vault Password:
Gui, add, Edit, vPassword x140 y110 w160 h20 Password,
Gui, Add, Picture, x50 y175 w231 h102, %ImageDir%\Logo_small.jpg
If IType in %ADImageTypes%
{
   Gui, Add, Text, x50 y290 h20 , Powered by AccessData's FTK Imager.
}
Gui, Add, Text, x340 y30 h30, Code Name:
Gui, add, Text, vCodeName x435 y30 h30, %CName%
Gui, Add, Text, x340 y70 h30, Image Number:
Gui, add, Text, vImageNumber x435 y70 h30, %INumber%
Gui, Add, Text, x340 y110 h30, Image Type:
Gui, add, Text, vImageType x435 y110 h30, %IType%
Gui, Add, Text, x340 y150 h30, Device to image:
Gui, add, Text, vDriveToImage x435 y150 h30, %DTI%
Gui, Add, Text, x340 y190 h30, Job file name:

If IType in Robocopy
{
   Gui, add, Text, vFilterType x435 y190 w110 h30, %FType%
}else{
   Gui, add, text, vFilterType x435 y190 w110 h30, NA
} 

Gui, add, Text, x340 y240, During the imaging process the machine will be unusable.
Gui, add, Text, x340 y260, Please click Start once to begin drive imaging. 
Gui, Add, Button, gImageDrive x400 y300 w100 h30 , &Start

Gui, Show, , Epiq Auto Imager %ver%

return 
 


//*************************** Start imaging code ***********************
ImageDrive:
Gui, hide
msgBox, During the imaging process you will not be able to use your computer.
BlockInput, on

GuiControlGet, DestinationDrive
GuiControlGet, DriveToImage
GuiControlGet, CustodianFName
GuiControlGet, CustodianLName
GuiControlGet, Password
GuiControlGet, CodeName 
GuiControlGet, ImageNumber
GuiControlGet, ImageType
GuiControlGet, FilterType

If %A_IsAdmin%
{
}else{
   BlockInput, off
   Gui, Show, , Epiq Auto Imager %ver%
   MsgBox,  This requries local admin rights to run, please contact technical support.
   Return
}
Process,Exist,Outlook.exe
OutlookPID = %ErrorLevel%
If %OutlookPID%
{
   BlockInput, off
   Gui, Show, , Epiq Auto Imager %ver%
   MsgBox, Outlook is currently running, please shut down outlook and restart the collection.
   Return
}
Process,Exist,notes.exe
OutlookPID = %ErrorLevel%
If %OutlookPID%
{
   BlockInput, off
   Gui, Show, , Epiq Auto Imager %ver%
   MsgBox, Lotus Notes is currently running, please shut down notes and click OK.
   Return
}
Process,Exist,nlnotes.exe
OutlookPID = %ErrorLevel%
If %OutlookPID%
{
   BlockInput, off
   Gui, Show, , Epiq Auto Imager %ver%
   MsgBox, Lotus Notes is currently running, please shut down notes and click OK.
   Return
}


DriveGet, BeforeMountList, list
TCMount(Password)
Sleep, 1000

DriveGet, AfterMountList, list

Loop, Parse, AfterMountList
{
   Aft = %A_LoopField%
   ifNotInString, BeforeMountList, %Aft%
   {
       DestinationDrive = %Aft%
   }
}

If not DestinationDrive
{
   TCDismount()
   BlockInput, off
   Gui, Show, , Epiq Auto Imager %ver%
   MsgBox, Failed to mount drive, please check password.  If problems continue please contact Epiq support.
   Return
}

StringReplace, CustodianFName, CustodianFName, %A_SPACE%,, All
StringReplace, CustodianLName, CustodianLName, %A_SPACE%,, All
//StringReplace, CustodianMName, CustodianMName, %A_SPACE%,, All
//CustodianFName = %CustodianFName%_%CustodianMName%

//Start the jiggler
SetWorkingDir, %Apps%
run, %JigglerName%,,, JigglerID



ImageStart := A_Now
//Image the drive using the chosen method.

If IType in FTKP
{
   run, %comspec% /c mkdir "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%"",,hide

   SetWorkingDir, %FTKCWorkingDir%
   run, %comspec% /c ftkimager %DriveToImage% "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%\%ImageNumber%_%CustodianFName%_%CustodianLName%" --verify --e01 --evidence-number "%ImageNumber%" --case-number "%CodeName%" --examiner "%CustodianFName% %CustodianLName%" --frag 3G --outpass "%HardCodedPassword%",,,ImagePID

   sleep, 5000

   //Checks the image is still running and moves the mouse to keep the machine from sleeping or locking.
   CheckRunningFTKC:
   IfWinExist, (ahk_pid %ImagePID%)
   {
      Sleep, 5600
      Goto, CheckRunningFTKC
   }
}

If IType in FTKL
{

   SetWorkingDir, %FTKGWorkingDir%
   
   FileRemoveDir, %DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%,1

   run, %comspec% /c mkdir "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%"",,hide

   //Turns on image verify / prescan for status in FTK before FTK is even launched.
   RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\AccessData\FTK Imager\imaging, auto_verify, 1
   RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\AccessData\FTK Imager\imaging, prescan, 1

   run, FTK Imager.exe,,,ImagePID
   WinWait, (ahk_pid %ImagePID%)
   Sleep, 1000
   Send, !f
   Sleep, 1000
   send,c
   WinWait, Select
   send, !l
   sleep, 500
   send, !n
   WinWait, Select Drive
   send, !f
   WinWait, Create Image
   send, !a
   WinWait, Select Image Type
   send, !e
   Sleep, 1000
   send, !n
   Sleep, 1000
   WinWait, Evidence
   Send, %CodeName%
   Send, {tab}
   Send, %ImageNumber%
   Send, {tab}
   Send, %ImageNumber%
   Send, {tab}
   Send, %CustodianFName% %CustodianLName%
   send, !n
   send, !i
   send, %DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%
   send, !m
   Send, %ImageNumber%_%CustodianFName%_%CustodianLName%
   Send, !f
   Sleep, 1000
   Send, !s

   WinWait, Creating Image
   WinGet, ImagingWindowID, ID, Creating Image

   CheckImaging:
   IfWinExist, Creating Image
   {
      IfWinExist, Creating Image [100
      {
         WinWait, Verifying
         Goto, CheckVerifying
      }
      Sleep, 5600
      Goto, CheckImaging
   }

   CheckVerifying:
   IfWinExist, Verifying
   {
      IfWinExist, Drive/Image Verify Results
      {
         Goto, DoneVerifying
      }
      Sleep, 5600
      Goto, CheckVerifying
   }
   
   DoneVerifying:
   Send, !c
   Sleep, 500
   Send, !c
   Sleep, 500
   Send, !f
   Sleep, 1000
   Send, x   

   Sleep, 100
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
}

If IType in FTKF
{

   SetWorkingDir, %FTKGWorkingDir%
   
   FileRemoveDir, %DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%,1

   run, %comspec% /c mkdir "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%"",,hide
   run, %comspec% /c mkdir "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%_BKF"",,hide

   //Turns on image verify / prescan for status in FTK before FTK is even launched.
   RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\AccessData\FTK Imager\imaging, auto_verify, 1
   RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\AccessData\FTK Imager\imaging, prescan, 1

   run, FTK Imager.exe,,,ImagePID
   WinWait, (ahk_pid %ImagePID%)
   Sleep, 1000
   Send, !f
   Sleep, 1000
   send,c
   WinWait, Select
   send, !f
   sleep, 500
   send, !n
   WinWait, FTK
   Send, !y
   WinWait, Select File
   Send, %DriveToImage%
   send, !f
   WinWait, Create Image
   send, !a
   WinWait, Evidence
   Send, %CodeName%
   Send, {tab}
   Send, %ImageNumber%
   Send, {tab}
   Send, %ImageNumber%
   Send, {tab}
   Send, %CustodianFName% %CustodianLName%
   send, !n
   send, !i
   send, %DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%
   send, !m
   Send, %ImageNumber%_%CustodianFName%_%CustodianLName%
   Send, !p
   Send, {tab}
   Send, {space}
   Send, !f
   WinWait, AD Encryption Credentials
   Send, %HardCodedPassword%
   Send, {tab}
   Send, %HardCodedPassword%
   Send, {enter}
   Sleep, 1000
   Send, !s

   WinWait, Creating Image
   WinGet, ImagingWindowID, ID, Creating Image

   CheckImagingFileLevel:
   IfWinExist, Creating Image
   {
      IfWinExist, Creating Image [100
      {
         WinWait, Verifying
         Goto, CheckVerifyingFileLevel
      }
      Sleep, 5600
      Goto, CheckImagingFileLevel
   }

   CheckVerifyingFileLevel:
   IfWinExist, Verifying
   {
      IfWinExist, Drive/Image Verify Results
      {
         Goto, DoneVerifyingFileLevel
      }
      Sleep, 5600
      Goto, CheckVerifyingFileLevel
   }
   
   DoneVerifyingFileLevel:
   Send, !c
   Sleep, 500
   Send, !c
   Sleep, 500
   Send, !f
   Sleep, 1000
   Send, x   

   Sleep, 100
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)
   WinClose, (ahk_pid %ImagePID%)


//***************************************
//Insert Log Parsing / BKF Code.
//***************************************
   Denied=Access is denied. (5).
   DocsNSettings=Documents and Settings
   PathDocsNSettings=C:\Documents and Settings\
   
//   MsgBox, Parsing Logs code starts now.
   Loop
   {
      FileReadLine, line, %DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%\%ImageNumber%_%CustodianFName%_%CustodianLName%.ad1.txt, %A_Index%
      if ErrorLevel
      {
         break
      }
      If (InStr(line, Denied) && InStr(line, DocsNSettings))
      {
//         MsgBox, Has error.
         StringSplit, Line_Array, line, \
         If Line_Array3 in %FinalList%
         {
         }else{
            FinalList = %FinalList%%Line_Array3%,
//            MsgBox, Adding %Line_Array3%
         }
      }

   }

   Loop, parse, FinalList, `,
   {
      If %A_LoopField%
      {
         //Run BKF code
        SetWorkingDir, %NTBWorkingDir%
        runWait, %comspec% /c ntbackup backup "%PathDocsNSettings%%A_LoopField%" /a  /v:yes /r:no /rs:no /hc:off /m normal /j "Get Command" /l:s /f "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%_BKF\%A_LoopField%.bkf",,

        Sleep, 3000
        CheckRunningBKF:
        If WinExist(Backup)
        {
          Sleep, 5600
          Goto, CheckRunningBKF
        }
      }
   }


}

//This is test code non functional for making BKF files of the custodian drive.
If IType in BKF
{
   //Windows XP run BKF command line
   //NTBackup
   if (dwMajorVersion = 5)
   {

   }
   
   //Windows 7 run BKF command line
   //WBAdmin
   if (dwMajorVersion = 6)
   {

   }

}

If IType in Robocopy
{
   run, %comspec% /c mkdir "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%"",,hide
   run, %comspec% /c mkdir "%DestinationDrive%:\%CodeName%\Logs"",,hide

   SetWorkingDir, %RoboWorkingDir%
   run, %comspec% /c %RoboWorkingDir%\RCXP026 /JOB:"%RoboWorkingDir%\%FilterType%" %DriveToImage% "%DestinationDrive%:\%CodeName%\Evidence\%CustodianFName%_%CustodianLName%\%ImageNumber%" /LOG+:"%DestinationDrive%:\%CodeName%\Logs\%ImageNumber%_%CustodianFName%_%CustodianLName%.txt",,,ImagePID

   sleep, 5000

   //Checks the image is still running and jiggles the mouse.
   CheckRunningRobo:
   IfWinExist, (ahk_pid %ImagePID%)
   {
      Sleep, 5600
      Goto, CheckRunningRobo
   }
}


ImageFinish := A_Now

//Determines how long the imaging process took in seconds.
CompletedTime := ImageFinish - ImageStart


TCDismount()
Sleep, 2000

//Kill Jiggler
Process,Close,%JigglerName%

BlockInput, off
If CompletedTime<300
{
   MsgBox, Please contact Epiq technical support to verify image.
}else{
   MsgBox, Thank you, Please unplug the drive and ship it back to Epiq using the included return shipping label.
}

//Instead of Return ExitApp user will not be imaging the drive twice.
ExitApp


GuiClose:
ExitApp