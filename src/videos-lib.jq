
def groupToObj (fnKey):
  group_by ( fnKey )
  | reduce .[] as $item ( {} ; . + { ( $item[0] | fnKey ): $item } )
;

# Examples:
#
# Command:
#  keyDate
#
# Input:
#  {
#    "kind": "youtube#video",
#    "snippet": {
#      "publishedAt": "2022-04-10T17:35:47Z",
#      "title": "Hosanna Sunday"
#    },
#    "liveStreamingDetails": {
#      "actualStartTime": "2022-04-10T15:28:00Z",
#      "actualEndTime": "2022-04-10T17:17:09Z",
#      "scheduledStartTime": "2022-04-10T15:30:00Z"
#    }
#  }
#
# Output:
#  "2022-04-10T15:28:00Z"

def keyDate:
  .liveStreamingDetails.actualStartTime // 
  .liveStreamingDetails.scheduledStartTime // 
  .snippet.publishedAt
;

# Examples:
#
# Command:
#  keyYear
#
# Input:
#  {
#    "kind": "youtube#video",
#    "snippet": {
#      "publishedAt": "2022-04-10T17:35:47Z",
#      "title": "Hosanna Sunday"
#    },
#    "liveStreamingDetails": {
#      "actualStartTime": "2022-04-10T15:28:00Z",
#      "actualEndTime": "2022-04-10T17:17:09Z",
#      "scheduledStartTime": "2022-04-10T15:30:00Z"
#    }
#  }
#
# Output:
#  2022

def keyYear:
    keyDate
  | fromdate
  | localtime[0]
;

# Examples:
#
# Command:
#  categorize
#
# Input:
#  {
#    "kind": "youtube#video",
#    "snippet": {
#      "publishedAt": "2022-04-10T17:35:47Z",
#      "title": "Hosanna Sunday"
#    },
#    "liveStreamingDetails": {
#      "actualStartTime": "2022-04-10T15:28:00Z",
#      "actualEndTime": "2022-04-10T17:17:09Z",
#      "scheduledStartTime": "2022-04-10T15:30:00Z"
#    }
#  }
#
# Output:
#  "Livestreamed"

def categorize:
  if .liveStreamingDetails.actualStartTime then
    "Livestreamed"
  elif .liveStreamingDetails.scheduledStartTime then
    "Scheduled"
  else
    "Videos"
  end
;

# Examples:
#
# Command:
#  mdTime
#
# Input:
#  "2022-04-10T17:35:47Z"
#
# Output:
#  "Sunday, April 10, 2022, 12:35 PM EST"

def mdTime:
  if . then
    fromdate | localtime | strftime ( "%A, %B %e, %Y, %I:%M %p %Z" )
  else
    ""
  end
;

# Examples:
#
# Command:
#  mdSeeAlsoTime
#
# Input:
#  "2022-04-10T17:35:47Z"
#
# Output:
#  "04/10/2022"

def mdSeeAlsoTime:
  if . then
    fromdate | localtime | strftime ( "%x" )
  else
    ""
  end
;

# Examples:
#
# Command:
#  anchorText("X")
#
# Input:
#  "2022-04-10T17:35:47Z"
#  "2024-12-25T21:46:15.543315Z"
#  "foobar"
#
# Output:
#  "X2022-04-10-12-35-47"
#  "X2024-12-25-16-46-15"

def anchorText ($prefix):
    capture("^(?<yymmdd>\\d{4}-\\d{2}-\\d{2})T(?<hhmmss>\\d{2}:\\d{2}:\\d{2})(?<ms>[.]\\d{6})?Z$")
  | "\(.yymmdd)T\(.hhmmss)Z"
  | fromdate
  | localtime
  | strftime ( "\($prefix)%Y-%m-%d-%H-%M-%S" )
;

# Examples:
#
# Command:
#  mdSeeAlsoAnchor
#
# Input:
#  "2022-04-10T17:35:47Z"
#
# Output:
#  "d2022-04-10-12-35-47"

def mdSeeAlsoAnchor:
  if . then
    anchorText ( "d" )
  else
    ""
  end
;

# Examples:
#
# Command:
#  mdPlaylistAnchor
#
# Input:
#  "2022-04-10T17:35:47Z"
#  "2024-12-25T21:46:15.543315Z"
#
# Output:
#  "p2022-04-10-12-35-47"
#  "p2024-12-25-16-46-15"

def mdPlaylistAnchor:
  if . then
    anchorText ( "p" )
  else
    ""
  end
;

# Examples:
#
# Command:
#  mdDuration
#
# Input:
#  "PT1H22M59S"
#
# Output:
#  "1h 22m 59s"

def mdDuration:
  capture ( "^P((?<years>\\d+)Y)?((?<months>\\d+)M)?((?<weeks>\\d+)W)?((?<d>\\d+)D)?T?((?<h>\\d+)H)?((?<m>\\d+)M)?((?<s>\\d+)S)?$" )
  | map_values( select ( . ) | tonumber )
  | to_entries | map ( "\(.value)\(.key)" ) | join(" ")
;

# Examples:
#
# Command:
#  atomicTitles
#
# Input:
#   {
#     "snippet": {
#       "title": "Fifth Sunday of Pentecost; The Feast of Saints Peter and Paul"
#     }
#   }
#
# Output:
#   [
#     "Fifth Sunday of Pentecost",
#     "The Feast of Saints Peter and Paul"
#   ]
#
def atomicTitles:
  .snippet.title | split( "[[:blank:]]*;[[:blank:]]*"; null )
;

def seeAlsoAnchor:
  keyDate | mdSeeAlsoAnchor
;

# Examples:
#
# Command:
#  seeAlsoChainGroup
#
# Input:
#  [
#    {
#      "kind": "youtube#video",
#      "snippet": {
#        "publishedAt": "2022-04-10T17:35:47Z",
#        "title": "Hosanna Sunday"
#      },
#      "liveStreamingDetails": {
#        "actualStartTime": "2022-04-10T15:28:00Z",
#        "actualEndTime": "2022-04-10T17:17:09Z",
#        "scheduledStartTime": "2022-04-10T15:30:00Z"
#      }
#    }
#  ]
#
# Output:
#  [
#    "[04/10/2022](#d2022-04-10-10-28-00)"
#  ]
#
def seeAlsoChainGroup:
  map ( "[\( keyDate | mdSeeAlsoTime )](#\( seeAlsoAnchor ))" )
;

# Examples:
#
# Command:
#  seeAlsoChain
#
# Input:
#  [
#    {
#      "kind": "youtube#video",
#      "snippet": {
#        "publishedAt": "2022-04-10T17:35:47Z",
#        "title": "Hosanna Sunday"
#      },
#      "liveStreamingDetails": {
#        "actualStartTime": "2022-04-10T15:28:00Z",
#        "actualEndTime": "2022-04-10T17:17:09Z",
#        "scheduledStartTime": "2022-04-10T15:30:00Z"
#      }
#    }
#  ]
#
# Output:
#    "[04/10/2022](#d2022-04-10-10-28-00)"
#
# Input:
#  [
#    {
#      "kind": "youtube#video",
#      "snippet": {
#        "publishedAt": "2022-04-10T17:35:47Z",
#        "title": "Hosanna Sunday"
#      },
#      "liveStreamingDetails": {
#        "actualStartTime": "2022-04-10T15:28:00Z",
#        "actualEndTime": "2022-04-10T17:17:09Z",
#        "scheduledStartTime": "2022-04-10T15:30:00Z"
#      }
#    },
#    {
#      "kind": "youtube#video",
#      "snippet": {
#        "publishedAt": "2022-04-11T17:35:47Z",
#        "title": "Hosanna Sunday"
#      },
#      "liveStreamingDetails": {
#        "actualStartTime": "2022-04-11T15:28:00Z",
#        "actualEndTime": "2022-04-10T17:17:09Z",
#        "scheduledStartTime": "2022-04-10T15:30:00Z"
#      }
#    }
#  ]
#
# Output:
#    "[04/10/2022](#d2022-04-10-10-28-00)"
#    "[04/11/2022](#d2022-04-11-10-28-00)"
#
def seeAlsoChain:
    group_by ( keyYear )
  | if length == 1 or all( length == 1 ) then
      map ( .[] ) | seeAlsoChainGroup[]
    else
     (
       "",
       map ( seeAlsoChainGroup | .[0] |= " * \(.)" | .[] )[]
     )
    end
;

def seeAlso ($byAtomicTitle):
  atomicTitles as $aTitles
  | (
    . as $entry
    | $aTitles
    | map(
        . as $t
        | $byAtomicTitle[$t] | select ( length > 1 )
        | sort_by(
            keyDate
          )
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
        map ( "", "*\(.key)*:", ( .value | seeAlsoChain ) )
      end
    ) as $seeAlsoLines

  | select ( $seeAlsoLines | length > 0 )
  | (
      "See also:",
      $seeAlsoLines[]
    )
;

def playlistAnchor:
  .snippet.publishedAt | mdPlaylistAnchor
;

def seePlaylists:
  def playlistRef:
    "[\( .snippet.title )](#\( playlistAnchor ))"
  ;

    .playlists
  | select ( . )
  | if length == 1 then
      ( "", "Playlist:",  (  .[] | playlistRef ) )
    else
      ( "", "Playlists:", ( .[] | "* \( playlistRef )" ) )
    end
;

# Examples:
#
# Command:
#    [
#      { "id": "list1", "x": 5 },
#      { "id": "list2", "x": 6 }
#    ] as $playlists
#  | [
#      { "contentDetails": { "videoId": "123" }, "snippet": { "playlistId": "list1" } },
#      { "contentDetails": { "videoId": "123" }, "snippet": { "playlistId": "list2" } }
#    ] as $playlistItems
#  | [
#      {
#        "id": "123"
#      },
#      {
#        "id": "234"
#      }
#    ] as $videos
#  | $videos | mergePlaylists ( $playlists ; $playlistItems )
#
# Input:
#  ""
#
# Output:
#  [
#    {
#      "id": "123",
#      "playlists": [
#        { "id": "list1", "x": 5 },
#        { "id": "list2", "x": 6 }
#      ]
#    },
#    {
#      "id": "234"
#    }
#  ]
#
def mergePlaylists ($playlists ; $playlistItems):
    ( $playlists | groupToObj( .id ) ) as $playlistsById
  | ( reduce $playlistItems[] as $item ( {} ; .[ $item.contentDetails.videoId ] |= ( . // [] ) + [ $item ] ) ) as $playlistItemsById
  | map (
        $playlistItemsById[.id] as $items
      | if $items then
          .playlists = ( $items | map ( $playlistsById[ .snippet.playlistId ][] ) )
        else
          .
        end
    )
;

def linkHyperlinks:
  (
      sub (
        "
          (?<href>
            http[s]?://[^[:blank:]]+(/|[^[:punct:][:blank:]])
          )
        ";
	"[\( .href )](\( .href ))";
        "x"
      )
  ) // .
;

def linkTimestamps ($id):
  (
      capture (
        "^
          (?<ts>
            (
              (?<hh>\\d\\d):
            )?
            (
              (?<mm>\\d\\d):
            )
            (
              (?<ss>\\d\\d)
            )
          )
          (?<rest>.*)
        ";
        "x"
      )
    | [
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
      ) + .rest
  ) // .
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
                tonumber | select ( . > 0 ) | "\( . ) \($singular)\( if . > 1 then "s" else "" end ) \($thumb)"
              ;
              ( .likeCount    | thumb ( "like"    ; "&#128077;" ) ),
              ( .dislikeCount | thumb ( "dislike" ; "&#128078;" ) )
            ]
            | select ( length > 0 )
            | join (" and ")
            | "| Reactions: | \( . ) |"
          ) 
        )
    ),

    "",
    (
      ">" + ( .snippet.description | split("\n") | .[] | linkHyperlinks | linkTimestamps ( $entry.id ) ) + "  "
    ),
    "",

    ( seeAlso ( $byAtomicTitle ) ),

    ( seePlaylists ),

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

def playlistBody ($videos ; $playlistItems):
    ( $videos | groupToObj ( .id ) ) as $videosById
  | ( $playlistItems | groupToObj ( .snippet.playlistId ) ) as $itemsByPlaylist
  | .[]
  | (
      "#### \( .snippet.title )[](#\( playlistAnchor ))",
      "",
      (
          $itemsByPlaylist[ .id ][]
        | $videosById[ .contentDetails.videoId ][]
        | "* [\( .snippet.title )]( #\( seeAlsoAnchor ) )"
      ),    
      ""
    )
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
;

def toc ($byAtomicTitle; $byCategory; $playlists):
  "## Table of Contents",
  "### Chapters",
  (
     $byCategory | (
       ( select (.["Scheduled"])    | "* [Upcoming streams](#upcoming)" ),
       ( select (.["Livestreamed"]) | "* [Live streams](#live)"         ),
       ( select (.["Videos"])       | "* [Uploaded videos](#uploaded)"  )
    )
  ),

  ( select ( $playlists | length > 0 ) | "* [Playlists](#playlists)" ),

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

