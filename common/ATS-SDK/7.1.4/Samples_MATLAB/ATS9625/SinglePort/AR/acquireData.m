function [result] = acquireData(boardHandle)
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
preTriggerSamples = 1024;

%TODO: Select the number of post-trigger samples per record
postTriggerSamples = 1024;

% TODO: Select the number of records in the acquisition
recordsPerCapture = 100;

% TODO: Select the amount of time, in seconds, to wait for a trigger
timeout_sec = 10;

% TODO: Select if you wish to save the sample data to a binary file
saveData = false;

% TODO: Select if you wish to plot the data to a chart
plotData = false;

% TODO: Select which channels read from on-board memory (A, B, or both)
channelMask = CHANNEL_A + CHANNEL_B;

% Calculate the number of enabled channels from the channel mask
channelCount = 0;
channelsPerBoard = 2;
for channel = 0:channelsPerBoard - 1
    channelId = 2^channel;
    if bitand(channelId, channelMask)
        channelCount = channelCount + 1;
    end
end

if (channelCount < 1) || (channelCount > channelsPerBoard)
    fprintf('Error: Invalid channel mask %08X\n', channelMask);
    return
end

% Get the sample and memory size
[retCode, boardHandle, maxSamplesPerRecord, bitsPerSample] = calllib('ATSApi', 'AlazarGetChannelInfo', boardHandle, 0, 0);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarGetChannelInfo failed -- %s\n', errorToText(retCode));
    return;
end

% Calculate the size of each record in bytes
bytesPerSample = floor((double(bitsPerSample) + 7) / double(8));
samplesPerRecord = uint32(preTriggerSamples + postTriggerSamples);
if samplesPerRecord > maxSamplesPerRecord
    samplesPerRecord = maxSamplesPerRecord;
end
bytesPerRecord = double(bytesPerSample) * samplesPerRecord;

% The buffer must be at least 16 samples larger than the transfer size
samplesPerBuffer = samplesPerRecord + 16;
bytesPerBuffer = samplesPerBuffer * bytesPerSample;

% Set the number of samples per record
retCode = AlazarSetRecordSize(boardHandle, preTriggerSamples, postTriggerSamples);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarSetRecordSize failed -- %s\n', errorToText(retCode));
    return;
end

% Set the number of records in the acquisition
retCode = AlazarSetRecordCount(boardHandle, recordsPerCapture);
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

% Create progress window
waitbarHandle = waitbar(0, ...
                        sprintf('Captured 0 of %u records', recordsPerCapture), ...
                        'Name','Capturing ...', ...
                        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
setappdata(waitbarHandle, 'canceling', 0);

% Wait for the board to capture all records to on-board memory
fprintf('Capturing %u records ...\n', recordsPerCapture);

tic;
updateTic = tic;
updateInterval_sec = 0.1;
captureDone = false;
triggerTic = tic;
triggerCount = 0;

while ~captureDone
    if ~AlazarBusy(boardHandle)
        % The capture to on-board memory is done
        captureDone = true;
    elseif toc(triggerTic) > timeout_sec
        % The acquisition timeout expired before the capture completed
        % The board may not be triggering, or the capture timeout may be too short.
        fprintf('Error: Capture timeout after %.3f sec -- verify trigger.\n', timeout_sec);
        break;
    elseif toc(updateTic) > updateInterval_sec
        updateTic = tic;
        % Check if the waitbar cancel button was pressed
        if getappdata(waitbarHandle,'canceling')
            break
        end
        % Get the number of records captured = triggers received
        [retCode, boardHandle, recordsCaptured] = AlazarGetParameter(boardHandle, 0, GET_RECORDS_CAPTURED, 0);
        if retCode ~= ApiSuccess
            fprintf('Error: AlazarGetParameter failed -- %s\n', errorToText(retCode));
            break;
        end
        if triggerCount ~= recordsCaptured
            % Update the waitbar progress
            waitbar(double(recordsCaptured) / double(recordsPerCapture), ...
                    waitbarHandle, ...
                    sprintf('Captured %u of %u records', recordsCaptured, recordsPerCapture));
            % Reset the trigger timeout counter
            triggerCount = recordsCaptured;
            triggerTic = tic;
        end
    else
        % Wait for triggers
        pause(0.01);
    end
end

% Close progress bar
delete(waitbarHandle);

if ~captureDone
    % Abort the acquisition
    retCode = AlazarAbortCapture(boardHandle);
    if retCode ~= ApiSuccess
        fprintf('Error: AlazarAbortCapture failed -- %s\n', errorToText(retCode));
    end
    return;
end

% The board captured all records to on-board memory
captureTime_sec = toc;
if captureTime_sec > 0.
    recordsPerSec = recordsPerCapture / captureTime_sec;
else
    recordsPerSec = 0.;
end
fprintf('Captured %u records in %g sec (%.4g records / sec)\n', recordsPerCapture, captureTime_sec, recordsPerSec);

% Create a buffer to store a record
pbuffer = AlazarAllocBuffer(boardHandle, bytesPerBuffer + 16);
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

% Create progress window
waitbarHandle = waitbar(0, ...
                        sprintf('Transferred 0 of %u records', recordsPerCapture), ...
                        'Name','Reading ...', ...
                        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
setappdata(waitbarHandle, 'canceling', 0);

% Transfer the records from on-board memory to our buffer
fprintf('Transferring %u records ...\n', recordsPerCapture);

tic;
updateTic = tic;
bytesTransferred = 0;
success = true;

for record = 0 : recordsPerCapture - 1
    for channel = 0 : channelsPerBoard - 1
        % Find channel Id from channel index
        channelId = 2 ^ channel;

        % Skip this channel if it's not in channel mask
        if ~bitand(channelId,channelMask)
            continue;
        end

        % Transfer one full record from on-board memory to our buffer
        [retCode, boardHandle, bufferOut] = ...
            AlazarRead(...
                boardHandle,            ...	% HANDLE -- board handle
                channelId,              ...	% U32 -- channel Id
                pbuffer,                ...	% void* -- buffer
                bytesPerSample,         ...	% int -- bytes per sample
                record + 1,             ... % long -- record (1 indexed)
                -int32(preTriggerSamples),   ...	% long -- offset from trigger in samples
                samplesPerRecord		...	% U32 -- samples to transfer
                );
        if retCode ~= ApiSuccess
            fprintf('Error: AlazarRead record %u failed -- %s\n', record, errorToText(retCode));
            success = false;
        else
            bytesTransferred = bytesTransferred + bytesPerRecord;

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
            %
            % Sample codes are unsigned by default. As a result:
            % - a sample code of 0x0000 represents a negative full scale input signal.
            % - a sample code of 0x8000 represents a ~0V signal.
            % - a sample code of 0xFFFF represents a positive full scale input signal.

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
        end

        if ~success
            break;
        end

    end % next channel

    if toc(updateTic) > updateInterval_sec
        % Check if waitbar cancel button was pressed
        if getappdata(waitbarHandle,'canceling')
            break
        end
        % Update progress
        waitbar(double(record) / double(recordsPerCapture), ...
                waitbarHandle, ...
                sprintf('Transferred %u of %u records', record, recordsPerCapture));
        updateTic = tic;
    end

end % next record

% Close progress bar
delete(waitbarHandle);

% Release the buffer
retCode = AlazarFreeBuffer(boardHandle, pbuffer);
if retCode ~= ApiSuccess
    fprintf('Error: AlazarFreeBuffer failed -- %s\n', errorToText(retCode));
end
clear pbuffer;

% Display results
transferTime_sec = toc;
if transferTime_sec > 0.
    bytesPerSec = bytesTransferred / transferTime_sec;
else
    bytesPerSec = 0.;
end
fprintf('Transferred %d bytes in %g sec (%.4g bytes per sec)\n', bytesTransferred, transferTime_sec, bytesPerSec);

% Close the data file
if fid ~= -1
    fclose(fid);
end

result = true;