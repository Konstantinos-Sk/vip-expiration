#define FILTERSCRIPT

#include <a_samp>

#undef MAX_PLAYERS
#define MAX_PLAYERS 50 // change to your server slots

#include <sscanf2>
#include <zcmd>

static DB: g_SQL,
    gPlayer_VipExpiration[MAX_PLAYERS], gPlayerTimer_VipExpiration[MAX_PLAYERS];

public OnFilterScriptInit()
{
    g_SQL = db_open("vip_system.db");
    return 1;
}

public OnFilterScriptExit()
{
    db_close(g_SQL);
    return 1;
}

public OnPlayerConnect(playerid)
{
    CheckVipStatus(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (gPlayerTimer_VipExpiration[playerid])
    {
        KillTimer(gPlayerTimer_VipExpiration[playerid]);
        gPlayerTimer_VipExpiration[playerid] = 0;
    }
    return 1;
}

//-----------------------------------------------------

forward OnPlayerVipStatusExpire(playerid);
public OnPlayerVipStatusExpire(playerid)
{
    new Query[55], player_name[MAX_PLAYER_NAME];
    
    GetPlayerName(playerid, player_name, MAX_PLAYER_NAME);
    format(Query, sizeof Query, "DELETE FROM vips WHERE name='%q'", player_name);
    db_query(g_SQL, Query);
    
    SendClientMessage(playerid, -1, "Your VIP status has just expired!");
	
    gPlayer_VipExpiration[playerid] = gPlayerTimer_VipExpiration[playerid] = 0;
}

//-----------------------------------------------------

CMD:setvip(playerid, params[])
{
    if (!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "Error: You are not authorized to use this command.");
	
    new id, interval, type;
	
    if (sscanf(params, "rii", id, interval, type))
    {
        SendClientMessage(playerid, -1, "Usage: /setvip <ID/Part Of Name> <interval> <type>");
        SendClientMessage(playerid, -1, "Types: 0 for \"day(s)\" and 1 for \"month(s)\"");
        return 1;
    }
    if (id == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "Error: Player is not connected.");
    if (IsPlayerVip(id)) return SendClientMessage(playerid, -1, "Error: Player is already VIP.");

    switch (type)
    {
        case 0:
        {
            new days_and_year, string[70];
	        
            getdate(days_and_year, _, _);
            days_and_year = (!(days_and_year & 3) && ((days_and_year % 25) || !(days_and_year & 15))) ? 366 : 365;
	        
            if (!(1 <= interval <= days_and_year))
            {
                format(string, sizeof string, "Error: Interval cannot be negative, equal to 0 or more than %i days.", days_and_year);
                SendClientMessage(playerid, -1, string);
                return 1;
            }
        }
        case 1:
        {
            if (!(1 <= interval <= 12)) return SendClientMessage(playerid, -1, "Error: Interval cannot be negative, equal to 0 or more than 12 months.");
        }
        default: return SendClientMessage(playerid, -1, "Error: Type can only be 0 or 1 for \"day(s)\" and \"month(s)\" respectively.");
    }

    SetVipStatus(id, interval, type);
    return 1;
}

//-----------------------------------------------------

CheckVipStatus(playerid)
{
    new DBResult: result, Query[122], player_name[MAX_PLAYER_NAME];

    GetPlayerName(playerid, player_name, MAX_PLAYER_NAME);
    format(Query, sizeof Query, "SELECT strftime('%%s',expire)-strftime('%%s',datetime('now','localtime')) FROM vips WHERE name='%q'", player_name);
    result = db_query(g_SQL, Query);

    if (db_num_rows(result))
    {
        new seconds = db_get_field_int(result);

        if (seconds <= 0)
        {
            format(Query, sizeof Query, "DELETE FROM vips WHERE name='%q'", player_name);
            db_query(g_SQL, Query);

            SendClientMessage(playerid, -1, "Your VIP status has expired.");

            gPlayer_VipExpiration[playerid] = 0;
        }
        else
        {
            gPlayerTimer_VipExpiration[playerid] = SetTimerEx("OnPlayerVipStatusExpire", seconds * 1000, false, "i", playerid);
            gPlayer_VipExpiration[playerid] = gettime() + seconds;

            new days, hours, minutes;

            days = seconds / 86400;
            hours = (seconds / 3600) % 24;
            minutes = (seconds / 60) % 60;
            seconds %= 60;

            if (days) format(Query, sizeof Query, "Your VIP status expires in %i day%s, %i hour%s, %i minute%s and %i second%s", days, days != 1 ? ("s") : (""), hours, hours != 1 ? ("s") : (""), minutes, minutes != 1 ? ("s") : (""), seconds, seconds != 1 ? ("s") : (""));
            else if (!days && hours) format(Query, sizeof Query, "Your VIP status expires in %i hour%s, %i minute%s and %i second%s", hours, hours != 1 ? ("s") : (""), minutes, minutes != 1 ? ("s") : (""), seconds, seconds != 1 ? ("s") : (""));
            else if (!days && !hours && minutes) format(Query, sizeof Query, "Your VIP status expires in %i minute%s and %i second%s", minutes, minutes != 1 ? ("s") : (""), seconds, seconds != 1 ? ("s") : (""));
            else if (!days && !hours && !minutes && seconds) format(Query, sizeof Query, "Your VIP status expires in %i second%s", seconds, seconds != 1 ? ("s") : (""));

            SendClientMessage(playerid, -1, Query);
        }
    }
    else gPlayer_VipExpiration[playerid] = 0;

    db_free_result(result);
}

IsPlayerVip(playerid)
{
    if (!gPlayer_VipExpiration[playerid]) return 0;
    return gettime() <= gPlayer_VipExpiration[playerid];
}

SetVipStatus(playerid, interval, type)
{
    new DBResult: result, Query[134], player_name[MAX_PLAYER_NAME];

    GetPlayerName(playerid, player_name, MAX_PLAYER_NAME);
    format(Query, sizeof Query, "INSERT OR REPLACE INTO vips VALUES ('%q',datetime('now','localtime','%i %s'))", player_name, interval, !type ? ("day") : ("month"));
    db_query(g_SQL, Query);

    format(Query, sizeof Query, "SELECT strftime('%%s',expire)-strftime('%%s',datetime('now','localtime')) FROM vips WHERE name='%q'", player_name);
    result = db_query(g_SQL, Query);

    new seconds = db_get_field_int(result);

    gPlayerTimer_VipExpiration[playerid] = SetTimerEx("OnPlayerVipStatusExpire", seconds * 1000, false, "i", playerid);
    gPlayer_VipExpiration[playerid] = gettime() + seconds;

    db_free_result(result);
}
