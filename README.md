# Platform Leaderboards

When the platform game mode was added to Trackmania 2020, it didn't have an ingame leaderboard to submit your records. In December 2025, Nadeo added a leaderboard for Platform maps to their API, but it was never added to the game.

With this plugin, you can see this leaderboard, including respawns, race time, and when it was driven.

## Record formatting

When getting the leaderboard through the API, if a run doesn't have any respawns, the API will return the race time, in milliseconds, like in Race leaderboards.

If the run has a respawn, the API will return the score in the following format:

* The first 6 digits represent the race time (to the tenth) + 400,000
* The last 3 digits are the number of respawns in the run. If a run has over 1000 respawns, the API will return 999.

    |Score       |Time         |Respawns |
    |:-:         |:-:          |:-:      |
    |401375004   |2:17.500     |4        |
    |501932423   |2:49:53.200  |423      |
    
You can calculate the respawns and race time of a run by using the following formulas:

```
respawns = score % 1000
time = (score - respawns - 400000000) / 10
```

You can convert respawns and race time to this format by using the following formula:

```
score = int(time / 100) * 1000 + respawns + 400000000
```

NOTE: The formula is written like this to truncate race times containing hundreds / thousands.

## Dependencies

The plugin requires the `NadeoServices` plugin to perform certain API requests. This is bundled with Openplanet, so it's not required to install separately.

Additionally, the plugin can use [MLHook](https://openplanet.dev/plugin/mlhook) to toggle record ghosts. This is optional, and it's not required to use the plugin.

## Credits

Thanks to Zai for discovering the format used by the API for the records.
