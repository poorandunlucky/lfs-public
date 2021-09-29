-- wlan2.lua
-- Wireless LAN library/module for ESP8266 NodeMCU LFS.

--[[
-- -------------------------------------------------------------------
-- AUTHOR:	Tyler Ufen <tyler-github@null.net>
--
-- VERSION:	0.1.3
--
-- DATE:	Sep. 18, 2021.
--
-- LICENSE:	You need permission to use this code.
-- -------------------------------------------------------------------
]]--

--[[
-- -------------------------------------------------------------------
-- MODULE DOCUMENTATION
-- -------------------------------------------------------------------
-- DESCRIPTION
--
-- 		This module configures wifi, and provides wlan functions.
--
-- BEHAVIOUR
--
--		When initialized, the module creates the wlan global if it
--		isn't already there, and shuts the radio off to preserve
--		power.  The radio becomes configured at the same time as the
--		communications parameters.
--
-- USAGE
--
--		WLAN is configured from a switch function, and a configuration
--		file.
--
--		wlan2.switch ( OFF | AP | STA | STAAP | SUSPEND | RESUME )
--
--			OFF		Shuts off the radio.
--			AP		Configures the radio, and wlan as an access point.
--			STA		Configures the radio, and wlan as a client.
--			STAAP	Configures the radio, and wlan as a client, and an
--					access point on the same channel.
--			SUSPEND	Suspends the radio, and modem.
--			RESUME	Resumes in whatever state it was when suspended.
--
--	DEPENDENCIES
--
--		log					module			Logging, and messaging.
--		config/wlan.conf	file			Configuration option script.
--
--
--	BUGS/LIMITATIONS/TODO
--
--		At this time, the software only remembers one AP to connect to,
--		so moving it around, or using it somewhere where there are multiple
--		antennas on the same SSID might be a problem, but testing for that
--		isn't really possible right now, and this is already way more than
--		is needed in the immediate.
--
--		This should be compiled with luac.cross, and tested for RAM usage...
--
--		wlan2.switch('OFF') has a call that returns -1 in some conditions.

--		The configuration file is only read during module configuration, or
-- 		re-configuration, and isn't read at boot, or resume.  This allows 
--		the use of the ESP's own wifi resume functions.
--
--		This module is largely untested despite its maturity, because it 
--		was never finished, it causes a heap overflow.
--
-- -------------------------------------------------------------------
]]--


-- MODULE INITIALIZATION

module ( 'wlan2', package.seeall )


function wlan2.loadconf ( file )

	--[[
	----------------------------------------------------------------------------
	--	wlan2.loadconf ( [ file ] )
	--
	--	Loads the default configuration file (/config/wlan.conf), or the file 
	--	specified
	--	which creates a variable that holds the configurable options of the 
	--	wlan module.
	--
	--	PARAMETERS
	--
	--	file			file		The configuration file/script that creates 
	--	the variable.
	--								Defaults to /config/wlan.conf.
	--	RETURNS
	--
	--	bool			true on success, false on failure.
	-- ----------------------------------------------------------------------------
	]]--

	-- Load file.

	if ( file == nil ) then
		dofile ( 'config/wlan.conf')
	else
		dofile ( 'file')
	end

	if ( type ( wlanconf ) == 'table' ) then
		log.msg ( 'Configuration file loaded.', 'wlan2.loadconf()', 'DEBUG' )
	else
		log.msg ( 'Unable to load wlan configuration file.', 'wlan2.loadconf()', 'CRIT' )
		return false
	end

	-- Formatting, and sanity checks.

	if ( wlanconf.mode ~= nil ) then
		wlanconf.mode = string.upper ( wlanconf.mode )
	end
	
	if ( wlanconf.phymode ~= nil ) then
		wlanconf.phymode = string.upper ( wlanconf.phymode )
	end

	return true

end  -- End of function.
	
	
function wlan2.cfgradio ( )

	--[[
	-- ----------------------------------------------------------------------------
	--	wlan2.cfgradio ( )
	--
	--	Configures the radio transceiver.
	--
	--	DEPENDS
	--
	--	wlan.conf		file		Loads the WLAN configuration parameters 
	--	variable.
	--
	--	NOTES
	--
	--	wifi.nullmodesleep isn't a configurable options (power).
	-- ----------------------------------------------------------------------------
	]]--

	-- Configure regulatory domain.

	local regdomain = {
		policy = wifi.COUNTRY_AUTO
	}

	if ( wlanconf.regdomain.country ~= nil ) then
		regdomain.country = wlanconf.regdomain.country
	else
		regdomain.country = 'CA'
	end

	if ( wlanconf.regdomain.start_ch ~= nil ) then
		regdomain.start_ch = wlanconf.regdomain.start_ch
	else
		regdomain.start_ch = 1
	end

	if ( wlanconf.regdomain.end_ch ~= nil ) then
		regdomain.end_ch = wlanconf.regdomain.end_ch
	else
		regdomain.end_ch = 13
	end

	wifi.setcountry ( regdomain )
	log.msg ( 'Set transceiver regulatory domain to ' .. regdomain.country .. ' (2.4 GHz channels ' .. regdomain.start_ch .. '-' .. regdomain.end_ch .. ').', 'wlan2.cfgradio()', 'DEBUG' )

	-- Set 802.11 mode (b/g/n).

	if ( wlanconf.phymode == nil ) then
		log.msg ( 'No interface transceiver mode specified (b/g/n), setting defaullts (802.11n for STA, 802.11g for AP/STAAP)...', 'wlan2.cfgradio()', 'INFO' )
		if ( wlanconf.mode == 'STA' ) then
			wlanconf.phymode = 'N'
		elseif ( wlanconf.mode == 'AP' or wlanconf.mode == 'STAAP' ) then
			wlanconf.phymode = 'G'
		end
	end

	if ( wlanconf.phymode == 'B' ) then
		if ( wifi.setphymode ( wifi.PHYMODE_B ) == 1 ) then
			log.msg ( 'Transceiver set to use 802.11b standard.', 'wlan2.cfgradio()', 'DEBUG' )
		else
			log.msg ( 'Unable to configure transceiver interface mode (802.11b).', 'wlan2.cfgradio()', 'ERROR')
			return false
		end
	elseif ( wlanconf.phymode == 'G' ) then
		if ( wifi.setphymode ( wifi.PHYMODE_G ) == 2 ) then
			log.msg ( 'Transceiver set to use 802.11g standard.', 'wlan2.cfgradio()', 'DEBUG' )
		else
			log.msg ( 'Unable to configure transceiver interface mode (802.11g).', 'wlan2.cfgradio()', 'ERROR')
			return false
		end
	elseif ( wlanconf.phymode == 'N' ) then
		if ( wlanconf.mode == 'STA' ) then
			if ( wifi.setphymode ( wifi.PHYMODE_N ) == 3 ) then
				log.msg ( 'Transceiver set to use 802.11n standard.', 'wlan2.cfgradio()', 'DEBUG' )
			else
				log.msg ( 'Unable to configure transceiver interface mode (802.11n).', 'wlan2.cfgradio()', 'ERROR')
				return false
			end
		else
			log.msg ( 'Unable to use 802.11n standard in AP, or STAAP mode.', 'wlan2.cfgradio()', 'ERROR' )
			return false
		end
	end

	-- Set power.

	if ( wlanconf.power ~= nil ) then
		local pwr = math.ceil ( 82 / 100 * wlanconf.power )
		wifi.setmaxtxpower ( pwr )
		log.msg ( 'Wifi radio power set to ' .. pwr * 0.25 .. ' dBm.', 'wlan2.cfgradio()', 'DEBUG' )
	else
		wifi.setmaxtxpower ( 82 )
		log.msg ( 'Wifi radio power set to maximum: ' .. 82 * 0.25 .. ' dBm (default).', 'wlan2.cfgradio()', 'DEBUG' )
	end

	if ( wlanconf.deepsleep == false ) then
		wifi.nullmodelseep ( false )
		log.msg ( 'Radio null mode sleep turned off for faster reconnects, increased power usage.', 'wlan.cfgradio()', 'DEBUG' )
	end

	return true

end  -- End of function.


function wlan2.stacfg ( )

	--[[
	----------------------------------------------------------------------------
	--	wlan2.stacfg ( )
	--
	--	Configures the client side of the wi-fi module.
	--
	--	NOTES
	--
	--	The ESP8266EX has persistent wifi configuration, so this should only be 
	--	called when settings have changed.
	--
	--	RETURNS
	--
	--	bool			true on success, false on failure.
	-- ----------------------------------------------------------------------------
	]]--

	if ( wlanconf == nil ) then
		log.msg ( 'wlan configuration file not loaded.', 'wlan2.stacfg()', 'ERROR' )
		return false
	end

	-- Clear all previous settings.

	wifi.sta.clearconfig ( )
	log.msg ( 'Wifi STA settings cleared.', 'wlan2.stacfg()', 'DEBUG' )

	-- Configure STA mode options.

	wifi.sta.setaplimit ( wlanconf.sta.rememberap )

	--??  _G.wlan2.sta.reconnect = wlanconf.sta.auto || if save and this are true, set timer from callback function to try and reconnect every so often

	wifi.sta.sethostname ( wlanconf.sta.hostname )
	log.msg ( 'Hostname set to ' .. wlanconf.sta.hostname, 'wlan2.stacfg()', 'INFO' )

	if ( wlanconf.sta.ip ~= nil ) then
		wifi.sta.setip ( wlanconf.sta.ip )
		if ( wifi.sta.getip ( ) == wlanconf.sta.ip.ip ) then
			log.msg ( 'Client interface IPv4 configured.', 'wlan2.stacfg()', 'INFO' )
			log.msg ( 'IP: ' .. wlanconf.sta.ip.ip .. ' Netmask: ' .. wlanconf.sta.ip.netmask .. ' Gateway: ' .. wlanconf.sta.ip.gateway, 'wlan2.stacfg()', 'INFO' )
		else
			log.msg ( 'Unable to configure client interface IPv4.', 'wlan2.stacfg()', 'ERROR' )
			return false
		end
	end

	if ( wlanconf.sta.mac ~= nil ) then

		if ( wifi.sta.setmac ( wlanconf.sta.mac ) == false ) then
			log.msg ( 'Unable to set STA interface MAC.', 'wlan.stacfg()', 'ERROR' )
			return False
		else
			log.msg ( 'STA interface MAC set to ' .. wifi.sta.getmac() .. '.', 'wlan.stacfg()', 'INFO' )
		end

	end

	if ( wlanconf.deepsleep == nil ) then
		wifi.sta.sleeptype ( wifi.NONE_SLEEP )
		log.msg ( 'Disabled sleep.', 'wlan.stacfg()', 'DEBUG' )
	elseif ( wlanconf.deepsleep == false ) then
		wifi.sta.sleeptype ( wifi.LIGHT_SLEEP )
		log.msg ( 'Light sleep enabled.', 'wlan.stacfg()', 'DEBUG' )
	elseif ( wlanconf.deepsleep == true ) then
		wifi.sta.sleeptype ( wifi.MODEM_SLEEP )
		log.msg ( 'Deep sleep enabled.', 'wlan.stacfg()', 'DEBUG' )
	end

	local stacfg = {
		ssid = wlanconf.sta.ssid,
		pwd = wlanconf.sta.key,
		save = wlanconf.sta.save
	}

	if ( wlanconf.sta.autoconnect ~= nil ) then stacfg.auto = wlanconf.sta.autoconnect end
	if ( wlanconf.sta.bssid ~= nil ) then stacfg.bssid = wlanconf.sta.bssid end

	if ( wifi.sta.config ( stacfg ) == true ) then
		log.msg ( 'Wifi successfully configured.', 'wlan2.stacfg()', 'DEBUG' )
		if ( wlanconf.sta.autoconnect == false ) then
			log.msg ( 'Autoconnect disabled; use wifi.sta.connect() to connect to AP.', 'wlan', 'INFO' )
		else
			log.msg ( 'Trying to autoconnect to AP...', 'wlan2.stacfg()', 'DEBUG' )
		end
	else
		log.msg ( 'Unable to configure wifi.', 'wlan2.stacfg()', 'ERROR' )
		return false
	end

	log.msg ( 'Configured wi-fi client parameters.', 'wlan2.stacfg()', 'DEBUG' )

	return true

end  -- End of function.


function wlan2.apcfg ( )

	--[[
	----------------------------------------------------------------------------
	--	wlan.apcfg ( )
	--
	--	Configures the access point, and DHCP server.
	--
	--	RETURNS
	--
	--	bool			true on success, false on failure.
	--	----------------------------------------------------------------------------
	]]--

	if ( wlanconf == nil ) then
		log.msg ( 'wlan configuration file not loaded.', 'wlan2.apcfg()', 'ERROR' )
		return false
	end
	
	if ( wlanconf.ap.ip ~= nil ) then

		local apipcfg = { wlanconf.ap.ip, wlanconf.ap.netmask, wlanconf.ap.gateway }

		if ( wifi.ap.setip ( apipcfg ) == false ) then
			log.msg ( 'Unable to configure access point IPv4.', 'wlan2.apcfg()', 'ERROR' )
			return false
		else
			log.msg ( 'Set access point IPv4.', 'wlan.apcfg()', 'INFO' )
			local apip, apnm, apgw = wifi.ap.getip ( )
			log.msg ( 'IP: ' .. apip .. ' Netmask: ' .. apnm .. ' Gateway: ' .. apgw, 'wlan.apcfg()', 'INFO' )
		end

	end

	if ( wlanconf.ap.mac ~= nil ) then

		if ( wifi.ap.setmac ( wlanconf.ap.mac ) == false ) then
			log.msg ( 'Unable to set AP interface MAC.', 'wlan.apcfg()', 'ERROR' )
			return False
		else
			log.msg ( 'Access point interface MAC set to ' .. wifi.ap.getmac() .. '.', 'wlan.apcfg()', 'INFO' )
		end

	end

	if ( wlanconf.ap.dhcpstart ~= nil ) then

		local apdhcpcfg = { }
		apdhcpcfg.start = wlanconf.ap.dhcpstart

		if ( string.sub ( wifi.ap.dhcp.config ( apdhcpcfg ), 1, 7 ) ~= string.sub ( wlanconf.ap.dhcpstart, 1, 7 ) ) then
			log.msg ( 'Unable to configure DHCP server.', 'wlan2.apcfg()', 'ERROR' )
			return false
		else
			log.msg ( 'DHCP start address set to ' .. wlanconf.ap.dhcpstart .. ' (default: 4 clients max).', 'wlan.apcfg()', 'INFO' )
		end
	end

	local apcfg = {
		ssid = wlanconf.ap.ssid,
		auth = wifi.WPA2_PSK,
		hidden = wlanconf.ap.hidden,
		save = wlanconf.ap.save,
		beacon = 250,
		max = wlanconf.ap.maxclients
	}

	if ( wlanconf.ap.key ~= nil ) then
		apcfg.pwd = wlanconf.ap.key
	else
		log.msg ( 'No WPA key set, access point is open!', 'wlan.apcfg()', 'NOTICE' )
	end

	if ( wlanconf.ap.channel ~= nil ) then
		apcfg.channel = wlanconf.ap.channel
		log.msg ( 'Access point radio set to channel ' .. wlanconf.ap.channel, 'wlan.apcfg()', 'DEBUG' )
	end

	if ( wifi.ap.config ( apcfg ) == false ) then
		log.msg ( 'Unable to configure access point.', 'wlan.apcfg()', 'CRIT' )
		return false
	else
		log.msg ( 'Access point configured.', 'wlan.apcfg()', 'DEBUG' )
	end

	if ( wifi.ap.dhcp.start ( ) == false ) then
		log.msg ( 'DHCP server failed to start.', 'wlan.apcfg()', 'ERROR' )
		return false
	else
		log.msg ( 'DHCP server started.', 'wlan.apcfg()', 'DEBUG' )
	end

	return true

end  -- End of function.




function wlan2.switch ( mode )

	--[[
	----------------------------------------------------------------------------
	--	wlan2.switch ( [ mode ] )
	--
	--	Switches between the various wi-fi modes.  Prints the current status 
	--	when run
	--	with no arguments.
	--
	--	PARAMETERS
	--
	--	mode			string		OFF: Switches the radio, and modem off.
	--								STA: Configures modem as a client.
	--								AP: Configures the modem as an access point.
	--								STAAP: Configures the modem as a wireless 
	--								bridge.
	--								SUSPEND: Suspends wi-fi operations.
	--								RESUME: Resumes wi-fi operations.
	--
	--	NOTES
	--
	--	See the arga = nil section for something to do.
	--
	--	RETURNS
	--
	--	bool			true on success, false on failure.
	--	----------------------------------------------------------------------------
	]]--


	-- Print help, and exit if no arguments.

	if ( mode == nil ) then
		print ( 'wlan2.switch ( OFF | STA | AP | STAAP | SUSPEND | RESUME )' )
		return false
	end

	-- Check if log module is loaded.

	if ( _G.package.loaded.log == nil ) then
		print ( '>>> wlan: Error: Had to load log module.' )
		if ( type ( require ( 'log' ) ) ~= table ) then
			print ( '>>> wlan: Error: Unable to load log module. Exiting.')
			return false
		end
	end

	-- Check if module global is initialized.

	if ( system.wlan == nil ) then
		if ( system == nil ) then
			system = { }
			log.msg ( 'System global variable (system) did not exist.', 'wlan', 'ERROR' )
		end
		system.wlan = { }
		log.msg ( 'Module global (system.wlan) did not exist.', 'wlan', 'ERROR' )
	end

	-- Sanity-check argument.

	mode = string.upper ( mode )
	local modes = { 'OFF', 'STA', 'AP', 'STAAP', 'SUSPEND', 'RESUME' }
	for k, v in pairs ( modes ) do
		if ( mode ~= v ) then
			local argok = false
		end
	end
	if ( argok ~= nil ) then
		log.msg ( 'Argument must be either OFF, STA, AP, STAAP, SUSPEND, or RESUME.', 'wlan2.switch()', 'ERROR' )
		return false
	end

--[[	-- Make sure callbacks are registered.

	if ( _G.wlan2.cbreg ~= true ) then
		if ( wlan2.regcb ( ) == true ) then
			log.msg ( 'Callbacks registered.', 'wlan2.cfgradio()', 'DEBUG' )
			_G.wlan['cbreg'] = true
		else
			log.msg ( 'Unable to register callbacks.', 'wlan2.switch()', 'ERROR' )
			return false
		end
	end]]--

	-- Switches for the various modes.

	if ( mode == 'OFF' ) then

		wlan2.loadconf ( )

		if ( wifi.nullmodesleep ( true ) == false ) then
			log.msg ( 'Unable to enable nullmodesleep.', 'wlan2.switch()', 'ERROR' )
		end

		if ( wifi.setmode ( wifi.NULLMODE, wlanconf.save ) ~= 0 ) then
			log.msg ( 'Unable to put radio to sleep...', 'wlan2.switch()', 'CRITICAL' )
			return false
		end

		log.msg ( 'Wifi is off, and will need to be reconfigured.  If you want to suspend, use wlan.syspend() and wlan.resume() next time.', 'wlan2.switch()', 'INFO' )

		wlanconf = nil

		return true

	elseif ( mode == 'STA' ) then

		wlan2.loadconf ( )

		if ( wifi.setmode ( wifi.STATION, wlanconf.sta.save ) ~= 1 ) then
			log.msg ( 'Unable to configure modem as client.', 'wlan2.switch()', 'CRITICAL' )
			return false
		end
		if ( wlan2.stacfg ( ) ~= true ) then
			log.msg ( 'Unable to configure client connection parameters.', 'wlan2.switch()', 'CRITICAL' )
		end
		if ( wlanconf.sta.autoconnect == false ) then
			log.msg ( 'sta.autoconnect set to false in wlan.conf, you need to manually call wifi.sta.connect() to connect to AP.', 'wlan2.switch()', 'INFO' )
		end

		wlanconf = nil

		log.msg ( 'Wi-Fi: Entered client mode.', 'wlan2.switch().', 'DEBUG' )

		return true

	elseif ( mode == 'AP' ) then

		wlan2.loadconf ( )

		if ( wifi.setmode ( wifi.SOFTAP, wlanconf.ap.save ) ~= 2 ) then
			log.msg ( 'Unable to configure modem to access point.', 'wlan2.switch()', 'CRITICAL' )
			return false
		end

		if ( wlan2.apcfg ( ) ~= true ) then
			log.msg ( 'Unable to configure access point parameters.', 'wlan2.switch()', 'CRITICAL' )
		end

		wlanconf = nil

		log.msg ( 'Wi-Fi: Entered access point mode.', 'wlan2.switch().', 'DEBUG' )

		return true

	elseif ( mode == 'STAAP' ) then

		wlan2.loadconf ( )

		if ( wifi.setmode ( wifi.STATIONAP, wlanconf.ap.save ) ~= 3 ) then
			log.msg ( 'Unable to configure modem to Station + AP.', 'wlan2.switch()', 'CRITICAL' )
			return false
		end

		if ( wlan2.stacfg ( ) ~= true ) then
			log.msg ( 'Unable to configure STAAP \'STA\' connection parameters.', 'wlan2.switch()', 'CRITICAL' )
		end

		if ( wlanconf.sta.autoconnect == false ) then
			log.msg ( 'sta.autoconnect set to false in wlan.conf, you need to manually call wifi.sta.connect() to connect to AP.', 'wlan2.switch()', 'INFO' )
		end

		if ( wlan2.apcfg ( ) ~= true ) then
			log.msg ( 'Unable to configure STAAP \'AP\' parameters.', 'wlan2.switch()', 'CRITICAL' )
		end

		wlanconf = nil

		log.msg ( 'Wi-Fi: Entered client + access point mode.', 'wlan2.switch().', 'DEBUG' )

		return true

	elseif ( mode == 'SUSPEND' ) then

		wlan2.suspend ( )

	elseif ( mode == 'RESUME' ) then

		wlan2.resume ( )

	end

	return true

end  -- End of function.


function wlan2.reset ( type )

node.restore ( )
wlanconf = nil
log.msg ( 'All wifi-related settings have been cleared', 'wlan2.switch()', 'DEBUG' )

end  -- End of function.


return wlan2
