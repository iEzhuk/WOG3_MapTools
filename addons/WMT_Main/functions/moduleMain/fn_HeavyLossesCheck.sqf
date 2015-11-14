/*
    Name: WMT_fnc_HeavyLossesCheck

    Author(s):
        Zealot

    Description:
        Check losses
*/


params [["_playerratio", 0.1, [0.1]]];

if (_playerratio == 0) exitWith {};
if (not isServer) exitWith {diag_log "PALYERCOUNT.SQF NOT SERVER";};
if (!isNil "wmt_hl_disable") exitwith {diag_log "HeavyLossesCheck disabled";};

waitUntil { sleep 1.5; time > 60 };
waitUntil { sleep 1.5; (missionNamespace getvariable ["WMT_pub_frzState",3]) >=3 };

wmt_playerCountInit = [ {side _x == east and isPlayer _x} count playableUnits,  {side _x == west and isPlayer _x} count playableUnits,  {side _x == resistance and isPlayer _x} count playableUnits ];


if (isnil "wmtPlayerCountEmptySides") then { wmtPlayerCountEmptySides = [civilian]; };
{
    if( (wmt_playerCountInit select _foreachindex) == 0) then {
        wmtPlayerCountEmptySides = wmtPlayerCountEmptySides + [_x];
    };
} foreach [east, west, resistance];

private "_fnc_checkRatiosForSides";
_fnc_checkRatiosForSides = {
    private ["_countBegin","_countNow","_id"];
    _countbegin = 0;_countNow=0;_id=0;
    {
        _id = [_x] call bis_fnc_sideid;
        _countbegin = _countbegin + (wmt_playerCountInit select _id);
        _countNow = _countnow + (wmt_PlayerCountNow select _id);
    } foreach _this;
    [_countNow,_countBegin]
};


private ["_enemysides","_ratios","_enemyratio","_enemy"];
wmt_PlayerCountNow = [{side _x == east and isPlayer _x} count playableUnits,{side _x == west and isPlayer _x} count playableUnits,{side _x == resistance and isPlayer _x} count playableUnits];
diag_log ["HeavyLosses start", wmt_PlayerCountNow, wmt_playerCountInit, wmtPlayerCountEmptySides, count playableUnits, {isplayer _x} count playableunits];
while {isNil "wmt_hl_disable"} do {
    wmt_PlayerCountNow = [
        {side _x == east and isPlayer _x} count playableUnits,
        {side _x == west and isPlayer _x} count playableUnits,
        {side _x == resistance and isPlayer _x} count playableUnits
    ];
    {
        _enemysides = ([_x] call bis_fnc_enemysides) - [civilian];
        _ratios = _enemysides call _fnc_checkRatiosForSides;
        if ((_ratios select 1) != 0) then {
            _enemyratio = (_ratios select 0) / (_ratios select 1);
            if (_enemyratio < _playerratio) then {
                diag_log ["HeavyLosses triggered", wmt_PlayerCountNow, wmt_playerCountInit, wmtPlayerCountEmptySides, [_enemysides,_ratios,_enemyratio] ];
                if (isNil "wmt_hl_winmsg") then {
                    [ [_x], { [_this select 0,format[localize "STR_WMT_HLSWinLoseMSG",([_this select 0] call BIS_fnc_sideName)]] call wmt_fnc_endmission; } ] remoteExec ["bis_fnc_spawn"];
                } else {
                    [ [_x], { [_this select 0,format[ wmt_hl_winmsg select ([_this select 0] call bis_fnc_sideid),([_this select 0] call BIS_fnc_sideName)]] call wmt_fnc_endmission; } ] remoteExec ["bis_fnc_spawn"];
                };
                wmt_hl_disable = true;

            };
        };

    } foreach ([east,west,resistance] - wmtPlayerCountEmptySides);
    sleep 8.5;
};
