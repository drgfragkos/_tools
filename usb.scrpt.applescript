# Get the system logs
try
	set systemLogs to do shell script "log show --style syslog --predicate 'eventMessage contains \"USB\"'"
on error errorMessage
	display dialog "An error occurred while getting the system logs: " & errorMessage buttons {"OK"} default button 1 with icon stop
	return
end try

# Split the logs into lines
set logLines to paragraphs of systemLogs

# Iterate through the log lines
repeat with aLine in logLines
	# Check if the line contains information about a USB device
	if aLine contains "USB" then
		# Split the line into fields
		set logFields to words of aLine
		
		# Extract the device information
		set timeStamp to item 1 of logFields
		set eventMessage to item 3 of logFields
		set deviceName to item 5 of logFields
		set deviceID to item 6 of logFields
		
		# Print the device information in CSV format
		log timeStamp & "," & eventMessage & "," & deviceName & "," & deviceID
	end if
end repeat
