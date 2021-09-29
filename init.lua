-- init.lua
-- NodeMCU autorun script.

--[[
--	DESCRIPTION
--
--		This file runs after _init from LFS if it's installed.  Its 
--		purpose is mainly to install the LFS image on boot if it's 
--		present, and delete it otherwise after reboot.
--
--	BEHAVIOUR
--
--		If it boots and a file called LFS.img is present, it tries to install 
--		it, and creates a file called _lfs-installed to prevent a boot loop.
--		If that installation token/cookie is present on boot, then it deletes 
--		both the binary LFS image, and the reboot cookie/token so it doesn't 
--		try to install the LFS over, and over again.
--
--		If all that fails, the user should still be thrown back to an 
--		interactive prompt.
--
--	DEPENDENCIES
--
--		None, this could be used to install the LFS for the first time.
--
-- TO DO
--
--		- Rewrite the script that checks for the LFS, installs it, and deals 
--		  with the reboot cookie... it seems kinda messy, not easy to read...
--]]


print ( '>>> init.lua: Initializing...' )


-- INSTALL NEW LFS IMAGE IF PRESENT

--[[  This is kinda messy, maybe not optimal.  Might use a rewrite. ]]--

if ( file.exists ( 'LFS.img' ) == true ) then

	if ( file.exists ( '_lfs-installed' ) == false ) then

		-- Install LFS if a cookie (file) doesn't tell us it's already done.

		print ( '>>> init.lua: New LFS image found, installing...' )
		print ( '>>> init.lua: Creating LFS installation cookie...' )
		local token = file.open ( '_lfs-installed', 'w' )
		file.close ( token )
		local status = node.LFS.reload ( 'LFS.img' )
		if ( type ( status ) == string ) then
			
			-- If there's an error loading the LFS, remove the token.

			print ( '>>> init.lua: Error loading new LFS image: ' .. status .. '.' )
			print ( '>>> init.lua: Removing installation token.' )
			file.remove ( '_lfs-installed' )
			if ( file.exists ( '_lfs-installed' ) == false ) then
				print ( ' >>> init.lua: LFS.img could not be installed, you can try manually by using node.LFS.reload ( "LFS.img" ).  System will reboot if successful.' )
				return false
			end
		end

	else

		-- If the cookie exists, remove both LFS binary, and boot cookie.

		print ( '>>> init.lua: Reboot completed.  New LFS image installed.' )
		print ( '>>> init.lua: Removing LFS binary, and installation token...' )

		file.remove ( 'LFS.img' )

		if ( file.exists ( 'LFS.img' ) == false ) then
			print ( '>>> init.lua: Removed LFS.img.' )
			file.remove ( '_lfs-installed' )
			if ( file.exists ( '_lfs-installed' ) == false ) then
				print ( '>>> init.lua: Removed reboot cookie.' )
			else
				print ( '>>> init.lua: Could not remove reboot cookie.' )
			end
		else
			print ( '>>> init.lus: Could not remove LFS.img' )
			print ( '>>> init.lus: Making sure reboot cookie is present to prevent boot loops...' )
			if ( file.exists ( '_lfs-installed' ) == false ) then
				local token = file.open ( '_lfs-installed', 'w' )
				file.close ( token )
			else
				print ( '>>> init.lua: Reboot cookie written.' )
				print ( '>>> Error: init.lua: Please try to remove LFS.img and _lfs-installed manually, re-upload the image, and try again.' )
			end
		end
	end

end  -- End of statement.


-- LOAD CONFIGURATION FILE

-- This is done in _init.lua (LFS), but also here in case, or for 
-- debug/development...

if ( system == nil ) then

	print ( '>>> init.lua: Error: init.conf was not already loaded.' )
	dofile ( 'config/init.conf' )
	print ( '>>> init.lua: Info: Running init.conf...' )

	if ( system == nil ) then
		print ( '>>> init.lua: Critical: Could not run init.conf!' )
	end

end  

-- End of section.


-- LOAD, CONFIGURE, AND START MODULES

--[[ Logging ]]--

if ( system.log.enabled ~= nil ) then

	print ( '>>> init.lua: Info: Loading logging module...' )

	require ( 'log' )
	
	if ( _G.package.loaded.log == nil ) then
		print ( '>>> init.lua: Error: Could not load messaging module.')
	else
		if ( system.boot.dev_build == true ) then
			log.config ( true, 'DEBUG', false )
		else
			if ( system.log.enabled == true ) then
				log.config ( true, system.log.level, system.log.file )
			else
				log.config ( false )
			end
		end
	end

end

--[[ WLAN ]]--

print ( '>>> init.lua: Info: Loading wlan module...' )

if ( sytem.wlan.enable == true ) then
require ( 'wlan' )
end

if ( _G.package.loaded.wlan == nil ) then
	log.msg ( 'Could not load wlan module.', 'init.lua', 'ERROR' )
else
	if ( sytem.wlan.enable == true ) then
		wlan.loadconf ( )	
		wlan.switch ( wlanconf.mode )
		wlanconf = nil
	else
		wlan.switch ( 'OFF' )
	end
end

--[[ wlan2 ]]--

if ( _G.package.loaded.wlan2 == nil ) then
	log.msg ( 'Could not load wlan2 module.', 'init.lua', 'ERROR' )
else
	if ( sytem.wlan2.enable == true ) then
		wlan2.loadconf ( )	
		wlan2.switch ( wlanconf.mode )
		wlanconf = nil
	else
		wlan2.switch ( 'OFF' )
	end
end

--[[ Thermistor ]]--

if ( system.thermistor.enabled == true ) then
	require ( 'thermistor' )
end

-- End of section.


print ( '>>> init.lua: Info: Script completed.' )

-- End of File.