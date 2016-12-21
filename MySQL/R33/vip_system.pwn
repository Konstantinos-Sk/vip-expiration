#define FILTERSCRIPT

#include <a_samp>

#undef MAX_PLAYERS
#define MAX_PLAYERS 50 // change to your server slots

#include <a_mysql>
#include <sscanf2>
#include <zcmd>

#define     MYSQL_HOST            "host_here"
#define     MYSQL_USER            "user_here"
#define     MYSQL_PASSWORD        "password_here"
#define     MYSQL_DATABASE        "database_here"

static g_SQL,
    gPlayer_VipExpiration[MAX_PLAYERS], gPlayerTimer_VipExpiration[MAX_PLAYERS];

public OnFilterScriptInit()
{
    g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DATABASE, MYSQL_PASSWORD);
    return 1;
}

public OnFilterScriptExit()
{
    mysql_close(g_SQL);
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

forward OnVipStatusCheck(playerid);
public OnVipStatusCheck(playerid)
{
    if (cache_num_rows())
    {
        new seconds, Query[75];

        seconds = cache_get_row_int(0, 0, g_SQL);

        if (seconds <= 0)
        {
            GetPlayerName(playerid, Query, MAX_PLAYER_NAME);
            mysql_format(g_SQL, Query, sizeof Query, "DELETE FROM vips WHERE name='%e'", Query);
            mysql_tquery(g_SQL, Query);

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
}

forward OnPlayerVipStatusExpire(playerid);
public OnPlayerVipStatusExpire(playerid)
{
    new Query[55], player_name[MAX_PLAYER_NAME];

    GetPlayerName(playerid, player_name, MAX_PLAYER_NAME);
    mysql_format(g_SQL, Query, sizeof Query, "DELETE FROM vips WHERE name='%e'", player_name);
    mysql_tquery(g_SQL, Query);

    SendClientMessage(playerid, -1, "Your VIP status has just expired!");

    gPlayer_VipExpiration[playerid] = gPlayerTimer_VipExpiration[playerid] = 0;
}

forward OnVipStatusSet(playerid);
public OnVipStatusSet(playerid)
{
    if (cache_num_rows())
    {
        new seconds = cache_get_row_int(0, 0, g_SQL);
	    
        gPlayerTimer_VipExpiration[playerid] = SetTimerEx("OnPlayerVipStatusExpire", seconds * 1000, false, "i", playerid);
        gPlayer_VipExpiration[playerid] = gettime() + seconds;
    }
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
            if (!(1 <= interval <= 365)) return SendClientMessage(playerid, -1, "Error: Interval cannot be negative, equal to 0 or more than 365 days.");
        }
        case 1:
        {
            if (!(1 <= interval <= 12)) return SendClientMessage(playerid, -1, "Error: Interval cannot be negative, equal to 0 or more than 12 months.");
        }
        default: return SendClientMessage(playerid, -1, "Error: Type can only be 0 or 1 for \"day(s)\" and \"month(s)\" respectively.");
    }

    SetVipStatus(playerid, interval, type);
    return 1;
}

//-----------------------------------------------------

CheckVipStatus(playerid)
{
    new Query[122], player_name[MAX_PLAYER_NAME];

    GetPlayerName(playerid, player_name, MAX_PLAYER_NAME);
    mysql_format(g_SQL, Query, sizeof Query, "SELECT TIMESTAMPDIFF(SECOND,NOW(),expire) FROM vips WHERE name='%e'", player_name);
    mysql_tquery(g_SQL, Query, "OnVipStatusCheck", "i", playerid);
}

IsPlayerVip(playerid)
{
    if (!gPlayer_VipExpiration[playerid]) return 0;
    return gettime() <= gPlayer_VipExpiration[playerid];
}

SetVipStatus(playerid, interval, type)
{
    new Query[153], player_name[MAX_PLAYER_NAME], type_value[6];

    type_value = type ? ("MONTH") : ("DAY");
    GetPlayerName(playerid, player_name, MAX_PLAYER_NAME);
    mysql_format(g_SQL, Query, sizeof Query, "INSERT INTO vips VALUES ('%e', DATE_ADD(NOW(),INTERVAL %i %s)) ON DUPLICATE KEY UPDATE expire=DATE_ADD(NOW(),INTERVAL %i %s)", player_name, interval, type_value, interval, type_value);
    mysql_tquery(g_SQL, Query);

    mysql_format(g_SQL, Query, sizeof Query, "SELECT TIMESTAMPDIFF(SECOND,NOW(),expire) FROM vips WHERE name='%e'", player_name);
    mysql_tquery(g_SQL, Query, "OnVipStatusSet", "i", playerid);
}
