include "videos-lib";

"# Youtube videos on the Cathedral's channel",
(
    groupToObj ( .kind ) as $kind
  | ( $kind["youtube#playlist"] // [] )      as $playlists
  | ( $kind["youtube#playlistItem"]  // [] ) as $playlistItems
  | ( $kind["youtube#video"] | mergePlaylists ( $playlists ; $playlistItems ) ) as $videos

  | ( $videos | groupToObj ( .snippet.title ) ) as $byTitle
  | ( $videos | groupAtomicTitles )             as $byAtomicTitle
  | ( $videos | groupToObj ( categorize ) )     as $byCategory

  | (
      ( $videos | toc ( $byAtomicTitle ; $byCategory ; $playlists ) ),
      (
        $byCategory | (
          (
            ( .["Scheduled"] // empty )
            | (
              "## Upcoming streams []{#upcoming}",
              ( sort_by ( keyDate ) | sectionBody ( $byAtomicTitle ) )
            )
          ),

          (
            ( .["Livestreamed"] // empty )
            | (
              "## Live streams []{#live}",
              ( sort_by ( keyDate ) | reverse | sectionBody ( $byAtomicTitle ) )
            )
          ),

          (
            ( .["Videos"] // empty )
            | (
              "## Uploaded videos []{#uploaded}",
              ( sort_by ( keyDate ) | reverse | sectionBody ( $byAtomicTitle ) )
            )
          )
        )
      ),
      (
          $playlists
        | select ( length > 0 )
        | (
            "## Playlists [](#playlists)",
            playlistBody ( $videos ; $playlistItems )
          )
      ),
      (
        "## Matrix [](#matrix)",
        ( $byAtomicTitle | matrix )
      )
    )
)
