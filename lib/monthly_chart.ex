defmodule MonthlyChart do
  @moduledoc """
  Documentation for `MonthlyChart`.
  """
  @api_key System.get_env("LAST_FM_API_KEY")
  @http_headers ["User-Agent": "sillypog's Monthly Chart"]

  # Get recent user results
  def getMonthScrobbles(month \\ 0, username \\ "sillypog", showCounts \\ false, getImages \\ true) do
    IO.puts "Fetching monthly scrobbles for #{username}"

    albumPlayCounts = %{}

    {from, to} = getTimestamps(month)

    # Count from all pages of data
    albumPlayCounts = processPage(albumPlayCounts, username, from, to, 1)

    # List of albums to deduplicate
    aliases = getAliases("priv/aliases.txt")
    albumPlayCounts = deduplicateAlbumCounts(albumPlayCounts, aliases)

    # Get the list of albums, we don't need the keys any more
    albums = Map.values(albumPlayCounts)

    # Score the albums
    scoredAlbums = Enum.map(albums, fn(album) ->
      numTracks = MapSet.size(album[:tracks])
      %{album | score: (album[:count] / numTracks) * max(:math.log10(numTracks), 0.1)}
    end)

    # Sort the counts
    sortedAlbums = Enum.sort_by(scoredAlbums, &(&1.score), :desc)

    # Read the exclusion list and drop those from the album list
    exclusions = File.read!("priv/exclusions.txt")
      |> String.trim_trailing
      |> String.split("\n")

    filtered_albums = Enum.reject(sortedAlbums, fn(album) ->
      Enum.any?(exclusions, fn(exclusion) ->
        exclusion == album.name
      end)
    end)

    # Print out the top 50 and get the images
    top50 = Enum.take(filtered_albums, 50)
    Enum.reduce(top50, 1, fn(album, index) ->
      IO.write "#{index} #{album.name} - #{album.artist} "
      if showCounts do
        IO.write "#{album.count} #{album.score}"
      end
      IO.write "\n"

      if getImages do
        %{body: image_data} = HTTPoison.get!(album.image, @http_headers)
        File.write!("tmp/#{index}.jpg", image_data)
        :timer.sleep(500)
      end

      index + 1
    end)
  end

  defp getTimestamps(0) do
    now = DateTime.now!("US/Pacific", Tzdata.TimeZoneDatabase)
    getTimestamps(now)
  end

  defp getTimestamps(month) when is_integer(month) do
    now = DateTime.now!("US/Pacific", Tzdata.TimeZoneDatabase)
    then = %{now | month: month}
    getTimestamps(then)
  end

  defp getTimestamps(now) do
    from = %{now | day: 1, hour: 0, minute: 0, second: 0}
    next_month = case from.month do
      12 -> 1
      m -> m + 1
    end
    to = %{from | month: next_month}

    {DateTime.to_unix(from), DateTime.to_unix(to)}
  end

  defp getRecentsURL(username, from, to, page) do
    params = %{
      username: username,
      from: from,
      to: to,
      page: page,
      api_key: @api_key,
      format: "json"
    }

    url_base = "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&"

    url_base <> URI.encode_query(params)
  end

  defp getAliases(filename) do
    File.read!(filename)
      |> String.trim_trailing
      |> String.split("\n")
      |> Enum.reduce(%{}, fn(s, acc) ->
        [key, value] =  String.split(s, "|")
        Map.put(acc, String.trim(key), String.trim(value))
      end)
  end


  defp processPage(albumPlayCounts, username, from, to, page) do
    # See if we have the results in a cache
    filename = "tmp/cache/#{page}.json"

    albumPlayCounts = if File.exists?(filename) do
      # Read "response from file"
      json = filename
               |>File.read!
               |> Poison.decode!
      # Process response
      processResponse(json, albumPlayCounts, username, from, to, page)
    else
      # Download the reponse
      :timer.sleep(500)
      url = getRecentsURL(username, from, to, page)
      IO.puts url
      response = HTTPoison.get(url, @http_headers)
      case response do
        {:ok, response} ->
          # Save the response
          File.mkdir("tmp/cache")
          File.write!(filename, response.body)
          # Process response
          json = Poison.decode!(response.body)
          processResponse(json, albumPlayCounts, username, from, to, page)
        _ ->
          IO.puts "Get request failed"
      end
    end

    albumPlayCounts
  end

  defp processResponse(json, albumPlayCounts, username, from, to, page) do
    tracks = json["recenttracks"]["track"]
    albumPlayCounts = countPlays(tracks, albumPlayCounts)

    # If this is not the last page, request the next page
    {totalPages, _} = Integer.parse(json["recenttracks"]["@attr"]["totalPages"])
    IO.puts "Finished page #{page} out of #{totalPages}"
    albumPlayCounts = if page < totalPages do
      processPage(albumPlayCounts, username, from, to, page + 1)
    else
      albumPlayCounts
    end

    albumPlayCounts
  end

  defp countPlays([], albumPlayCounts), do: albumPlayCounts
  defp countPlays([track | t], albumPlayCounts) do
    key = track["album"]["#text"] <> track["album"]["mbid"]

    albumPlayCounts = case Map.has_key?(albumPlayCounts, key) do
      true ->
        currentCount = albumPlayCounts[key][:count]
        albumPlayCounts = Kernel.put_in(albumPlayCounts, [key, :count], currentCount + 1)

        # Also make a list of tracks we know are on this album
        updated_tracks = MapSet.put(albumPlayCounts[key][:tracks], track["name"])
        Kernel.put_in(albumPlayCounts, [key, :tracks], updated_tracks)
      false ->
        Map.put(albumPlayCounts, key, %{
          count: 1,
          score: 0,
          name: track["album"]["#text"],
          artist: track["artist"]["#text"],
          image: List.last(track["image"]) |> Map.get("#text"),
          tracks: MapSet.new([track["name"]])
        })
    end

    countPlays(t, albumPlayCounts)
  end

  defp deduplicateAlbumCounts(albums, aliases) do
    # If an aliases key and value are both in the albums, remove one and consolidate the play counts
    # and take the union of the tracks
    Enum.reduce(aliases, albums, fn({duplicate, original}, albums) ->
      if Map.has_key?(albums, duplicate) && Map.has_key?(albums, original) do
        IO.puts "Should deduplicate #{duplicate} for #{original}"
        # Calculate total playcounts for both albums
        original_count = albums[original][:count]
        duplicate_count = albums[duplicate][:count]
        total_count = original_count + duplicate_count
        # Get the union of both albums' tracks
        original_tracks = albums[original][:tracks]
        duplicate_tracks = albums[duplicate][:tracks]
        total_tracks = MapSet.union(original_tracks, duplicate_tracks)
        # Update the tracks and counts fields on the original
        albums = Kernel.put_in(albums, [original, :count], total_count)
        albums = Kernel.put_in(albums, [original, :tracks], total_tracks)
        # Remove the duplicate
        Map.drop(albums, [duplicate])
      else
        albums
      end
    end)
  end

end
