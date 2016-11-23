#Vip expiration



I decided to write a _real-time_ system that takes care of the expiration and its purpose was mostly to demonstrate the __Date and Time Functions__ in SQL.
As it very well known, the timer intervals are not accurate (roughly 25% off) so I prefer to use the [Timerfix plugin by udan11](https://github.com/udan11/samp-plugin-timerfix/releases).



Each server may want to add different features for Vip members so I'll leave this part up to you and I will only provide a /setvip command.
```pawn
Usage: /setvip <ID/Part Of Name> <interval> <type>
```
__Description:__
Sets a player as Vip for a certain amount of days/months (max: 1 year).



type | minimum interval | maximum interval | leap year
---|---|---|---
0 | 1 day | 365 days | NO
0 | 1 day | 366 days | YES
1 | 1 month | 12 months | ---
