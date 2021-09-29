-- _init.lua
-- NodeMCU LFS boot script.

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
--	DESCRIPTION
--
--		This file runs at boot, and runs init.lua from SPIFFS at the end.
--		If the LFS, or this file don't exist, init.lua from SPIFFS is ran 
--		at boot instead with no errors.  The running of this file at boot 
--		is 
--
--	DEPENDENCIES
--
--		log					module			Logging, and messaging.
--		config/wlan.conf	file			Configuration option script.
--]]

-- RUN INIT CONFIGURATION FILE

dofile ( 'config/init.conf' )
print ( '>>> _init.lua (LFS): Info: Running init.conf...' )

if ( system == nil ) then
	print ( '>>> _init.lua (LFS): Error: init.conf did not run successfully.' )
end


-- SET CPU FREQUENCY IF REQUIRED

if ( system.boot.cpufreq == 160 ) then
	if ( node.setcpufreq ( node.CPU160MHZ ) ~= 160 ) then
		print ( '>>> _init.lua (LFS): Error: Unable to set CPU frequency.' )
	else
		print ( '>>> _init.lua (LFS): Info: Set CPU frenquency to 160 MHz.' )
	end
end


-- PRINT SYSTEM INFORMATION IF DEVELOPMENT VERSION

if ( system.boot.dev_build == true ) then

	local lfsinit = { }

	-- BOOT CODES

	lfsinit.boot = { }
	lfsinit.boot.raw = { }
	lfsinit.boot.dodo = { }
	lfsinit.boot.reason = { }
	lfsinit.boot.ext = { }

	lfsinit.boot.raw.code, lfsinit.boot.reason.code, lfsinit.boot.ext.cause, lfsinit.boot.ext.epc1,
	lfsinit.boot.ext.epc2, lfsinit.boot.ext.epc3, lfsinit.boot.ext.vaddr, lfsinit.boot.ext.depc = node.bootreason ( )

	if ( lfsinit.boot.raw.code == 1 ) then lfsinit.boot.raw.desc = 'Power On' end
	if ( lfsinit.boot.raw.code == 2 ) then lfsinit.boot.raw.desc = 'Software Reset' end
	if ( lfsinit.boot.raw.code == 3 ) then lfsinit.boot.raw.desc = 'Hardware Reset' end
	if ( lfsinit.boot.raw.code == 4 ) then lfsinit.boot.raw.desc = 'Watchdog Timeout Reset' end

	if ( lfsinit.boot.reason.code == 0 ) then lfsinit.boot.reason.desc = 'Power On' end
	if ( lfsinit.boot.reason.code == 1 ) then lfsinit.boot.reason.desc = 'Hardware Watchdog Reset' end
	if ( lfsinit.boot.reason.code == 2 ) then lfsinit.boot.reason.desc = 'Exception Reset' end
	if ( lfsinit.boot.reason.code == 3 ) then lfsinit.boot.reason.desc = 'Software Watchdog Reset' end
	if ( lfsinit.boot.reason.code == 4 ) then lfsinit.boot.reason.desc = 'Software Restart' end
	if ( lfsinit.boot.reason.code == 5 ) then lfsinit.boot.reason.desc = 'Wake From Deep Sleep' end
	if ( lfsinit.boot.reason.code == 6 ) then lfsinit.boot.reason.desc = 'External Reset' end

	-- HARDWARE AND FIRMWARE INFO

	lfsinit.hw = { }
	lfsinit.partbl = { }
	lfsinit.flash = { }
	lfsinit.version = { }

	lfsinit.hw = node.info ( 'hw' )
	lfsinit.version = node.info ( 'sw_version' )
	lfsinit.build_config = node.info ( 'build_config' )

	lfsinit.cpu = node.getcpufreq ( )
	lfsinit.heap = node.heap ( )
	lfsinit.partbl = node.getpartitiontable ( )
	lfsinit.egcalloc, lfsinit.egcused = node.egc.meminfo ( )
	lfsinit.dsleep_max = node.dsleepMax ( )

	-- OUTPUT SYSTEM INFORMATION

	print ( '\n\n' )
	print ( 'Partition Table: \n\t' .. 'LFS Address: ' .. lfsinit.partbl.lfs_addr .. '\n\tLFS Size: ' .. lfsinit.partbl.lfs_size .. '\n\tSPIFFS Address: ' .. lfsinit.partbl.spiffs_addr .. '\n\tSPIFFS Size: ' .. lfsinit.partbl.spiffs_size )
	print ( '\n\n' )
	print ( "NodeMCU: Booting..." )

	if ( dev_build == true ) then  -- Prints ESP SDK debug info, must build with DEVELOPMENT_TOOLS.
		print ( '>>> DEVELOPMENT FIRMWARE' )
	end

	print ( "NodeMCU Version: " .. lfsinit.version.node_version_major .. '.' .. lfsinit.version.node_version_minor .. '.' .. lfsinit.version.node_version_revision .. ' (' .. lfsinit.version.git_release ..').' )
	print ( "Boot Code: " .. lfsinit.boot.raw.desc .. ", " .. lfsinit.boot.reason.desc .. '.' )
	if ( lfsinit.boot.ext.cause ~= nil ) then
		print ( '>>> EXTENDED (Lv.3) BOOT CAUSE ' .. lfsinit.boot.ext.cause .. '.' )
	end
	print ( 'Max Sleep: ' .. lfsinit.dsleep_max )
	print ( "Chip ID: " .. lfsinit.hw.chip_id .. " .. 'Flash ID: " .. lfsinit.hw.flash_id )
	print ( "Flash Size: " .. lfsinit.hw.flash_size .. " Flash Mode: " .. lfsinit.hw.flash_mode .. " Flash Speed (Hz): " .. lfsinit.hw.flash_speed )
	print ( "CPU Frequency: " .. lfsinit.cpu )
	if ( dev_build == true ) then  -- Prints ESP SDK debug info, must build with DEVELOPMENT_TOOLS.
		print ( 'Allowing output of ESP SDK debug info...' )
		--node.osprint ( true )  -- Causes error if not built-in.
		print ( '-- Not yet implemented.' )
	end
	print ( "NodeMCU: Setting emergency garbage collector to run on allocation failure..." )
	node.egc.setmode ( node.egc.ON_ALLOC_FAILURE )
	print ( "EGC Allocated: " .. lfsinit.egcalloc .. " EGC Used: " .. lfsinit.egcused )
	print ( 'Build Type: ' .. lfsinit.build_config.number_type .. '.' )
	print ( 'SSL: ' .. tostring ( lfsinit.build_config.ssl ) .. '.' )
	print ( 'Modules: ' .. lfsinit.build_config.modules .. '.' )
	print ( "Heap size: " .. node.heap ( ) )

end  -- End of statement.


-- ADD LFS TO MODULE LOADERS' SEARCH LOCATIONS

local function addLoader ( index )

   --[[
	--		This function adds the LFS to one of four indexes that get searched 
	--		in turn until a result is found, and the search stops.
	--		SPIFFS is in index 2, so by putting the LFS in index 3, if a module 
	--		is present in both SPIFFS, and LFS: the module in SPIFFS will be 
	--		loaded.  This can be useful in development, to work on modules 
	--		without having to recompile the LFS every time.
	--
	--		index		number		The search index where the LFS should be.
	--								1 is before SPIFFS, 3 after, so 1 or 3.
	--
	--		See repo /docs/lfs.md:148 for more information on package.loaders.
	]]--

	package.loaders[index] = function ( modname )

		--[[
		--		This is a NodeMCU replacement for package.searchers().  It 
		--		searches one of four locations for a module of 'modname', where 
		--		SPIFFS is in location 2, and LFS is in location 'index' (either
		--		1 or 3/4).
		--
		--		index		number		The LFS position in the module search.
		--		modname		string		The desired module.
		--
		--		Returns:	function	On success.
		--					false		On failure.
		]]--

		local module = node.LFS.get ( modname )

		if ( type ( module ) == 'function' ) then
			return module
		elseif ( module == nil ) then
			if ( _G.log ~= nil ) then
				log.msg ( 'Module ' .. modname .. ' could not be found in LFS.', 'ERROR', '')
				print ( '>>> LFS: Error: Module ' .. modname .. ' could not be found in LFS.' )
				return false
			end
		end

	end

end  -- End of function.


-- SET PACKAGE LOADER SEARCH INDEX

--[[
--		For security, and convenience, the LFS normally gets searched for 
--		modules before the SPIFFS, but during development, it might be more 
--		convenient to search for modules from SPIFFS first so they can be 
--		uploaded to SPIFFS without having to rewrite the LFS every time.
]]

print ( '>>> _init.lua (LFS): Adding LFS to module locations search index...' )

local lfsindex

if ( dev_build == true ) then
	lfsindex = 3
else
	lfsindex = 1
end

if ( addLoader ( lfsindex ) ~= false ) then
	print ( '>>> _init.lua (LFS): LFS added to search index ' .. lfsindex .. '.' )
else
	print ( '>>> _init.lua (LFS): Could not add LFS to package.loaders().' )
end


-- RETURN TO SPIFFS

--[[
--		Note: This _init.* file is ran first as specified in
--		user_config.h.  It's the only reason we're allowed to
--		access the LFS at all, I think.
]]--

print ( '>>> _init (LFS): LFS initialization completed; returning to SPIFFS...' )

dofile ( 'init.lua' )


-- End of file.