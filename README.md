# MonthlyChart

Generate a composite image of your most listened to albums for the month based on last.fm data.

## Installation
Prior to compiling the Elixir program, you must have a Last.fm API key available as the environment variable `LAST_FM_API_KEY`.

Imagemagick is needed for generating the composite image.

## Usage

### Calculating top albums
Launch the Elixir console with `iex -S mix`.
Run the program with `MonthlyChart.getMonthScrobbles()`.

By default, this will fetch listening data for the last month for the user `sillypog`. It will download the album art for the top albums into the tmp directory. This behaviour can be overridden by providing arguments to the program. For example, `MonthlyChart.getMonthScrobbles(4, "anne", true, false)` will:
* get April data.
* for user `anne`.
* showing the count of track listens for each album.
* not download the album art.

Listening data is cached in tmp/cache and needs to be manually cleared between runs if the latest data is needed.

#### Exluding albums
If there albums you want to exclude from consideration, add the album name to priv/exclusions.txt. There should be one album name per line.

#### Deduplicating albums
If there are multiple versions of the same album (such as a deluxe edition) and you want to consider these to be thesame, add these to priv/aliases.txt. Each line should contain the name of the duplicate album to exlude and the name and Monkey Brains id of the album to use instead, separated with the pipe character. For example:
```
Meliora (Deluxe Edition) | Meliora5ad39802-a528-4063-b18d-4dee85f4f479
```

### Generating composite images
This requires imagemagick to be installed on your system.

From within the tmp folder run `../priv/montage.sh`. This outputs /tmp/x_out_border.png showing the top 42 albums of the month.

The other output files (those not starting with "x") can be used to manually assemble a composite with the most listened album shown larger.
