<p><h1><span style="font-size: 36px; color: #339966;"><strong>Guild</strong></span>&nbsp;<span style="font-size: 36px; color: #ffcc00;"><strong>Tradeskills</strong></span></h1></p>
<p><span style="font-size: 14px;">This addon will send any profession you add to it to other guild mates who also have the addon and they'll send you the professions they've added also.</span></p>
<p><span style="font-size: 14px;">You can then easily search through their skills for something that might interest you and ask them the next time they're on if they'll craft it for you! Don't forget to tip your guildies!</span></p>
<h2>Commands</h2>
<ul>
	<li><strong>/gt</strong>: Toggles the search pane.</li>
	<li><strong>/gt help</strong>: Displays a list of available slash commands and descriptions.</li>
	<li><strong>/gt opt</strong>: Toggles the options pane.</li>
	<li><strong>/gt addprofession</strong>: Toggles adding a profession. Open the profession you want to add after.</li>
	<li><strong>/gt removeprofession {profession_name}</strong>: Remove a profession from&nbsp;<strong><span style="color: #339966;">Guild</span></strong>&nbsp;<strong><span style="color: #ffcc00;">Tradeskills</span></strong></li>
	<!--
	<li><strong>/gt advertise</strong>: Toggles advertising.</li>
	<li><strong>/gt advertise {seconds}</strong>: Sets the number of seconds between advertisements.</li>
	-->
	<li><strong>/gt add {character_name}</strong>: Requests to add a specific character.</li>
	<li><strong>/gt reject {character_name}</strong>: Rejects someone's request to add you. They can request again.</li>
	<li><strong>/gt ignore {character_name}</strong>: Ignores that person. No requests from that account should get through.</li>
	<li><strong>/gt requests</strong>: Lists the characters that have requested to add you.</li>
	<li><strong>/gt broadcast</strong>: Toggles all broadcasting capabilities.</li>
	<li><strong>/gt broadcast send</strong>: Toggles whether you are sending broadcasts to everyone. <strong>Yes, everyone everyone.</strong></li>
	<li><strong>/gt broadcast receive</strong>: Toggles whether you are receiving broadcasts from everyone. <strong>Yes, everyone everyone.</strong></li>
	<li><strong>/gt broadcast sendforwards</strong>: Toggles whether you are frowarding broadcasts that you have received. <strong>Use with caution. This may impact performance.</strong></li>
	<li><strong>/gt broadcase receiveforwards</strong>: Toggles whether you are accepting forwarded broadcasts that you have received. <strong>Use with caution. This may impact performance.</strong>
	<li><strong>/gt window {window_name}</strong>: Sets the output window.</li>
	<li><strong>/gt reset</strong>: Resets all stored data. Yes... all of it.&nbsp;<strong>This cannot be undone</strong>.&nbsp;We warned you.</li>
</ul>
<h2>FAQ</h2>
<p><strong>Q: I can't see my skills in the search window.</strong></p>
<p>A: You will need to add your profession with the '<strong>/gt addprofession</strong>' command.</p>
<p><strong>Q: I can't see my guild member's skills.</strong></p>
<p>A: Currently if your guild members do not have the addon or have not added their professions their skills will not appear in the search window.</p>
<p><strong>Q: I can't see skill X.</strong></p>
<p>A: The addon does not have a complete list of trade skills. It only tracks the skills it has been told about.</p>
<p><strong>Q: Are characters that are not in my guild that I have added sent to my guild?</strong></p>
<p>No, characters that are added are not sent to the guild.</p>
<p><strong>Q: Do I send my guild member's information to people outside the guild?</strong></p>
<p>No, characters outside the guild do not know about your guildmates.</p>
<p><strong>Q: What is broadcasting?</strong></p>
<p>Broadcasting is sending an invitation for everyone to fetch the skills you have added to the addon. Everyone inside you guild. Everyone outside. Everyone. This setting has no impact on whether you are syncing your skills with the guild. That will always happen even if this is off.</p>
<p><strong>Q: What is advertising?</strong></p>
<p>If this is on the addon will periodically advertise in the trade channel when you are in a city. People can then whisper you and query what skills you have.</p>
<h2>ToDo</h2>
<ul>
	<li>Add dropdown for online characters in the character search field.</li>
	<li>Add ability to view alts even when they are not in the same guild.</li>
	<li>Add ability to add a 'guild friend' that is then synced to the entire guild as if they were a guild member.</li>
</ul>
<h2>Known Issues</h2>
<ul>
	<li>AddOns\GuildTradeskills\Modules\Comm\CommGuild.lua line 209: AceTimer-3.0: ScheduleTimer(callback, delay, args...): 'callback' and 'delay' must have set values.</li>
	<li>AddOns\GuildTradeskills\Core.lua:193: bad argument #1 to 'lower' (string expected, got nil)</li>
</ul>
<h2>Links</h2>
<ul>
	<li><a href="https://www.curseforge.com/wow/addons/guild-tradeskills" target="_blank">CurseForge</a></li>
	<li><a href="https://www.wowinterface.com/downloads/info25573-GuildTradeskills.html" target="_blank">WoWInterface</a></li>
	<li><a href="https://github.com/Chalos-Atiesh/GuildTradeskills" target="_blank">GitHub</a></li>
</ul>
