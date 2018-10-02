# shrkbot-readme

This bot is deprecated. While it will still be running for a while, there will be no new bug fixes, and work on a rewrite will be started later this year.

### Welcome to the README portion of shrkbot

1. Introduction
2. Setup
3. Features for users
4. Features for staff

## Introduction:

shrkbot is a helpful bot for moderation and utility use. 

## Setup:

### Setup to run the bot yourself:

First, you will need to [create an application](https://discordapp.com/developers/applications/me), as you will need the token of it to start the bot. You will also need a MySQL database, which is what the bot uses for persistence.

The bot expects a file of this format called `.login` in the same directory as `shrkbot.rb`.
```
---
:token: <discord token of your application>
:client_id: <client_id of your app>
:server_name: <server the database is on (can be localhost)>
:username: <username for the database>
:server_password: <password for the server the database is on (can be blank if server has no PW / localhost)>
:db_name: <name of the database you want to use (needs to be MySQL)>
:db_password: <password for the database>

```

### Setup for servers:

Simply [invite to server](https://discordapp.com/oauth2/authorize?&client_id=346043915142561793&scope=bot&permissions=8) and it will set itself up. Anything it can’t do automatically it will DM the server owner about. To recognize staff members, the bot uses a role called **BotCommand**, which will be automatically created when the bot joins your server. Simply assign it to your staff members so the bot knows who should have access to more administrative commands.

The bot’s default prefix is `.`, which means you can call commands with `.<command>`. However, the prefix can be set on a per server basis using the `setPrefix <prefix>` command. The only two commands that statically use the `.` prefix are `.prefix` (which returns the prefix currently set for this server) and `.resetPrefix` (which resets the prefix to `.`). The latter can be used in case the prefix gets set to something the bot can’t react to (e.g. an emoji).

All commands are case-insensitive, but will be written in camelCase in the documentation so they’re easier to read.

Required parameters will be written in `<>`, optional ones in `[]`.

**IMPORTANT**: In its current state, shrkbot has some issues when joining a server without restarting. Please DM me (TrueBlackShark#6987) on Discord, if you'd like to use shrkbot!
        
## Features for users:
        
### Current User Commands: 

#### Assignment Command:
##### `.roles`
* Points you to the channel where you can assign roles to yourself. 

#### Chart Commands:                
##### `.roleChart [minMembers]`
* Generates a chart showing the distribution of roles on the server. Selects 10 roles max, if <min_members> isn\'t specified.
##### `.gameChart`
* Generates a chart of the games currently being played on the server.

#### Help Command: 
##### `.help [commandName]`
* Lists all the commands available to the user calling the command, or shows help for one specific command.

#### Link Removal Command: 
##### `.prohibited`               
* Lists all sites you are not allowed to link to.

#### Reminder Command:
##### `.remind <message> [time] [--pm]`
* You will be reminded of <message> after <time>. Argument order doesn't matter. Set the `--pm` flag to be reminded in a PM. Time defaults to 1 day. Supported time formats: s, m, d, w, M, y. Mixing formats (e.g. 1d10h) is supported.

#### Roulette Commands:
##### `.roulette`
* You have a 1/6 chance to die, like an actual revolver. Dying mutes you for 1 minute.
##### `.leaderboard`
* Shows a leaderboard of roulette highscores.
##### `.stats`
* Shows your current roulette stats (# of plays, current streak, highscore).

#### ToDo Command:
##### `.todo [entry OR id] [flags]`
* Creates an entry, if [entry] is given. Otherwise, displays the TODO list. 
* Flags:        
  * --server: Hides the entry from all servers but the one it was created on. 
  * --delete: Deletes the entry with the given <id>.
  * --all: Also displays entries hidden with --server.
  * --clear: Clears your TODO list.

## Features For Staff:

### Current Staff Commands:

#### Assignment Commands:
##### `.setAssignmentChannel <channelName>`
* Sets the channel where the bot displays the role assign message.
##### `.addToSelfAssign <roleNames>`
* Adds as many roles to the list of self-assignable roles as you want.
##### `.removerFromSelfAssign <roleName>`
* Removes as many roles from the list of self-assignable roles as you want.
##### `.refreshRoles`
* Triggers a manual refresh for the role message.
##### `.assignmentChannel?`
* Tells you what the assignment channel is, in case you forgot which one it was.

#### Join/Leave Message Commands:
##### `.setJoinMessage <joinMessage>`
* Sets a message to display when a user joins the server. **Message can't be longer than 255 characters.**
##### `.setLeaveMessage <leaveMessage>`
* Sets a message to display when a user leaves the server. **Message can't be longer than 255 characters.**
##### `.joinMessage`
* Displays the message for when a user joins the server.
##### `.leaveMessage`
* Displays the message for when a user leaves the server.
##### `.setMessageChannel <channelName>`
* Sets the channel where the bot logs role assigns.
##### `.messageChannel?`
* Links the channel for join / leave messages, in case you forgot which one it is.

#### Link Removal Commands:
##### `.prohibit <link> <duration> <--ignore-whitespace>`
* Prohibits linking to the specified site. Keep this as general as possible for best results. Duration defaults to 2h. The flag is optional. When enabled, the bot will still recognize the link, even if there's whitespace in it. Beware of false positives.
##### `.allow <link>`
* Now allows linking to this site again.
##### `.permit <useMentions>`
* Allows all mentioned users to send prohibited links for 30s.

#### Logger Commands:
##### `.setlogchannel <channelName>`
* Sets the channel where the bot logs role assigns.
##### `.logChannel?`
* Sends a message in the log channel, in case you forgot which one it is.

#### Mention Command:
##### `.mention <user>`
* Mentions a user without letting them know it was you who mentioned them.

#### Misc Command:
##### `.setGame <game>`
* Sets what game the bot is playing.

#### Moderation Commands:
##### `.refereshMutedRole`
* Allows for a refresh of the muted role, e.g. when it was accidentally deleted.
##### `.mute <userMentions> <duration> <reason>`
* Mutes all users mentioned in the command for the duration given. Order doesn't matter, duration and reason are optional and have default values. Supported time formats: s, m, d, w, M, y. Mixing formats (e.g. 1d10h) is supported.
* **WARNING**: When the bot restarts, it won't unmute currently muted users!
##### `.unmute <userMentions>`
* Unmutes all users mentioned in the command.
##### `.mutes`
* Lists all muted people, and the time their mute expires.

#### Prefix Command:
##### `.setprefix <newPrefix>`
* Sets the prefix for this server.
* **Don't set this to a custom emoji, unless you want to brick your bot :)**

#### Webhook Commands:
##### `.clearWebhooks`
* Clears all shrkbot webhooks in the channel.
##### `.refreshWebhooks`
* Clears all shrkbot webhooks in the channel, and creates a new one.
