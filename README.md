#Vip expiration



I decided to write a _real-time_ system that takes care of the expiration and its purpose was mostly to demonstrate the __Date and Time Functions__ in SQL.
As it very well known, the timer intervals are not accurate (roughly 25% off) so I prefer to use the [Timerfix plugin by udan11](https://github.com/udan11/samp-plugin-timerfix/releases).



Each server may want to add different features for Vip members so I'll leave this part up to you and I will only provide a /setvip command.
```pawn
Usage: /setvip <ID/Part Of Name> <interval> <type>
```
__Description:__
Sets a player as Vip for a certain amount of days/months (max: 1 year).



type | represents for
---|---
0 | day(s)
1 | month(s)



minimum amount of days (interval) | maximum amount (interval) | leap year
---|---|---
1 | 365 | NO
1 | 366 | YES
