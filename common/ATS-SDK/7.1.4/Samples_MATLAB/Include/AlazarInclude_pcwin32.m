function [methodinfo,structs,enuminfo,ThunkLibName]=AlazarInclude
%ALAZARINCLUDE Create structures to define interfaces found in 'AlazarApi'.

%This function was generated by loadlibrary.m parser version  on Fri Jan  8 15:02:05 2016
%perl options:'AlazarApi.i -outfile=AlazarInclude.m'
ival={cell(1,0)}; % change 0 to the actual number of functions to preallocate the data.
structs=[];enuminfo=[];fcnNum=1;
fcns=struct('name',ival,'calltype',ival,'LHS',ival,'RHS',ival,'alias',ival);
ThunkLibName=[];
% unsigned int AlazarGetOEMFPGAName ( int opcodeID , char * FullPath , unsigned long * error ); 
fcns.name{fcnNum}='AlazarGetOEMFPGAName'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'int32', 'cstring', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarOEMSetWorkingDirectory ( char * wDir , unsigned long * error ); 
fcns.name{fcnNum}='AlazarOEMSetWorkingDirectory'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'cstring', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarOEMGetWorkingDirectory ( char * wDir , unsigned long * error ); 
fcns.name{fcnNum}='AlazarOEMGetWorkingDirectory'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'cstring', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarParseFPGAName ( const char * FullName , char * Name , U32 * Type , U32 * MemSize , U32 * MajVer , U32 * MinVer , U32 * MajRev , U32 * MinRev , U32 * error ); 
fcns.name{fcnNum}='AlazarParseFPGAName'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'cstring', 'cstring', 'ulongPtr', 'ulongPtr', 'ulongPtr', 'ulongPtr', 'ulongPtr', 'ulongPtr', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarOEMDownLoadFPGA ( HANDLE h , char * FileName , U32 * RetValue ); 
fcns.name{fcnNum}='AlazarOEMDownLoadFPGA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'cstring', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarDownLoadFPGA ( HANDLE h , char * FileName , U32 * RetValue ); 
fcns.name{fcnNum}='AlazarDownLoadFPGA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'cstring', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarReadWriteTest ( HANDLE h , U32 * Buffer , U32 SizeToWrite , U32 SizeToRead ); 
fcns.name{fcnNum}='AlazarReadWriteTest'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulongPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarMemoryTest ( HANDLE h , U32 * errors ); 
fcns.name{fcnNum}='AlazarMemoryTest'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarBusyFlag ( HANDLE h , int * BusyFlag ); 
fcns.name{fcnNum}='AlazarBusyFlag'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'int32Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarTriggeredFlag ( HANDLE h , int * TriggeredFlag ); 
fcns.name{fcnNum}='AlazarTriggeredFlag'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'int32Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetSDKVersion ( U8 * Major , U8 * Minor , U8 * Revision ); 
fcns.name{fcnNum}='AlazarGetSDKVersion'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'uint8Ptr', 'uint8Ptr', 'uint8Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetDriverVersion ( U8 * Major , U8 * Minor , U8 * Revision ); 
fcns.name{fcnNum}='AlazarGetDriverVersion'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'uint8Ptr', 'uint8Ptr', 'uint8Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetBoardRevision ( HANDLE hBoard , U8 * Major , U8 * Minor ); 
fcns.name{fcnNum}='AlazarGetBoardRevision'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8Ptr', 'uint8Ptr'};fcnNum=fcnNum+1;
% U32 AlazarBoardsFound (); 
fcns.name{fcnNum}='AlazarBoardsFound'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% HANDLE AlazarOpen ( char * BoardNameID ); 
fcns.name{fcnNum}='AlazarOpen'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='voidPtr'; fcns.RHS{fcnNum}={'cstring'};fcnNum=fcnNum+1;
% void AlazarClose ( HANDLE h ); 
fcns.name{fcnNum}='AlazarClose'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% MSILS AlazarGetBoardKind ( HANDLE h ); 
fcns.name{fcnNum}='AlazarGetBoardKind'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='MSILS'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetCPLDVersion ( HANDLE h , U8 * Major , U8 * Minor ); 
fcns.name{fcnNum}='AlazarGetCPLDVersion'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8Ptr', 'uint8Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetChannelInfo ( HANDLE h , U32 * MemSize , U8 * SampleSize ); 
fcns.name{fcnNum}='AlazarGetChannelInfo'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulongPtr', 'uint8Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarInputControl ( HANDLE h , U8 Channel , U32 Coupling , U32 InputRange , U32 Impedance ); 
fcns.name{fcnNum}='AlazarInputControl'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarInputControlEx ( HANDLE hBoard , U32 uChannel , U32 uCouplingId , U32 uRangeId , U32 uImpedenceId ); 
fcns.name{fcnNum}='AlazarInputControlEx'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetPosition ( HANDLE h , U8 Channel , int PMPercent , U32 InputRange ); 
fcns.name{fcnNum}='AlazarSetPosition'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8', 'int32', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetExternalTrigger ( HANDLE h , U32 Coupling , U32 Range ); 
fcns.name{fcnNum}='AlazarSetExternalTrigger'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetTriggerDelay ( HANDLE h , U32 Delay ); 
fcns.name{fcnNum}='AlazarSetTriggerDelay'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetTriggerTimeOut ( HANDLE h , U32 to_ns ); 
fcns.name{fcnNum}='AlazarSetTriggerTimeOut'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% U32 AlazarTriggerTimedOut ( HANDLE h ); 
fcns.name{fcnNum}='AlazarTriggerTimedOut'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetTriggerAddress ( HANDLE h , U32 Record , U32 * TriggerAddress , U32 * TimeStampHighPart , U32 * TimeStampLowPart ); 
fcns.name{fcnNum}='AlazarGetTriggerAddress'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulongPtr', 'ulongPtr', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarSetTriggerOperation ( HANDLE h , U32 TriggerOperation , U32 TriggerEngine1 , U32 Source1 , U32 Slope1 , U32 Level1 , U32 TriggerEngine2 , U32 Source2 , U32 Slope2 , U32 Level2 ); 
fcns.name{fcnNum}='AlazarSetTriggerOperation'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulong', 'ulong', 'ulong', 'ulong', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarGetTriggerTimestamp ( HANDLE h , U32 Record , U64 * Timestamp_samples ); 
fcns.name{fcnNum}='AlazarGetTriggerTimestamp'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'uint64Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarSetTriggerOperationForScanning ( HANDLE h , U32 slope , U32 level , U32 options ); 
fcns.name{fcnNum}='AlazarSetTriggerOperationForScanning'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarAbortCapture ( HANDLE h ); 
fcns.name{fcnNum}='AlazarAbortCapture'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarForceTrigger ( HANDLE h ); 
fcns.name{fcnNum}='AlazarForceTrigger'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarForceTriggerEnable ( HANDLE h ); 
fcns.name{fcnNum}='AlazarForceTriggerEnable'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarStartCapture ( HANDLE h ); 
fcns.name{fcnNum}='AlazarStartCapture'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarCaptureMode ( HANDLE h , U32 Mode ); 
fcns.name{fcnNum}='AlazarCaptureMode'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarStreamCapture ( HANDLE h , void * Buffer , U32 BufferSize , U32 DeviceOption , U32 ChannelSelect , U32 * error ); 
fcns.name{fcnNum}='AlazarStreamCapture'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'ulong', 'ulong', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarHyperDisp ( HANDLE h , void * Buffer , U32 BufferSize , U8 * ViewBuffer , U32 ViewBufferSize , U32 NumOfPixels , U32 Option , U32 ChannelSelect , U32 Record , long TransferOffset , U32 * error ); 
fcns.name{fcnNum}='AlazarHyperDisp'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'ulong', 'uint8Ptr', 'ulong', 'ulong', 'ulong', 'ulong', 'ulong', 'long', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarFastPRRCapture ( HANDLE h , void * Buffer , U32 BufferSize , U32 DeviceOption , U32 ChannelSelect , U32 * error ); 
fcns.name{fcnNum}='AlazarFastPRRCapture'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'ulong', 'ulong', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% U32 AlazarBusy ( HANDLE h ); 
fcns.name{fcnNum}='AlazarBusy'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% U32 AlazarTriggered ( HANDLE h ); 
fcns.name{fcnNum}='AlazarTriggered'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% U32 AlazarGetStatus ( HANDLE h ); 
fcns.name{fcnNum}='AlazarGetStatus'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% U32 AlazarDetectMultipleRecord ( HANDLE h ); 
fcns.name{fcnNum}='AlazarDetectMultipleRecord'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarSetRecordCount ( HANDLE h , U32 Count ); 
fcns.name{fcnNum}='AlazarSetRecordCount'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetRecordSize ( HANDLE h , U32 PreSize , U32 PostSize ); 
fcns.name{fcnNum}='AlazarSetRecordSize'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetCaptureClock ( HANDLE h , U32 Source , U32 Rate , U32 Edge , U32 Decimation ); 
fcns.name{fcnNum}='AlazarSetCaptureClock'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetExternalClockLevel ( HANDLE h , float level_percent ); 
fcns.name{fcnNum}='AlazarSetExternalClockLevel'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'single'};fcnNum=fcnNum+1;
% unsigned int AlazarSetClockSwitchOver ( HANDLE hBoard , U32 uMode , U32 uDummyClockOnTime_ns , U32 uReserved ); 
fcns.name{fcnNum}='AlazarSetClockSwitchOver'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% U32 AlazarRead ( HANDLE h , U32 Channel , void * Buffer , int ElementSize , long Record , long TransferOffset , U32 TransferLength ); 
fcns.name{fcnNum}='AlazarRead'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'voidPtr', 'int32', 'long', 'long', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetParameter ( HANDLE h , U8 Channel , U32 Parameter , long Value ); 
fcns.name{fcnNum}='AlazarSetParameter'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8', 'ulong', 'long'};fcnNum=fcnNum+1;
% unsigned int AlazarSetParameterUL ( HANDLE h , U8 Channel , U32 Parameter , U32 Value ); 
fcns.name{fcnNum}='AlazarSetParameterUL'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarGetParameter ( HANDLE h , U8 Channel , U32 Parameter , long * RetValue ); 
fcns.name{fcnNum}='AlazarGetParameter'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8', 'ulong', 'longPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetParameterUL ( HANDLE h , U8 Channel , U32 Parameter , U32 * RetValue ); 
fcns.name{fcnNum}='AlazarGetParameterUL'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% HANDLE AlazarGetSystemHandle ( U32 sid ); 
fcns.name{fcnNum}='AlazarGetSystemHandle'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='voidPtr'; fcns.RHS{fcnNum}={'ulong'};fcnNum=fcnNum+1;
% U32 AlazarNumOfSystems (); 
fcns.name{fcnNum}='AlazarNumOfSystems'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}=[];fcnNum=fcnNum+1;
% U32 AlazarBoardsInSystemBySystemID ( U32 sid ); 
fcns.name{fcnNum}='AlazarBoardsInSystemBySystemID'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'ulong'};fcnNum=fcnNum+1;
% U32 AlazarBoardsInSystemByHandle ( HANDLE systemHandle ); 
fcns.name{fcnNum}='AlazarBoardsInSystemByHandle'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% HANDLE AlazarGetBoardBySystemID ( U32 sid , U32 brdNum ); 
fcns.name{fcnNum}='AlazarGetBoardBySystemID'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='voidPtr'; fcns.RHS{fcnNum}={'ulong', 'ulong'};fcnNum=fcnNum+1;
% HANDLE AlazarGetBoardBySystemHandle ( HANDLE systemHandle , U32 brdNum ); 
fcns.name{fcnNum}='AlazarGetBoardBySystemHandle'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='voidPtr'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetLED ( HANDLE h , U32 state ); 
fcns.name{fcnNum}='AlazarSetLED'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarQueryCapability ( HANDLE h , U32 request , U32 value , U32 * retValue ); 
fcns.name{fcnNum}='AlazarQueryCapability'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% U32 AlazarMaxSglTransfer ( ALAZAR_BOARDTYPES bt ); 
fcns.name{fcnNum}='AlazarMaxSglTransfer'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'BoardTypes'};fcnNum=fcnNum+1;
% unsigned int AlazarGetMaxRecordsCapable ( HANDLE h , U32 RecordLength , U32 * num ); 
fcns.name{fcnNum}='AlazarGetMaxRecordsCapable'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% U32 AlazarGetWhoTriggeredBySystemHandle ( HANDLE systemHandle , U32 brdNum , U32 recNum ); 
fcns.name{fcnNum}='AlazarGetWhoTriggeredBySystemHandle'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% U32 AlazarGetWhoTriggeredBySystemID ( U32 sid , U32 brdNum , U32 recNum ); 
fcns.name{fcnNum}='AlazarGetWhoTriggeredBySystemID'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSetBWLimit ( HANDLE h , U32 Channel , U32 enable ); 
fcns.name{fcnNum}='AlazarSetBWLimit'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarSleepDevice ( HANDLE h , U32 state ); 
fcns.name{fcnNum}='AlazarSleepDevice'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarStartAutoDMA ( HANDLE h , void * Buffer1 , U32 UseHeader , U32 ChannelSelect , long TransferOffset , U32 TransferLength , long RecordsPerBuffer , long RecordCount , AUTODMA_STATUS * error , U32 r1 , U32 r2 , U32 * r3 , U32 * r4 ); 
fcns.name{fcnNum}='AlazarStartAutoDMA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'ulong', 'ulong', 'long', 'ulong', 'long', 'long', 'e_AUTODMA_STATUSPtr', 'ulong', 'ulong', 'ulongPtr', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetNextAutoDMABuffer ( HANDLE h , void * Buffer1 , void * Buffer2 , long * WhichOne , long * RecordsTransfered , AUTODMA_STATUS * error , U32 r1 , U32 r2 , long * TriggersOccurred , U32 * r4 ); 
fcns.name{fcnNum}='AlazarGetNextAutoDMABuffer'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'voidPtr', 'longPtr', 'longPtr', 'e_AUTODMA_STATUSPtr', 'ulong', 'ulong', 'longPtr', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarGetNextBuffer ( HANDLE h , void * Buffer1 , void * Buffer2 , long * WhichOne , long * RecordsTransfered , AUTODMA_STATUS * error , U32 r1 , U32 r2 , long * TriggersOccurred , U32 * r4 ); 
fcns.name{fcnNum}='AlazarGetNextBuffer'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'voidPtr', 'longPtr', 'longPtr', 'e_AUTODMA_STATUSPtr', 'ulong', 'ulong', 'longPtr', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarCloseAUTODma ( HANDLE h ); 
fcns.name{fcnNum}='AlazarCloseAUTODma'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarAbortAutoDMA ( HANDLE h , void * Buffer , AUTODMA_STATUS * error , U32 r1 , U32 r2 , U32 * r3 , U32 * r4 ); 
fcns.name{fcnNum}='AlazarAbortAutoDMA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'e_AUTODMA_STATUSPtr', 'ulong', 'ulong', 'ulongPtr', 'ulongPtr'};fcnNum=fcnNum+1;
% U32 AlazarGetAutoDMAHeaderValue ( HANDLE h , U32 Channel , void * DataBuffer , U32 Record , U32 Parameter , AUTODMA_STATUS * error ); 
fcns.name{fcnNum}='AlazarGetAutoDMAHeaderValue'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'voidPtr', 'ulong', 'ulong', 'e_AUTODMA_STATUSPtr'};fcnNum=fcnNum+1;
% float AlazarGetAutoDMAHeaderTimeStamp ( HANDLE h , U32 Channel , void * DataBuffer , U32 Record , AUTODMA_STATUS * error ); 
fcns.name{fcnNum}='AlazarGetAutoDMAHeaderTimeStamp'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='single'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'voidPtr', 'ulong', 'e_AUTODMA_STATUSPtr'};fcnNum=fcnNum+1;
% void * AlazarGetAutoDMAPtr ( HANDLE h , U32 DataOrHeader , U32 Channel , void * DataBuffer , U32 Record , AUTODMA_STATUS * error ); 
fcns.name{fcnNum}='AlazarGetAutoDMAPtr'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='voidPtr'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'voidPtr', 'ulong', 'e_AUTODMA_STATUSPtr'};fcnNum=fcnNum+1;
% U32 AlazarWaitForBufferReady ( HANDLE h , long tms ); 
fcns.name{fcnNum}='AlazarWaitForBufferReady'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='ulong'; fcns.RHS{fcnNum}={'voidPtr', 'long'};fcnNum=fcnNum+1;
% unsigned int AlazarEvents ( HANDLE h , U32 enable ); 
fcns.name{fcnNum}='AlazarEvents'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarBeforeAsyncRead ( HANDLE hBoard , U32 uChannelSelect , long lTransferOffset , U32 uSamplesPerRecord , U32 uRecordsPerBuffer , U32 uRecordsPerAcquisition , U32 uFlags ); 
fcns.name{fcnNum}='AlazarBeforeAsyncRead'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'long', 'ulong', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarAbortAsyncRead ( HANDLE hBoard ); 
fcns.name{fcnNum}='AlazarAbortAsyncRead'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarPostAsyncBuffer ( HANDLE hDevice , void * pBuffer , U32 uBufferLength_bytes ); 
fcns.name{fcnNum}='AlazarPostAsyncBuffer'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarWaitAsyncBufferComplete ( HANDLE hDevice , void * pBuffer , U32 uTimeout_ms ); 
fcns.name{fcnNum}='AlazarWaitAsyncBufferComplete'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarWaitNextAsyncBufferComplete ( HANDLE hDevice , void * pBuffer , U32 uBufferLength_bytes , U32 uTimeout_ms ); 
fcns.name{fcnNum}='AlazarWaitNextAsyncBufferComplete'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarCreateStreamFileA ( HANDLE hDevice , const char * pszFilePath ); 
fcns.name{fcnNum}='AlazarCreateStreamFileA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'cstring'};fcnNum=fcnNum+1;
% long AlazarFlushAutoDMA ( HANDLE h ); 
fcns.name{fcnNum}='AlazarFlushAutoDMA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='long'; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% void AlazarStopAutoDMA ( HANDLE h ); 
fcns.name{fcnNum}='AlazarStopAutoDMA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}=[]; fcns.RHS{fcnNum}={'voidPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarResetTimeStamp ( HANDLE h , U32 resetFlag ); 
fcns.name{fcnNum}='AlazarResetTimeStamp'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarReadRegister ( HANDLE hDevice , U32 offset , U32 * retVal , U32 pswrd ); 
fcns.name{fcnNum}='AlazarReadRegister'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulongPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarWriteRegister ( HANDLE hDevice , U32 offset , U32 Val , U32 pswrd ); 
fcns.name{fcnNum}='AlazarWriteRegister'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarDACSetting ( HANDLE h , U32 SetGet , U32 OriginalOrModified , U8 Channel , U32 DACNAME , U32 Coupling , U32 InputRange , U32 Impedance , U32 * getVal , U32 setVal , U32 * error ); 
fcns.name{fcnNum}='AlazarDACSetting'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'uint8', 'ulong', 'ulong', 'ulong', 'ulong', 'ulongPtr', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarConfigureAuxIO ( HANDLE hDevice , U32 uMode , U32 uParameter ); 
fcns.name{fcnNum}='AlazarConfigureAuxIO'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% const char * AlazarErrorToText ( unsigned int code ); 
fcns.name{fcnNum}='AlazarErrorToText'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='cstring'; fcns.RHS{fcnNum}={'uint32'};fcnNum=fcnNum+1;
% unsigned int AlazarConfigureSampleSkipping ( HANDLE hBoard , U32 uMode , U32 uSampleClocksPerRecord , U16 * pwClockSkipMask ); 
fcns.name{fcnNum}='AlazarConfigureSampleSkipping'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'uint16Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarCoprocessorRegisterRead ( HANDLE hDevice , U32 offset , U32 * pValue ); 
fcns.name{fcnNum}='AlazarCoprocessorRegisterRead'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarCoprocessorRegisterWrite ( HANDLE hDevice , U32 offset , U32 value ); 
fcns.name{fcnNum}='AlazarCoprocessorRegisterWrite'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarCoprocessorDownloadA ( HANDLE hBoard , char * pszFileName , U32 uOptions ); 
fcns.name{fcnNum}='AlazarCoprocessorDownloadA'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'cstring', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarConfigureRecordAverage ( HANDLE hBoard , U32 uMode , U32 uSamplesPerRecord , U32 uRecordsPerAverage , U32 uOptions ); 
fcns.name{fcnNum}='AlazarConfigureRecordAverage'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% U8 * AlazarAllocBufferU8 ( HANDLE hBoard , U32 uSampleCount ); 
fcns.name{fcnNum}='AlazarAllocBufferU8'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint8Ptr'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarFreeBufferU8 ( HANDLE hBoard , U8 * pBuffer ); 
fcns.name{fcnNum}='AlazarFreeBufferU8'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8Ptr'};fcnNum=fcnNum+1;
% U16 * AlazarAllocBufferU16 ( HANDLE hBoard , U32 uSampleCount ); 
fcns.name{fcnNum}='AlazarAllocBufferU16'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint16Ptr'; fcns.RHS{fcnNum}={'voidPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarFreeBufferU16 ( HANDLE hBoard , U16 * pBuffer ); 
fcns.name{fcnNum}='AlazarFreeBufferU16'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint16Ptr'};fcnNum=fcnNum+1;
% unsigned int AlazarConfigureLSB ( HANDLE hBoard , U32 uValueLsb0 , U32 uValueLsb1 ); 
fcns.name{fcnNum}='AlazarConfigureLSB'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarDspRegisterRead ( HANDLE hDevice , U32 offset , U32 * pValue ); 
fcns.name{fcnNum}='AlazarDspRegisterRead'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulongPtr'};fcnNum=fcnNum+1;
% unsigned int AlazarDspRegisterWrite ( HANDLE hDevice , U32 offset , U32 value ); 
fcns.name{fcnNum}='AlazarDspRegisterWrite'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarExtractNPTFooters ( void * buffer , U32 recordSize_bytes , U32 bufferSize_bytes , NPTFooter * footersArray , U32 numFootersToExtract ); 
fcns.name{fcnNum}='AlazarExtractNPTFooters'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'ulong', 's_NPTFoooterPtr', 'ulong'};fcnNum=fcnNum+1;
% unsigned int AlazarEnableFFT ( HANDLE boardHandle , U8 enable ); 
fcns.name{fcnNum}='AlazarEnableFFT'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'uint8'};fcnNum=fcnNum+1;
% unsigned int AlazarOCTIgnoreBadClock ( HANDLE hBoardHandle , U32 uEnable , double dGoodClockDuration , double dBadClockDuration , double * pTriggerCycleTime , double * pTriggerPulseWidth ); 
fcns.name{fcnNum}='AlazarOCTIgnoreBadClock'; fcns.calltype{fcnNum}='cdecl'; fcns.LHS{fcnNum}='uint32'; fcns.RHS{fcnNum}={'voidPtr', 'ulong', 'double', 'double', 'doublePtr', 'doublePtr'};fcnNum=fcnNum+1;
structs.s_BoardDef.members=struct('RecordCount', 'ulong', 'RecLength', 'ulong', 'PreDepth', 'ulong', 'ClockSource', 'ulong', 'ClockEdge', 'ulong', 'SampleRate', 'ulong', 'CouplingChanA', 'ulong', 'InputRangeChanA', 'ulong', 'InputImpedChanA', 'ulong', 'CouplingChanB', 'ulong', 'InputRangeChanB', 'ulong', 'InputImpedChanB', 'ulong', 'TriEngOperation', 'ulong', 'TriggerEngine1', 'ulong', 'TrigEngSource1', 'ulong', 'TrigEngSlope1', 'ulong', 'TrigEngLevel1', 'ulong', 'TriggerEngine2', 'ulong', 'TrigEngSource2', 'ulong', 'TrigEngSlope2', 'ulong', 'TrigEngLevel2', 'ulong');
structs.s_NPTFoooter.members=struct('triggerTimestamp', 'uint64', 'recordNumber', 'ulong', 'frameCount', 'ulong', 'aux_in_state', 'uint8');
enuminfo.MSILS=struct('KINDEPENDENT',0,'KSLAVE',1,'KMASTER',2,'KLASTSLAVE',3);
enuminfo.BoardTypes=struct('ATS_NONE',0,'ATS850',1,'ATS310',2,'ATS330',3,'ATS855',4,'ATS315',5,'ATS335',6,'ATS460',7,'ATS860',8,'ATS660',9,'ATS665',10,'ATS9462',11,'ATS9434',12,'ATS9870',13,'ATS9350',14,'ATS9325',15,'ATS9440',16,'ATS9410',17,'ATS9351',18,'ATS9310',19,'ATS9461',20,'ATS9850',21,'ATS9625',22,'ATG6500',23,'ATS9626',24,'ATS9360',25,'AXI8870',26,'ATS9370',27,'ATU7825',28,'ATS9373',29,'ATS9416',30,'ATS_LAST',31);
enuminfo.e_AUTODMA_STATUS=struct('ADMA_Completed',0,'ADMA_Buffer1Invalid',1,'ADMA_Buffer2Invalid',2,'ADMA_BoardHandleInvalid',3,'ADMA_InternalBuffer1Invalid',4,'ADMA_InternalBuffer2Invalid',5,'ADMA_OverFlow',6,'ADMA_InvalidChannel',7,'ADMA_DMAInProgress',8,'ADMA_UseHeaderNotSet',9,'ADMA_HeaderNotValid',10,'ADMA_InvalidRecsPerBuffer',11,'ADMA_InvalidTransferOffset',12,'ADMA_InvalidCFlags',13);
methodinfo=fcns;