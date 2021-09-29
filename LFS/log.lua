-- log.lua
-- Logging and messaging facility.

--[[
--------------------------------------------------------------------------------
-- AUTHOR:	Tyler Ufen <tyler-github@null.net>
--
-- VERSION:	0.1.3
--
-- DATE:	Sep. 18, 2021.
--
-- LICENSE:	You need permission to use this code.
-- --------------------------------------------------------------------------------
]]--

--[[
-- -------------------------------------------------------------------
-- MODULE DOCUMENTATION
-- -------------------------------------------------------------------
-- DESCRIPTION
--
-- 		This module provides facilities for logging, and messaging.
--
-- USAGE
--
--		log.config ( enabled [, level ][, file ] )
--			enabled		bool		Whether logging is enabled.
--			level		string/		The verbosity, as a string or 
--						number		as a number (default to INFO).
--			file		string		The file to output to (if any).
--
--		log.msg ( message, facility, level )
--			message		string		The log message.
--			facility	string		The source of the message.
--			level		string/		The level of the message.
--						number
--
-- DEPENDENCIES
--
--		log.conf		file		The module's configuration file.
-- 
-- -------------------------------------------------------------------
]]--

module ( 'log', package.seeall )


-- SUPPORT AND CONTROL FUNCTIONS

function log.str2lvl ( level )

	--[[
	----------------------------------------------------------------------------
	--	log.str2lvl ( )
	--
	--	Converts a level string to a level number.
	--
	--	RETURNS
	--
	--	number			The number of the level.
	----------------------------------------------------------------------------
	]]--

	level = string.upper ( level )

	local levels = { 'DEBUG', 'INFO', 'NOTICE', 'WARN', 'WARNING', 'ERR', 'ERROR', 'CRIT', 'CRITICAL', 'ALERT', 'EMERG', 'EMERGENCY' }

	local levelok

	for k, v in pairs ( levels ) do
		if ( level == v ) then
			levelok = true
		end
	end

	if ( levelok ~= true ) then
		print ( '>>> log.str2lvl(): Error: Expecting one of DEBUG, INFO, NOTICE, WARN, WARNING, ERR, ERROR, CRIT, CRITICAL, ALERT, EMERG, or EMERGENCY.' )
	end

	if ( level == 'DEBUG' ) then level = 7
	elseif ( level == 'INFO' ) then level = 6
	elseif ( level == 'NOTICE' ) then level = 5
	elseif ( level == 'WARN' or level == 'WARNING' ) then level = 4
	elseif ( level == 'ERR' or level == 'ERROR' ) then level = 3
	elseif ( level == 'CRIT' or level == 'CRITICAL' ) then level = 2
	elseif ( level == 'ALERT' ) then level = 1
	elseif ( level == 'EMERG' or level == 'EMERGENCY' ) then level = 0 end

	return level

end  -- End of function.


function log.lvl2str ( level )

	--[[
	--		This function converts a level number to a level string.
	--
	--		level		number		The number of the level.
	--
	--		Returns:	string		The string of the level.
	]]--

	if ( type ( level ) == string ) then
		level = tonumber ( level )
	end

	if ( level < 0 or level > 7 ) then
		print ( '>>> log.lvl2str(): Error: Expecting number from 0 to 7, from EMERGENCY to DEBUG.' )
	end

	if ( level == 7 ) then level = 'DEBUG'
	elseif ( level == 6 ) then level = 'INFO'
	elseif ( level == 5 ) then level = 'NOTICE'
	elseif ( level == 4 ) then level = 'WARNING'
	elseif ( level == 3 ) then level = 'ERROR'
	elseif ( level == 2 ) then level = 'CRITICAL'
	elseif ( level == 1 ) then level = 'ALERT'
	elseif ( level == 0 ) then level = 'EMERG' end

	return level

end  -- End of function.


function log.config ( enable, level, file )

	--[[
	--		Configures the messaging facility.
	--
	--		enable		bool		Whether to enable messaging, or not.
	--		[level]		string		The desired verbosity level, defaults 
	--								to INFO.
	--		[file]		string/bool	Whether to log to file, false to switch 
	--								off.
	--
	--		Returns:	nil
	]]--

	if ( enable == nil or enable == true ) then
		system.log.enabled = true
		print ( '>>> log: Info: Messaging facility enabled.' )
	elseif ( enable == false ) then
		system.log.enabled = false
		print ( '>>> log: Info: Messaging facility disabled.' )
	end

	if ( level == nil ) then
		system.log.level = 'INFO'
	elseif ( type ( level ) == 'string' ) then
		system.log.level = string.upper ( level )
	elseif ( type ( level ) == 'number' ) then
		system.log.level = log.lvl2str ( level )
	end

	if ( file == nil or file == false ) then
		system.log.file = false
	elseif ( type ( file ) == 'string' ) then
		system.log.file = file
	end

end  -- End of function.


function log.msg ( message, facility, level )

	--[[
	--		Prints messages for logging or debugging.
	--
	--		Informational messages are printed as: facility: message
	--		whereas other levels' name is also printed: --- LEVEL --- facility: message.
	--
	--		message		string		The message to be printed or logged.
	--		facility	string		The facility where the event occured.
	--		level		string		The severity of the event, follows syslogd.
	--
	--		Depends on LOG (global, bool), and LOGLEVEL (global, number).
	]]--

	if ( system.log.enabled == false ) then
		return nil
	elseif ( log.str2lvl ( level ) <= log.str2lvl ( system.log.level ) ) then

		print ( '>>> ' .. facility .. ': ' .. level .. ': ' .. message )

		if ( type ( system.log.file ) == 'string' ) then

			if ( file.open ( system.log.file ) == nil ) then
				print ( '>>> log: Error: Log file could not be opened, nor created.' )
			end

			file.open ( system.log.file, 'a+' )
			file.writeline ( '>>> ' .. facility .. ': ' .. level .. ': ' .. message )
			file.close ( system.log.file )

		end

	end

	return true

end  -- End of function.


-- PRINT ON MODULE LOAD

print ( '>>> log: Info: Messaging module loaded (disabled by default, run log.config ( ) to enable).' )
print ( '\tlog.config ( enable (bool), [ level (str|int) ], [ file (str) ] ).' )

return log

-- End of file.