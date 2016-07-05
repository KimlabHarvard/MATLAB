function [result] = Copy_of_acquireData(boardHandle)
% Acquire to on-board memory. After the acquisition is complete,
% transfer data to an application buffer.

%---------------------------------------------------------------------------
%
% Copyright (c) 2008-2015 AlazarTech, Inc.
%
% AlazarTech, Inc. licenses this software under specific terms and
% conditions. Use of any of the software or derivatives thereof in any
% product without an AlazarTech digitizer board is strictly prohibited.
%
% AlazarTech, Inc. provides this software AS IS, WITHOUT ANY WARRANTY,
% EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. AlazarTech makes no
% guarantee or representations regarding the use of, or the results of the
% use of, the software and documentation in terms of correctness, accuracy,
% reliability, currentness, or otherwise; and you rely on the software,
% documentation and results solely at your own risk.
%
% IN NO EVENT SHALL ALAZARTECH BE LIABLE FOR ANY LOSS OF USE, LOSS OF
% BUSINESS, LOSS OF PROFITS, INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL
% DAMAGES OF ANY KIND. IN NO EVENT SHALL ALAZARTECH%S TOTAL LIABILITY EXCEED
% THE SUM PAID TO ALAZARTECH FOR THE PRODUCT LICENSED HEREUNDER.
%
%---------------------------------------------------------------------------

% set default return code to indicate failure
result = false;

%call mfile with library definitions
AlazarDefs

% TODO: Select the number of pre-trigger samples per record
preTriggerSamples = 0;

%TODO: Select the number of post-trigger samples per record
%postTriggerSamples = 262144-16;

% TODO: Select the number of records in the acquisition
recordsPerCapture = 10;

% TODO: Select the amount of time, in seconds, to wait for a trigger
timeout_sec = 10;

% TODO: Select if you wish to save the sample data to a binary file
saveData = false;

% TODO: Select if you wish to plot the data to a chart
plotData = true;

% Get the sample and memory size
[retCode, boardHandle, maxSamplesPerRecord, bitsPerSample] = calllib('ATSApi', 'AlazarGetChannelInfo', boardHandle, 0, 0);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarGetChannelInfo failed -- %s\n', errorToText(retCode));
    return;
end

% Calculate the size of each record in bytes
bytesPerSample = 1;
samplesPerRecord = maxSamplesPerRecord/2-16;
bytesPerRecord = bytesPerSample * samplesPerRecord;

% The buffer must be at least 16 samples larger than the transfer size
% why?
samplesPerBuffer = samplesPerRecord + 16;
bytesPerBuffer = samplesPerBuffer * bytesPerSample;

% Set the number of samples per record
retCode = AlazarSetRecordSize(boardHandle, 0, samplesPerRecord);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetRecordSize failed -- %s\n', errorToText(retCode));
    return;
end

% Set the number of records in the acquisition
retCode = AlazarSetRecordCount(boardHandle, 1);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetRecordCount failed -- %s\n', errorToText(retCode));
    return;
end

% Arm the board system to begin the acquisition
retCode = AlazarStartCapture(boardHandle);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarStartCapture failed -- %s\n', errorToText(retCode));
    return;
end

% Wait for the board to capture all records to on-board memory
fprintf('Capturing %u records ...\n', recordsPerCapture);

while(AlazarBusy(boardHandle))
    %The acquisition is in progress
end

% Create a buffer to store a record
pbuffer = AlazarAllocBuffer(boardHandle, bytesPerBuffer + 16);
%pbuffer is a libpointer
if pbuffer == 0
    fprintf('Error: AlazarAllocBufferU16 %u bytes failed\n', bytesPerBuffer);
    return
end

% Create a data file if required
fid = -1;
if saveData
    fid = fopen('data.bin', 'w');
    if fid == -1
        fprintf('Error: Unable to create data file\n');
    end
end

% Transfer the records from on-board memory to our buffer
fprintf('Transferring %u records ...\n', recordsPerCapture);

for record = 1 : recordsPerCapture
    % Transfer one full record from on-board memory to our buffer
    [retCode, boardHandle, bufferOut] = ...
        AlazarRead(...
            boardHandle,            ...	% HANDLE -- board handle
            CHANNEL_A,              ...	% U32 -- channel Id
            pbuffer,                ...	% void* -- buffer
            bytesPerSample,         ...	% int -- bytes per sample
            record,             ... % long -- record (1 indexed)
            -int32(preTriggerSamples),   ...	% long -- offset from trigger in samples
            samplesPerRecord		...	% U32 -- samples to transfer
            );
    if retCode ~= ApiSuccess
        fprintf('Error: AlazarRead record %u failed -- %s\n', record, errorToText(retCode));
    else

        % TODO: Process sample data in this buffer.
        %
        % NOTE:
        %
        % While you are processing this buffer, the board is already
        % filling the next available buffer(s).
        %
        % You MUST finish processing this buffer and post it back to the
        % board before the board fills all of its available DMA buffers
        % and on-board memory.
        %
        % Records are arranged in the buffer as follows: R0A, R1A, R2A ... RnA, R0B,
        % R1B, R2B ...
        % with RXY the record number X of channel Y
        %
        % Sample code are stored as 8-bit values.
        %
        % Sample codes are unsigned by default. As a result:
        % - a sample code of 0x00 represents a negative full scale input signal.
        % - a sample code of 0x80 represents a ~0V signal.
        % - a sample code of 0xFF represents a positive full scale input signal.

        if bytesPerSample == 1
            setdatatype(bufferOut, 'uint8Ptr', 1, samplesPerBuffer);
        else
            setdatatype(bufferOut, 'uint16Ptr', 1, samplesPerBuffer);
        end

        if fid ~= -1
            if bytesPerSample == 1
                samplesWritten = fwrite(fid, bufferOut.Value(1: samplesPerRecord), 'uint8');
            else
                samplesWritten = fwrite(fid, bufferOut.Value(1: samplesPerRecord), 'uint16');
            end
            if samplesWritten ~= samplesPerRecord
                fprintf('Error: Write record %u failed\n', record);
                success = false;
            end
        end

        if plotData
            plot(bufferOut.Value);
        end
        record
        pause(1);
    end
end % next record

% Release the buffer
retCode = AlazarFreeBuffer(boardHandle, pbuffer);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarFreeBuffer failed -- %s\n', errorToText(retCode));
end
clear pbuffer;

% Close the data file
if fid ~= -1
    fclose(fid);
end