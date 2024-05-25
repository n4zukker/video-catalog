def keyDate:
  .liveStreamingDetails.actualStartTime // 
  .liveStreamingDetails.scheduledStartTime // 
  .snippet.publishedAt

;

def categorize:
  if .liveStreamingDetails.actualStartTime then
    "Livestreamed"
  elif .liveStreamingDetails.scheduledStartTime then
    "Scheduled"
  else
    "Videos"
  end
;

def mdTime:
  if . then
    fromdate | localtime | strftime ( "%A, %B %e, %Y, %I:%M %p %Z" )
  else
    ""
  end
;

def mdSeeAlsoTime:
  if . then
    fromdate | localtime | strftime ( "%x" )
  else
    ""
  end
;

def mdSeeAlsoAnchor:
  if . then
    fromdate | localtime | strftime ( "d%Y-%m-%d-%H-%M-%S" )
  else
    ""
  end
;

def mdDuration:
  capture ( "^P((?<years>\\d+)Y)?((?<months>\\d+)M)?((?<weeks>\\d+)W)?((?<d>\\d+)D)?T?((?<h>\\d+)H)?((?<m>\\d+)M)?((?<s>\\d+)S)?$" )
  | map_values( select ( . ) | tonumber )
  | reduce to_entries[] as $item ( "" ; "\(.) \($item.value)\($item.key)" )
;

def atomicTitles:
  .snippet.title | split( "[[:blank:]]*;[[:blank:]]*"; null )
;

def seeAlsoChain:
  map ( "[\( keyDate | mdSeeAlsoTime )](#\( keyDate | mdSeeAlsoAnchor ))" ) | join (" ")
;

def seeAlso ($byAtomicTitle):
  atomicTitles as $aTitles
  | (
    . as $entry
    | $aTitles
    | map(
        . as $t
        | $byAtomicTitle[$t] | select ( length > 1 )
        | map ( select ( keyDate != ( $entry | keyDate ) ) )
        | { key: $t, value: . }
      )
  ) as $titles

  | (
    $titles
    | if length == 0 then
        empty
      elif ( $aTitles | length ) == 1 then
        [ .[0].value | seeAlsoChain ]
      else
        map ( "*\(.key)*: \( .value | seeAlsoChain )   " )
      end
    ) as $seeAlsoLines

  | select ( $seeAlsoLines | length > 0 )
  | (
      "See also: \( if $seeAlsoLines | length > 1 then "  " else "" end )",
      $seeAlsoLines[]
    )
;

def linkTimestamps ($id):
  capture (
    "^(?<ts>
        (
          (?<hh>\\d\\d):
        )?
        (
          (?<mm>\\d\\d):
        )
        (
          (?<ss>\\d\\d)
        )
      )?
      (?<rest>.*)
    ";
    "x"
  )
  | if .ts then
      [
        ( .hh | select (.) | tonumber | select (. > 0) | "\( . )h" ),
        ( .mm | select (.) | tonumber | select (. > 0) | "\( . )m" ),
        ( .ss | select (.) | tonumber | select (. > 0) | "\( . )s" )
      ] as $hms
      | (
        [
          "[\( .ts )]",
          "(",
          "https://youtube.com/watch?v=\($id)",
          if ( $hms | length > 0 ) then
            "&t=\( $hms | join("") )"
          else
            ""
          end,
          ")"
        ] | join("")
      )
    else
      ""
    end + .rest
;

def body ($byAtomicTitle):
  . as $entry
  | (
    "![](\(.snippet.thumbnails.medium.url))",
    "",
    "|||",
    "|-----|------|",
    "| Video link: | [https://youtube.com/watch?v=\(.id)](https://youtube.com/watch?v=\(.id)) |",
    (
      if .liveStreamingDetails then
        (
          .liveStreamingDetails
          | (
              "| Scheduled Start Time: | \( .scheduledStartTime | mdTime ) |",
              ( .actualStartTime | select (.) | "| Actual Start Time: | \( mdTime ) |" ),
              ( .actualEndTime   | select (.) | "| Actual End Time: | \( mdTime ) |" )
            )
        )
      else
        "| Published at: | \( .snippet.publishedAt | mdTime ) |"
      end
    ),

    ( ( .contentDetails.duration // "P0D" ) | select ( . != "P0D" ) | "| Duration: | \( mdDuration ) |" ),

    (
      select (.statistics.viewCount | tonumber > 0)
      | .statistics
      | (
          "| Views: | \( .viewCount ) |",
          (
            [ 
              def thumb ( $singular ; $thumb ):
                tonumber | select ( . > 0 ) | "\( . ) \($singular)\( if . > 1 then "s" else "" end ) \($thumb)",
              ;
              ( .likeCount    | thumb ( "like"    ; "&#128077;" ) ),
              ( .dislikeCount | thumb | "dislike" ; "&#128078;" )  )
            ]
            | select ( length > 0 )
            | join (" and ")
            | "| Reactions: | \( . ) |"
          ) 
        )
    ),

    "",
    (
      ">" + ( .snippet.description | split("\n") | .[] | linkTimestamps ( $entry.id ) ) + "  "
    ),
    "",

    ( seeAlso ( $byAtomicTitle ) ),

    "",
    "---",
    ""
  )
;

def sectionBody ($byTitle):
  .[]
  | (
    "#### \( .snippet.title )[]{#\( keyDate | mdSeeAlsoAnchor )}",
    "",
    body ($byTitle)
  )
;

def groupToObj (fnKey):
  group_by ( fnKey )
  | reduce .[] as $item ( {} ; . + { ( $item[0] | fnKey ): $item } )
;

def groupAtomicTitles:
  group_by ( .snippet.title )
  | map (
      . as $array
      | .[0] | atomicTitles[] | { key: ., value: $array }
    )
  | reduce .[] as $item (
      {} ;
      . + { ( $item.key ): ( ( .[$item.key] // [] ) + $item.value ) }
    )
#  | from_entries
;

def toc ($byAtomicTitle; $byCategory):
  "## Table of Contents",
  "### Chapters",
  (
     $byCategory | (
       if .["Scheduled"] then
         "* [Upcoming streams](#upcoming)"
       else
         empty
       end,

       if .["Livestreamed"] then
         "* [Live streams](#live)"
       else
         empty
       end,

       if .["Videos"] then
         "* [Uploaded videos](#uploaded)"
       else
         empty
       end
    )
  ),

  "",

  (
    map (
        select ( ( categorize == "Livestreamed" ) and ( atomicTitles | all ( . as $title | $byAtomicTitle[$title] | length == 1 ) ) )
      )
    | sort_by ( keyDate )
    | (
        "### Isolated events",
        (
          .[] | "* [\(.snippet.title)](#\( keyDate | mdSeeAlsoAnchor ))"
        )
      ) 
  ),

  ""
;

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
