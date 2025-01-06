include "videos-lib";

"# Youtube videos on the Cathedral's channel",
(
  groupToObj ( .snippet.title ) as $byTitle
  | groupAtomicTitles as $byAtomicTitle
  | groupToObj ( categorize ) as $byCategory

  | (
      toc ( $byAtomicTitle ; $byCategory ),
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
      )
    )
)
